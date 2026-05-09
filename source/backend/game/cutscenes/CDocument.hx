package backend.game.cutscenes;

/** Top-level document for the new keyframe format. */
class CDocument {
    public var name:String    = "untitled";
    public var fps:Int        = 60;
    public var objects:Array<CObject>         = [];
    public var frames:Map<Int, CFrame>         = [];
    public var totalFrames:Int                  = 120;

    public var snapshots:Array<Map<String, Map<String, Float>>> = [];
    public var snapshotsDirty:Bool = true;

    public function new() {}

    // ── serialisation ────────────────────────────────────────────────

    public function toXmlString():String {
        var sb = new StringBuf();
        sb.add('<CutScene name="${escXml(name)}" fps="$fps">\n');
        sb.add('    <objects>\n');
        for (o in objects) o.serialize(sb, 2);
        sb.add('    </objects>\n');
        sb.add('    <frames>\n');
        var keys = [for (k in frames.keys()) k];
        keys.sort((a, b) -> a - b);
        for (k in keys) frames.get(k).serialize(sb, 2);
        sb.add('    </frames>\n');
        sb.add('</CutScene>');
        return sb.toString();
    }

    public function toXml():Xml return Xml.parse(toXmlString());

    public static function fromXml(xml:Xml):CDocument {
        var doc = new CDocument();
        var root = xml.firstElement();
        if (root == null) throw "No root element";
        doc.name = root.get("name") ?? "untitled";
        doc.fps  = Std.parseInt(root.get("fps") ?? "60") ?? 60;

        for (el in root.elements()) {
            switch(el.nodeName) {
                case "objects":
                    for (obj in el.elements()) doc.objects.push(CObject.fromXml(obj));
                case "frames":
                    doc.totalFrames = Std.parseInt(el.get('total') ?? "120") ?? 120;
                    for (f in el.elements()) {
                        var kf = CFrame.fromXml(f);
                        doc.frames.set(kf.frameNum, kf);
                        if (kf.frameNum >= doc.totalFrames) doc.totalFrames = kf.frameNum + 1;
                    }
            }
        }
        doc.totalFrames == 0 ? doc.totalFrames = 120 : doc.totalFrames = doc.totalFrames;
        doc.snapshotsDirty = true;
        return doc;
    }

    public function clone():CDocument {
        return fromXml(toXml());
    }

    // ── snapshot baking ──────────────────────────────────────────────

    public function bakeSnapshots() {
        snapshots = [];
        snapshotsDirty = false;

        var current:Map<String, Map<String, Float>> = [];
        for (o in objects) _initObjectState(o, current);

        var activeTweens:Array<CTween.BakedTween> = [];

        for (f in 0...totalFrames) {
            var stillActive:Array<CTween.BakedTween> = [];
            for (t in activeTweens) {
                if (f > t.endFrame) continue;
                var pct = t.endFrame == t.startFrame ? 1.0 : (f - t.startFrame) / (t.endFrame - t.startFrame);
                var eased = t.easeFn(pct);
                var val = t.from + (t.to - t.from) * eased;
                _setStateVal(current, t.obj, t.prop, val);
                if (f < t.endFrame) stillActive.push(t);
            }
            activeTweens = stillActive;

            var kf = frames.get(f);
            if (kf != null) {
                for (d in kf.data) {
                    for (prop => val in d.props) _setStateVal(current, d.obj, prop, val);
                }
                for (tw in kf.tweens) {
                    var objState = current.get(tw.obj);
                    var fromVal  = tw.from != null ? tw.from : (objState != null ? (objState.get(tw.prop) ?? 0.0) : 0.0);
                    if (tw.from != null) _setStateVal(current, tw.obj, tw.prop, tw.from);
                    activeTweens.push({
                        obj: tw.obj, prop: tw.prop,
                        from: fromVal, to: tw.to,
                        startFrame: f, endFrame: f + tw.duration,
                        easeFn: CTween.resolveEase(tw.ease)
                    });
                }
            }

            var snap:Map<String, Map<String, Float>> = [];
            for (objName => props in current) {
                var pc:Map<String, Float> = [];
                for (p => v in props) pc.set(p, v);
                snap.set(objName, pc);
            }
            snapshots.push(snap);
        }
    }

    function _initObjectState(o:CObject, state:Map<String, Map<String, Float>>) {
        var props:Map<String, Float> = [];
        for (k => v in o.attrs) {
            var f = Std.parseFloat(v);
            if (!Math.isNaN(f)) props.set(k, f);
        }
        if (!props.exists("x"))       props.set("x", 0);
        if (!props.exists("y"))       props.set("y", 0);
        if (!props.exists("alpha"))   props.set("alpha", 1);
        if (!props.exists("angle"))   props.set("angle", 0);
        if (!props.exists("scale.x")) props.set("scale.x", 1);
        if (!props.exists("scale.y")) props.set("scale.y", 1);
        state.set(o.name, props);
        for (child in o.children) _initObjectState(child, state);
    }

    function _setStateVal(state:Map<String, Map<String, Float>>, obj:String, prop:String, val:Float) {
        if (!state.exists(obj)) state.set(obj, []);
        state.get(obj).set(prop, val);
    }

    static function escXml(s:String):String
        return s.split("&").join("&amp;").split('"').join("&quot;").split("<").join("&lt;").split(">").join("&gt;");

    // ── cascade rename ───────────────────────────────────────────────

    /** Rename an object everywhere: objects list, all frame data, all tweens. */
    public function renameObject(oldName:String, newName:String) {
        _renameInList(objects, oldName, newName);
        for (_ => kf in frames) {
            for (d in kf.data)   if (d.obj == oldName)  d.obj = newName;
            for (tw in kf.tweens) if (tw.obj == oldName) tw.obj = newName;
        }
        snapshotsDirty = true;
    }

    static function _renameInList(list:Array<CObject>, oldName:String, newName:String) {
        for (o in list) {
            if (o.name == oldName) {
                o.name = newName;
                o.attrs.set("name", newName);
            }
            _renameInList(o.children, oldName, newName);
        }
    }

    /** Reparent an object into a group (or to root if groupName == null). */
    public function embedIntoGroup(objName:String, groupName:Null<String>) {
        var obj = _extractFromList(objects, objName);
        if (obj == null) return;
        if (groupName == null) {
            objects.push(obj);
        } else {
            var parent = findObject(groupName, objects);
            if (parent != null) parent.children.push(obj);
        }
        snapshotsDirty = true;
    }

    public function _extractFromList(list:Array<CObject>, name:String):CObject {
        for (i in 0...list.length) {
            if (list[i].name == name) { var o = list[i]; list.splice(i, 1); return o; }
            var r = _extractFromList(list[i].children, name);
            if (r != null) return r;
        }
        return null;
    }

    public static function findObject(name:String, list:Array<CObject>):CObject {
        for (o in list) {
            if (o.name == name) return o;
            var r = findObject(name, o.children);
            if (r != null) return r;
        }
        return null;
    }
}