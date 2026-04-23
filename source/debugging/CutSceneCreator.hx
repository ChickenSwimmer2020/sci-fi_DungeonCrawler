//TODOS OF THE EDITOR
/**
 * Optimization
 * proper implementation of things like FileDialog
 * fix text input boxes
 * undo supports more than one action.
 * Optimization 2X
 * Right click popup menus when right-clicking on an object to change proper properties,
 *   like image, image path, name, and frame size.
 * create new popup actually clears all keyframes and groups and EVERYTHING from the
 *   old cutscene for proper memory saving, and also to prevent issues.
 */

/**
 * Keyframe-based Cutscene Editor + Runtime
 * AI-assisted (Claude). Original system by ChickenSwimmer2020.
 *
 * XML FORMAT:
 *   <CutScene name="intro" fps="24">
 *       <objects>
 *           <Sprite name="sky" x="0" y="-720" image_dir="..." image="..." animated="false" frameWidth="1280" frameHeight="1440"/>
 *           <Text   name="label" x="0" y="0" text="hello" size="16" width="0" alignment="left"/>
 *           <Sprite name="group" x="100" y="100">          <!-- group = FlxSpriteGroup -->
 *               <Sprite name="child" x="0" y="0" .../>     <!-- position relative to group -->
 *           </Sprite>
 *       </objects>
 *       <frames>
 *           <frame n="0">
 *               <data obj="sky" y="-720" alpha="1"/>
 *               <Tween obj="sky" prop="y" to="0" duration="218" ease="expoIn"/>
 *               <Tween obj="sky" prop="scale.x" from="1" to="1.5" duration="60" ease="linear"/>
 *               <timer frames="48">
 *                   <data obj="label" alpha="1"/>
 *               </timer>
 *           </frame>
 *       </frames>
 *   </CutScene>
 */

package debugging;

import haxe.io.Bytes;
import flixel.FlxG;
import flixel.FlxCamera;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.FlxSubState;
import flixel.group.FlxSpriteGroup;
import flixel.text.FlxText;
import flixel.ui.FlxButton;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.addons.ui.FlxInputText;

#if sys
import sys.io.File;
import sys.FileSystem;
#end

using flixel.util.FlxSpriteUtil;

// ═══════════════════════════════════════════════════════════════════════════════
//  NEW XML DATA MODEL
// ═══════════════════════════════════════════════════════════════════════════════

/** Top-level document for the new keyframe format. */
class KFDocument {
    public var name:String    = "untitled";
    public var fps:Int        = 60;
    public var objects:Array<KFObject>         = [];
    public var frames:Map<Int, KFFrame>         = [];
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

    public static function fromXml(xml:Xml):KFDocument {
        var doc = new KFDocument();
        var root = xml.firstElement();
        if (root == null) throw "No root element";
        doc.name = root.get("name") ?? "untitled";
        doc.fps  = Std.parseInt(root.get("fps") ?? "60") ?? 60;

        for (el in root.elements()) {
            switch(el.nodeName) {
                case "objects":
                    for (obj in el.elements()) doc.objects.push(KFObject.fromXml(obj));
                case "frames":
                    doc.totalFrames = Std.parseInt(el.get('total') ?? "120") ?? 120;
                    for (f in el.elements()) {
                        var kf = KFFrame.fromXml(f);
                        doc.frames.set(kf.frameNum, kf);
                        if (kf.frameNum >= doc.totalFrames) doc.totalFrames = kf.frameNum + 1;
                    }
            }
        }
        doc.totalFrames == 0 ? doc.totalFrames = 120 : doc.totalFrames = doc.totalFrames;
        doc.snapshotsDirty = true;
        return doc;
    }

    public function clone():KFDocument {
        return fromXml(toXml());
    }

    // ── snapshot baking ──────────────────────────────────────────────

    public function bakeSnapshots() {
        snapshots = [];
        snapshotsDirty = false;

        var current:Map<String, Map<String, Float>> = [];
        for (o in objects) _initObjectState(o, current);

        var activeTweens:Array<BakedTween> = [];

        for (f in 0...totalFrames) {
            var stillActive:Array<BakedTween> = [];
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
                        easeFn: KFTween.resolveEase(tw.ease)
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

    function _initObjectState(o:KFObject, state:Map<String, Map<String, Float>>) {
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

    static function _renameInList(list:Array<KFObject>, oldName:String, newName:String) {
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

    public function _extractFromList(list:Array<KFObject>, name:String):KFObject {
        for (i in 0...list.length) {
            if (list[i].name == name) { var o = list[i]; list.splice(i, 1); return o; }
            var r = _extractFromList(list[i].children, name);
            if (r != null) return r;
        }
        return null;
    }

    public static function findObject(name:String, list:Array<KFObject>):KFObject {
        for (o in list) {
            if (o.name == name) return o;
            var r = findObject(name, o.children);
            if (r != null) return r;
        }
        return null;
    }
}

typedef BakedTween = {
    obj:String, prop:String,
    from:Float, to:Float,
    startFrame:Int, endFrame:Int,
    easeFn:Float->Float
}

/** Object declaration in <objects> block. */
class KFObject {
    public var name:String;
    public var type:String;
    public var attrs:Map<String, String> = [];
    public var children:Array<KFObject> = [];

    public function new(type:String, name:String) { this.type = type; this.name = name; }

    public static function fromXml(el:Xml):KFObject {
        var o = new KFObject(el.nodeName, el.get("name") ?? "unnamed");
        for (a in el.attributes()) o.attrs.set(a, el.get(a));
        for (child in el.elements()) o.children.push(fromXml(child));
        return o;
    }

    public function serialize(sb:StringBuf, depth:Int) {
        var ind = _indent(depth);
        var attrStr = [for (k => v in attrs) '$k="${_esc(v)}"'].join(" ");
        if (children.length > 0) {
            sb.add('$ind<$type $attrStr>\n');
            for (c in children) c.serialize(sb, depth + 1);
            sb.add('$ind</$type>\n');
        } else {
            sb.add('$ind<$type $attrStr/>\n');
        }
    }

    static function _indent(d:Int) return StringTools.rpad("", " ", d * 4);
    static function _esc(s:String) return s.split("&").join("&amp;").split('"').join("&quot;");
}

/** One frame in the <frames> block. */
class KFFrame {
    public var frameNum:Int;
    public var data:Array<KFData>    = [];
    public var tweens:Array<KFTween> = [];
    public var timers:Array<KFTimer> = [];

    public function new(n:Int) { this.frameNum = n; }

    public static function fromXml(el:Xml):KFFrame {
        var kf = new KFFrame(Std.parseInt(el.get("n") ?? "0") ?? 0);
        for (child in el.elements()) {
            switch(child.nodeName) {
                case "data":  kf.data.push(KFData.fromXml(child));
                case "Tween": kf.tweens.push(KFTween.fromXml(child));
                case "timer": kf.timers.push(KFTimer.fromXml(child));
            }
        }
        return kf;
    }

    public function serialize(sb:StringBuf, depth:Int) {
        var ind = _indent(depth);
        sb.add('$ind<frame n="$frameNum">\n');
        for (d in data)   d.serialize(sb, depth + 1);
        for (t in tweens) t.serialize(sb, depth + 1);
        for (t in timers) t.serialize(sb, depth + 1);
        sb.add('$ind</frame>\n');
    }

    static function _indent(d:Int) return StringTools.rpad("", " ", d * 4);
}

/** <data obj="sky" y="-720" alpha="1" scale.x="2"/> */
class KFData {
    public var obj:String;
    public var props:Map<String, Float> = [];

    public function new(obj:String) { this.obj = obj; }

    public static function fromXml(el:Xml):KFData {
        var d = new KFData(el.get("obj") ?? "");
        for (a in el.attributes()) {
            if (a == "obj") continue;
            var f = Std.parseFloat(el.get(a));
            if (!Math.isNaN(f)) d.props.set(a, f);
        }
        return d;
    }

    public function serialize(sb:StringBuf, depth:Int) {
        var ind = _indent(depth);
        var attrs = ['obj="$obj"'];
        for (k => v in props) attrs.push('$k="$v"');
        sb.add('$ind<data ${attrs.join(" ")}/>\n');
    }

    static function _indent(d:Int) return StringTools.rpad("", " ", d * 4);
}

/** <Tween obj="sky" prop="y" from="-720" to="0" duration="218" ease="expoIn"/> */
class KFTween {
    public var obj:String;
    public var prop:String;
    public var from:Null<Float>;
    public var to:Float;
    public var duration:Int;
    public var ease:String = "linear";

    public function new() {}

    public static function fromXml(el:Xml):KFTween {
        var t = new KFTween();
        t.obj      = el.get("obj") ?? "";
        t.prop     = el.get("prop") ?? "x";
        t.to       = Std.parseFloat(el.get("to") ?? "0") ?? 0;
        t.duration = Std.parseInt(el.get("duration") ?? "24") ?? 24;
        t.ease     = el.get("ease") ?? "linear";
        var fromStr = el.get("from");
        t.from = fromStr != null ? Std.parseFloat(fromStr) : null;
        return t;
    }

    public function serialize(sb:StringBuf, depth:Int) {
        var ind = _indent(depth);
        var fromAttr = from != null ? ' from="$from"' : "";
        sb.add('$ind<Tween obj="$obj" prop="$prop"$fromAttr to="$to" duration="$duration" ease="$ease"/>\n');
    }

    public function clone():KFTween {
        var t = new KFTween();
        t.obj = obj; t.prop = prop; t.from = from; t.to = to;
        t.duration = duration; t.ease = ease;
        return t;
    }

    public static function resolveEase(name:String):Float->Float {
        return switch(name) {
            case "quadIn":      FlxEase.quadIn;
            case "quadOut":     FlxEase.quadOut;
            case "quadInOut":   FlxEase.quadInOut;
            case "cubeIn":      FlxEase.cubeIn;
            case "cubeOut":     FlxEase.cubeOut;
            case "cubeInOut":   FlxEase.cubeInOut;
            case "expoIn":      FlxEase.expoIn;
            case "expoOut":     FlxEase.expoOut;
            case "expoInOut":   FlxEase.expoInOut;
            case "sineIn":      FlxEase.sineIn;
            case "sineOut":     FlxEase.sineOut;
            case "sineInOut":   FlxEase.sineInOut;
            case "bounceIn":    FlxEase.bounceIn;
            case "bounceOut":   FlxEase.bounceOut;
            case "bounceInOut": FlxEase.bounceInOut;
            case "elasticIn":   FlxEase.elasticIn;
            case "elasticOut":  FlxEase.elasticOut;
            case "backIn":      FlxEase.backIn;
            case "backOut":     FlxEase.backOut;
            default:            (t:Float) -> t;
        };
    }

    public static final ALL_EASES:Array<String> = [
        "linear","quadIn","quadOut","quadInOut","cubeIn","cubeOut","cubeInOut",
        "expoIn","expoOut","expoInOut","sineIn","sineOut","sineInOut",
        "bounceIn","bounceOut","bounceInOut","elasticIn","elasticOut",
        "backIn","backOut"
    ];

    static function _indent(d:Int) return StringTools.rpad("", " ", d * 4);
}

/** <timer frames="48"> children... </timer> */
class KFTimer {
    public var frames:Int;
    public var children:Array<KFData> = [];

    public function new(f:Int) { this.frames = f; }

    public static function fromXml(el:Xml):KFTimer {
        var t = new KFTimer(Std.parseInt(el.get("frames") ?? "24") ?? 24);
        for (child in el.elements())
            if (child.nodeName == "data") t.children.push(KFData.fromXml(child));
        return t;
    }

    public function serialize(sb:StringBuf, depth:Int) {
        var ind = _indent(depth);
        sb.add('$ind<timer frames="$frames">\n');
        for (c in children) c.serialize(sb, depth + 1);
        sb.add('$ind</timer>\n');
    }

    static function _indent(d:Int) return StringTools.rpad("", " ", d * 4);
}

// ═══════════════════════════════════════════════════════════════════════════════
//  RUNTIME — KFCutscene
// ═══════════════════════════════════════════════════════════════════════════════

/**
 * Keyframe-based cutscene runtime.
 * Can run as a substate (full test) OR be embedded directly into the editor
 * state and rendered to a dedicated camera (live preview).
 */
class KFCutscene extends FlxSubState {
    public var doc:KFDocument;
    public var currentFrame:Int = 0;
    public var playing:Bool     = false;
    public var onComplete:Void->Void;

    public var objects:Map<String, Dynamic> = [];

    var _frameTimer:Float = 0;
    var _secPerFrame:Float;
    var _activeFlxTweens:Array<FlxTween> = [];

    public function new(doc:KFDocument) {
        super(0x00000000);
        this.doc = doc;
        _secPerFrame = 1.0 / doc.fps;
    }

    override public function create() {
        super.create();
        _buildObjects(doc.objects, null);
        if (doc.snapshotsDirty) doc.bakeSnapshots();
        _applySnapshot(0);
    }

    // ── object construction ──────────────────────────────────────────

    function _buildObjects(list:Array<KFObject>, ?parentGroup:FlxSpriteGroup) {
        for (o in list) {
            var built:Dynamic = null;
            switch(o.type) {
                case "Text":
                    var t = new FlxText(
                        Std.parseFloat(o.attrs.get("x") ?? "0") ?? 0,
                        Std.parseFloat(o.attrs.get("y") ?? "0") ?? 0,
                        Std.parseInt(o.attrs.get("width") ?? "0") ?? 0,
                        o.attrs.get("text") ?? "",
                        Std.parseInt(o.attrs.get("size") ?? "16") ?? 16
                    );
                    built = t;
                case "Sprite" if (o.children.length > 0):
                    var g = new FlxSpriteGroup(
                        Std.parseFloat(o.attrs.get("x") ?? "0") ?? 0,
                        Std.parseFloat(o.attrs.get("y") ?? "0") ?? 0
                    );
                    built = g;
                    _buildObjects(o.children, g);
                case "Sprite":
                    var s = new FlxSprite(
                        Std.parseFloat(o.attrs.get("x") ?? "0") ?? 0,
                        Std.parseFloat(o.attrs.get("y") ?? "0") ?? 0
                    );
                    var imgDir = o.attrs.get("image_dir") ?? "";
                    var img    = o.attrs.get("image") ?? "";
                    if (img != "") {
                        var animated = (o.attrs.get("animated") ?? "false") == "true";
                        var fw = Std.parseInt(o.attrs.get("frameWidth") ?? "64") ?? 64;
                        var fh = Std.parseInt(o.attrs.get("frameHeight") ?? "64") ?? 64;
                        if (animated) s.loadGraphic(Paths.image(imgDir, img), true, fw, fh);
                        else          s.loadGraphic(Paths.image(imgDir, img));
                    }
                    built = s;
                default:
                    built = new FlxSprite(0, 0).makeGraphic(4, 4, FlxColor.TRANSPARENT);
            }

            if (built != null) {
                objects.set(o.name, built);
                if (parentGroup != null) parentGroup.add(built);
                else add(built);
            }
        }
    }

    // ── snapshot application ─────────────────────────────────────────

    public function _applySnapshot(frame:Int) {
        if (frame < 0 || frame >= doc.snapshots.length) return;
        var snap = doc.snapshots[frame];
        for (objName => props in snap) {
            var obj = objects.get(objName);
            if (obj == null) continue;
            for (prop => val in props) _setReflect(obj, prop, val);
        }
    }

    function _setReflect(obj:Dynamic, prop:String, val:Dynamic) {
        if (prop.indexOf(".") >= 0) {
            var parts = prop.split(".");
            var target = obj;
            for (i in 0...parts.length - 1) {
                target = Reflect.getProperty(target, parts[i]);
                if (target == null) return;
            }
            Reflect.setProperty(target, parts[parts.length - 1], val);
        } else {
            Reflect.setProperty(obj, prop, val);
        }
    }

    // ── playback ─────────────────────────────────────────────────────

    public function play():KFCutscene  { playing = true; return this; }
    public function pause() { playing = false; }

    public function seekTo(frame:Int) {
        currentFrame = Std.int(Math.max(0, Math.min(frame, doc.totalFrames - 1)));
        for (t in _activeFlxTweens) t.cancel();
        _activeFlxTweens = [];
        _applySnapshot(currentFrame);
        _fireFrameActions(currentFrame, false);
    }

    override public function update(elapsed:Float) {
        super.update(elapsed);
        if (!playing) return;

        _frameTimer += elapsed;
        if (_frameTimer >= _secPerFrame) {
            _frameTimer -= _secPerFrame;
            _advanceFrame();
        }
    }

    function _advanceFrame() {
        if (currentFrame >= doc.totalFrames - 1) {
            playing = false;
            if (onComplete != null) onComplete();
            return;
        }
        currentFrame++;
        _applySnapshot(currentFrame);
        _fireFrameActions(currentFrame, true);
    }

    function _fireFrameActions(frame:Int, fireTimers:Bool) {
        var kf = doc.frames.get(frame);
        if (kf == null) return;

        for (tw in kf.tweens) {
            var obj = objects.get(tw.obj);
            if (obj == null) continue;
            var durationSec = tw.duration / doc.fps;
            var ease = KFTween.resolveEase(tw.ease);
            if (tw.from != null) _setReflect(obj, tw.prop, tw.from);
            var startVal:Float = _getReflect(obj, tw.prop);
            var endVal   = tw.to;
            var flxTw = FlxTween.num(startVal, endVal, durationSec, {ease: ease, onComplete: _ -> {}}, v -> _setReflect(obj, tw.prop, v));
            _activeFlxTweens.push(flxTw);
        }

        if (fireTimers) {
            for (timer in kf.timers) {
                var delayFrames = timer.frames;
                var children    = timer.children.copy();
                new FlxTimer().start(delayFrames / doc.fps, _ -> {
                    for (d in children) {
                        var obj = objects.get(d.obj);
                        if (obj == null) continue;
                        for (prop => val in d.props) _setReflect(obj, prop, val);
                    }
                }, 1);
            }
        }
    }

    function _getReflect(obj:Dynamic, prop:String):Float {
        if (prop.indexOf(".") >= 0) {
            var parts  = prop.split(".");
            var target = obj;
            for (i in 0...parts.length - 1) {
                target = Reflect.getProperty(target, parts[i]);
                if (target == null) return 0;
            }
            return Reflect.getProperty(target, parts[parts.length - 1]) ?? 0;
        }
        return Reflect.getProperty(obj, prop) ?? 0;
    }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  EDITOR
// ═══════════════════════════════════════════════════════════════════════════════

#if debug
class CutSceneCreator extends FlxState {

    // ── layout constants ─────────────────────────────────────────────
    public static inline final TOOLBAR_H:Int    = 24;
    public static inline final TIMELINE_H:Int   = 180;
    public static inline final OBJPANEL_W:Int   = 200;
    public static inline final PROPSPANEL_W:Int = 240;
    public static inline final STATUS_H:Int     = 16;

    public static var PREVIEW_X(get, never):Int; static function get_PREVIEW_X() return OBJPANEL_W;
    public static var PREVIEW_Y(get, never):Int; static function get_PREVIEW_Y() return TOOLBAR_H;
    public static var PREVIEW_W(get, never):Int; static function get_PREVIEW_W() return FlxG.width - OBJPANEL_W - PROPSPANEL_W;
    public static var PREVIEW_H(get, never):Int; static function get_PREVIEW_H() return FlxG.height - TOOLBAR_H - TIMELINE_H - STATUS_H;

    // ── state ────────────────────────────────────────────────────────
    public var doc:KFDocument;
    var _undoStack:KFDocument;
    var _filePath:String = "";

    public var selectedObjName:String        = "";
    public var selectedObjNames:Array<String> = [];
    public var currentFrame:Int              = 0;
    public var expandedObjects:Map<String, Bool> = [];

    public var onionEnabled:Bool = false;
    public var onionBefore:Int   = 2;
    public var onionAfter:Int    = 2;

    // ── ui panels ────────────────────────────────────────────────────
    var toolbar:KFToolbar;
    var objectPanel:KFObjectPanel;
    var propsPanel:KFPropsPanel;
    public var timeline:KFTimeline;
    public var previewPanel:KFPreviewPanel;
    var statusBar:FlxText;

    // ── overlays ─────────────────────────────────────────────────────
    public var stopOverlay:KFStopOverlay;
    public var addPropDialog:KFAddPropDialog;
    public var addObjectDialog:KFAddObjectDialog;
    public var tweenEditDialog:KFTweenEditDialog;

    // ── live preview (always-on, not a substate) ─────────────────────
    public var previewCamera:FlxCamera;
    public var liveCutscene:KFCutscene;
    var _fullTestRunning:Bool = false;

    // Preview drag
    var _dragObj:String   = "";
    var _dragOffX:Float   = 0;
    var _dragOffY:Float   = 0;
    var _dragStartX:Float = 0;
    var _dragStartY:Float = 0;

    override public function create() {
        super.create();
        bgColor = 0xFF232323;
        FlxG.state.persistentUpdate = true;

        doc = new KFDocument();

        // Build UI (order matters for layering)
        previewPanel = new KFPreviewPanel(this);
        add(previewPanel);

        toolbar = new KFToolbar(this);
        add(toolbar);

        objectPanel = new KFObjectPanel(this);
        add(objectPanel);

        propsPanel = new KFPropsPanel(this);
        add(propsPanel);

        timeline = new KFTimeline(this);
        add(timeline);

        statusBar = new FlxText(0, FlxG.height - STATUS_H, FlxG.width, "Ready.", 8);
        statusBar.color = 0xFF999999;
        add(statusBar);

        // Overlays (always on top)
        stopOverlay     = new KFStopOverlay(this);    stopOverlay.visible     = false; add(stopOverlay);
        addPropDialog   = new KFAddPropDialog(this);  addPropDialog.visible   = false; add(addPropDialog);
        addObjectDialog = new KFAddObjectDialog(this);addObjectDialog.visible = false; add(addObjectDialog);
        tweenEditDialog = new KFTweenEditDialog(this);tweenEditDialog.visible = false; add(tweenEditDialog);

        openSubState(new KFNewCutsceneDialog(this));
        setStatus("New cutscene — fill in details above.");
    }

    // ── public API ───────────────────────────────────────────────────

    public function setStatus(msg:String) statusBar.text = msg;
    public function showError(msg:String) openSubState(new KFErrorPopup(this, msg));

    public function snapshot() _undoStack = doc.clone();

    public function undo() {
        if (_undoStack == null) return;
        var tmp = doc; doc = _undoStack; _undoStack = tmp;
        doc.snapshotsDirty = true;
        rebakeAndRefresh();
        setStatus("Undo.");
    }

    public function rebakeAndRefresh() {
        if (doc.snapshotsDirty) doc.bakeSnapshots();
        objectPanel.rebuild();
        timeline.rebuild();
        propsPanel.loadFrame(currentFrame);
        _syncLivePreview();
        previewPanel.refresh();
    }

    public function selectObject(name:String, addToSel:Bool = false) {
        if (addToSel) {
            if (selectedObjNames.contains(name)) selectedObjNames.remove(name);
            else selectedObjNames.push(name);
        } else {
            selectedObjNames = [name];
        }
        selectedObjName = selectedObjNames.length > 0 ? selectedObjNames[selectedObjNames.length - 1] : "";
        propsPanel.loadFrame(currentFrame);
        objectPanel.refresh();
        timeline.refresh();
        // Also select in live preview visually (highlight handled by previewPanel overlay)
        previewPanel.refresh();
        setStatus('Selected: ${selectedObjNames.join(", ")}');
    }

    public function seekToFrame(f:Int) {
        currentFrame = Std.int(Math.max(0, Math.min(f, doc.totalFrames - 1)));
        propsPanel.loadFrame(currentFrame);
        timeline.refresh();
        if (liveCutscene != null) liveCutscene.seekTo(currentFrame);
        previewPanel.refresh();
    }

    public function addFrame(n:Int) {
        snapshot();
        if (!doc.frames.exists(n)) doc.frames.set(n, new KFFrame(n));
        if (n >= doc.totalFrames) doc.totalFrames = n + 1;
        doc.snapshotsDirty = true;
        rebakeAndRefresh();
        setStatus('Added frame $n.');
    }

    public function setTotalFrames(n:Int) {
        snapshot();
        doc.totalFrames = Std.int(Math.max(1, n));
        doc.snapshotsDirty = true;
        rebakeAndRefresh();
    }

    public function addDataToFrame(frame:Int, obj:String, prop:String, val:Float) {
        snapshot();
        var kf = doc.frames.get(frame);
        if (kf == null) { kf = new KFFrame(frame); doc.frames.set(frame, kf); }
        var d = _getOrCreateData(kf, obj);
        d.props.set(prop, val);
        if (frame >= doc.totalFrames) doc.totalFrames = frame + 1;
        doc.snapshotsDirty = true;
        rebakeAndRefresh();
    }

    function _getOrCreateData(kf:KFFrame, obj:String):KFData {
        for (d in kf.data) if (d.obj == obj) return d;
        var d = new KFData(obj);
        kf.data.push(d);
        return d;
    }

    public function addTweenToFrame(frame:Int, tw:KFTween) {
        snapshot();
        var kf = doc.frames.get(frame);
        if (kf == null) { kf = new KFFrame(frame); doc.frames.set(frame, kf); }
        kf.tweens.push(tw);
        var endFrame = frame + tw.duration;
        if (endFrame >= doc.totalFrames) doc.totalFrames = endFrame + 1;
        doc.snapshotsDirty = true;
        rebakeAndRefresh();
    }

    public function removeTweenFromFrame(frame:Int, tw:KFTween) {
        snapshot();
        var kf = doc.frames.get(frame);
        if (kf == null) return;
        kf.tweens.remove(tw);
        doc.snapshotsDirty = true;
        rebakeAndRefresh();
    }

    public function removeDataFromFrame(frame:Int, obj:String, prop:String) {
        snapshot();
        var kf = doc.frames.get(frame);
        if (kf == null) return;
        for (d in kf.data) {
            if (d.obj == obj) { d.props.remove(prop); break; }
        }
        doc.snapshotsDirty = true;
        rebakeAndRefresh();
    }

    public function addObject(type:String, name:String, ?attrs:Map<String, String>, ?parentName:String) {
        snapshot();
        var o = new KFObject(type, name);
        if (attrs != null) for (k => v in attrs) o.attrs.set(k, v);
        else {
            o.attrs.set("name", name);
            o.attrs.set("x", "0");
            o.attrs.set("y", "0");
            if (type == "Sprite") {
                o.attrs.set("image_dir", "");
                o.attrs.set("image", "");
                o.attrs.set("animated", "false");
                o.attrs.set("frameWidth", "64");
                o.attrs.set("frameHeight", "64");
            } else if (type == "Text") {
                o.attrs.set("text", "Hello");
                o.attrs.set("size", "16");
                o.attrs.set("width", "0");
                o.attrs.set("alignment", "left");
            }
        }

        // Auto-embed into selected group if parentName given, or if selected obj is a group
        var embedTarget = parentName;
        if (embedTarget == null && selectedObjName != "") {
            var selObj = KFDocument.findObject(selectedObjName, doc.objects);
            if (selObj != null && selObj.children.length > 0) embedTarget = selectedObjName;
        }

        if (embedTarget != null) {
            var parent = KFDocument.findObject(embedTarget, doc.objects);
            if (parent != null) { parent.children.push(o); }
            else doc.objects.push(o);
        } else {
            doc.objects.push(o);
        }

        doc.snapshotsDirty = true;
        rebakeAndRefresh();
        setStatus('Added $type "$name"${embedTarget != null ? ' into "$embedTarget"' : ""}.');
    }

    public function removeObject(name:String) {
        snapshot();
        doc.objects = doc.objects.filter(o -> o.name != name);
        doc.snapshotsDirty = true;
        if (selectedObjName == name) { selectedObjName = ""; selectedObjNames = []; }
        rebakeAndRefresh();
    }

    public function renameObject(oldName:String, newName:String) {
        if (newName == "" || newName == oldName) return;
        snapshot();
        doc.renameObject(oldName, newName);
        if (selectedObjName == oldName) {
            selectedObjName = newName;
            selectedObjNames = selectedObjNames.map(n -> n == oldName ? newName : n);
        }
        rebakeAndRefresh();
        setStatus('Renamed "$oldName" → "$newName".');
    }

    // ── live preview (persistent, not a substate) ────────────────────

    /**
     * Builds (or rebuilds) the persistent live preview cutscene.
     * Called after doc changes and on initial create.
     */
    public function buildLivePreview() {
        _destroyLivePreview();

        if (doc.snapshotsDirty) doc.bakeSnapshots();

        var zoom = Math.min(PREVIEW_W / 1280.0, PREVIEW_H / 720.0);
        previewCamera = new FlxCamera(PREVIEW_X, PREVIEW_Y, PREVIEW_W, PREVIEW_H);
        previewCamera.zoom = zoom;
        previewCamera.bgColor = 0xFF111111;
        FlxG.cameras.add(previewCamera, false);

        // Build cutscene with preview camera as default so members attach to it
        var savedDefaults = @:privateAccess FlxCamera._defaultCameras.copy();
        @:privateAccess FlxCamera._defaultCameras = [previewCamera];

        try {
            liveCutscene = new KFCutscene(doc);
            liveCutscene.create(); // manually create since we're not using openSubState
        } catch(e) {
            @:privateAccess FlxCamera._defaultCameras = savedDefaults;
            _destroyLivePreview();
            showError("Preview build failed: " + e.toString());
            return;
        }

        @:privateAccess FlxCamera._defaultCameras = savedDefaults;

        // Make all members of liveCutscene render to previewCamera only
        _assignCamera(liveCutscene, previewCamera);

        liveCutscene.seekTo(currentFrame);
    }

    function _assignCamera(cs:KFCutscene, cam:FlxCamera) {
        for (_ => obj in cs.objects) {
            try { Reflect.setProperty(obj, "cameras", [cam]); } catch(_) {}
        }
    }

    function _destroyLivePreview() {
        if (liveCutscene != null) {
            liveCutscene.destroy();
            liveCutscene = null;
        }
        if (previewCamera != null) {
            FlxG.cameras.remove(previewCamera, true);
            previewCamera = null;
        }
    }

    /** Sync live preview to current frame without rebuilding objects. */
    public function _syncLivePreview() {
        if (liveCutscene == null) {
            buildLivePreview();
            return;
        }
        // If doc objects changed, we need a full rebuild
        liveCutscene.doc = doc;
        liveCutscene.seekTo(currentFrame);
    }

    // ── full test playback (substate, same as before) ────────────────

    public function startFullTest() {
        if (_fullTestRunning) return;
        _fullTestRunning = true;
        stopOverlay.visible = true;

        if (doc.snapshotsDirty) doc.bakeSnapshots();

        var testCs = new KFCutscene(doc);
        testCs.onComplete = () -> { _fullTestRunning = false; stopOverlay.visible = false; closeSubState(); };
        openSubState(testCs);
        testCs.seekTo(0);
        testCs.play();
        setStatus("Full test — press STOP or ESC to end.");
    }

    public function stopFullTest() {
        if (!_fullTestRunning) return;
        _fullTestRunning = false;
        stopOverlay.visible = false;
        closeSubState();
        setStatus("Full test stopped.");
    }

    // ── preview play/pause (on live preview, not substate) ───────────

    public function playPreview() {
        if (liveCutscene == null) buildLivePreview();
        liveCutscene.play();
        setStatus("Playing…");
    }

    public function pausePreview() {
        if (liveCutscene != null) liveCutscene.pause();
        setStatus("Paused.");
    }

    public function stopPreview() {
        if (_fullTestRunning) { stopFullTest(); return; }
        if (liveCutscene != null) {
            liveCutscene.pause();
            liveCutscene.seekTo(0);
        }
        stopOverlay.visible = false;
        setStatus("Preview stopped.");
    }

    // ── drag in preview ──────────────────────────────────────────────

    public function beginDrag(objName:String, worldX:Float, worldY:Float) {
        _dragObj    = objName;
        var snap = doc.snapshots.length > currentFrame ? doc.snapshots[currentFrame] : null;
        _dragStartX = snap != null && snap.exists(objName) ? (snap.get(objName).get("x") ?? 0) : 0;
        _dragStartY = snap != null && snap.exists(objName) ? (snap.get(objName).get("y") ?? 0) : 0;
        _dragOffX   = worldX - _dragStartX;
        _dragOffY   = worldY - _dragStartY;
    }

    public function updateDrag(worldX:Float, worldY:Float) {
        if (_dragObj == "") return;
        var nx = worldX - _dragOffX;
        var ny = worldY - _dragOffY;
        var dx = nx - _dragStartX;
        var dy = ny - _dragStartY;

        var targets = selectedObjNames.length > 1 ? selectedObjNames : [_dragObj];
        for (name in targets) {
            var snap = doc.snapshots.length > currentFrame ? doc.snapshots[currentFrame] : null;
            var ox = snap != null && snap.exists(name) ? (snap.get(name).get("x") ?? 0) : 0;
            var oy = snap != null && snap.exists(name) ? (snap.get(name).get("y") ?? 0) : 0;
            if (liveCutscene != null) {
                var obj = liveCutscene.objects.get(name);
                if (obj != null) {
                    Reflect.setProperty(obj, "x", ox + dx);
                    Reflect.setProperty(obj, "y", oy + dy);
                }
            }
        }
    }

    public function endDrag(worldX:Float, worldY:Float) {
        if (_dragObj == "") return;
        var nx = worldX - _dragOffX;
        var ny = worldY - _dragOffY;
        var dx = nx - _dragStartX;
        var dy = ny - _dragStartY;

        var targets = selectedObjNames.length > 1 ? selectedObjNames : [_dragObj];
        snapshot();
        for (name in targets) {
            var snap = doc.snapshots.length > currentFrame ? doc.snapshots[currentFrame] : null;
            var ox = snap != null && snap.exists(name) ? (snap.get(name).get("x") ?? 0) : 0;
            var oy = snap != null && snap.exists(name) ? (snap.get(name).get("y") ?? 0) : 0;
            addDataToFrame(currentFrame, name, "x", ox + dx);
            addDataToFrame(currentFrame, name, "y", oy + dy);
        }
        _dragObj = "";
        doc.snapshotsDirty = true;
        rebakeAndRefresh();
    }

    // ── file I/O ─────────────────────────────────────────────────────

    public function saveToFile(?path:String, saveAs:Bool) {
        #if sys
        var p = path ?? _filePath;
        if (saveAs || (p == "" || p == null)) {
            var filediag:FileDialog = new FileDialog();
            filediag.save(Bytes.ofString(doc.toXmlString()), "cutscene", '$p${doc.name}.cutscene', "Save Cutscene");
            filediag.onSave.add((_) -> { trace('file saved successfully!'); });
            return;
        } else {
            try {
                var normalizedPathForRender:String = p;
                normalizedPathForRender.replace('\\', '/').replace('//', '/');
                if (!FileSystem.exists('$p/${doc.name}.cutscene')) File.write('$p/${doc.name}.cutscene', false);
                File.saveContent('$p/${doc.name}.cutscene', doc.toXmlString());
                _filePath = '$p/${doc.name}.cutscene';
                setStatus('Saved to $normalizedPathForRender/${(doc.name).replace('//', '/')}.cutscene');
            } catch(e) { showError("Save failed: " + e.toString()); }
        }
        #else
            //TODO: HTML5
        #end
    }

    public function loadFromFile(path:String) {
        #if sys
        try {
            var xml:Xml;
            var filediag:FileDialog = new FileDialog();
            filediag.open("cutscene", path, "Load Cutscene");
            filediag.onOpen.add((_) -> {
                @:privateAccess xml = Xml.parse(_);
                doc = KFDocument.fromXml(xml);
                _filePath = path;
                currentFrame = 0;
                selectedObjName = ""; selectedObjNames = [];
                doc.bakeSnapshots();
                buildLivePreview(); // rebuild preview for new doc
                rebakeAndRefresh();
                setStatus('Loaded $path');
            });
        } catch(e) {
            showError("Load failed: " + e.toString());
            trace('something went wrong: $e with stack: ${e.stack}');
        }
        #else
            //TODO: HTML5
        #end
    }

    // ── update ───────────────────────────────────────────────────────

    override public function update(elapsed:Float) {
        super.update(elapsed);

        // Tick live preview manually (it's not a substate so FlxGame won't tick it)
        if (liveCutscene != null && !_fullTestRunning) {
            liveCutscene.update(elapsed);
            // Sync currentFrame from live preview when playing
            if (liveCutscene.playing) {
                if (liveCutscene.currentFrame != currentFrame) {
                    currentFrame = liveCutscene.currentFrame;
                    timeline.refresh();
                }
            }
        }

        FlxG.watch.addQuick("popup is open: ", Flags.CC_THEREISAPOPUPOPENDONOTUSECUTSCENECONTROLS);

        if (!Flags.CC_THEREISAPOPUPOPENDONOTUSECUTSCENECONTROLS && FlxG.keys.justPressed.ESCAPE) {
            if (_fullTestRunning)            { stopFullTest(); return; }
            if (addPropDialog.visible)       { addPropDialog.visible = false; return; }
            if (addObjectDialog.visible)     { addObjectDialog.visible = false; return; }
            if (tweenEditDialog.visible)     { tweenEditDialog.visible = false; return; }
        }

        var anyOverlay = addPropDialog.visible || addObjectDialog.visible || tweenEditDialog.visible;

        if (!anyOverlay && !_fullTestRunning) {
            if (FlxG.keys.pressed.CONTROL) {
                if (!Flags.CC_THEREISAPOPUPOPENDONOTUSECUTSCENECONTROLS && FlxG.keys.justPressed.S)
                    saveToFile(_filePath, FlxG.keys.pressed.SHIFT);
                if (!Flags.CC_THEREISAPOPUPOPENDONOTUSECUTSCENECONTROLS && FlxG.keys.justPressed.Z)
                    undo();
            }
            if (!Flags.CC_THEREISAPOPUPOPENDONOTUSECUTSCENECONTROLS && FlxG.keys.justPressed.SPACE) {
                if (liveCutscene != null && liveCutscene.playing) pausePreview();
                else playPreview();
            }
            if (!Flags.CC_THEREISAPOPUPOPENDONOTUSECUTSCENECONTROLS && FlxG.keys.justPressed.LEFT)  seekToFrame(currentFrame - 1);
            if (!Flags.CC_THEREISAPOPUPOPENDONOTUSECUTSCENECONTROLS && FlxG.keys.justPressed.RIGHT) seekToFrame(currentFrame + 1);
        }
    }

    override public function destroy() {
        _destroyLivePreview();
        super.destroy();
    }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  PREVIEW PANEL — 16:9 viewport with onion skin + tween viz + drag
// ═══════════════════════════════════════════════════════════════════════════════

class KFPreviewPanel extends FlxSpriteGroup {
    var editor:CutSceneCreator;
    var bg:FlxSprite;
    var borderLeft:FlxSprite;
    var borderRight:FlxSprite;
    var borderTop:FlxSprite;
    var borderBottom:FlxSprite;
    var onionSprites:Array<FlxSprite>  = [];
    var tweenLines:Array<FlxSprite>    = [];
    var tweenEndBoxes:Array<FlxSprite> = [];
    var tweenHitboxes:Array<FlxSprite> = [];
    var playBtn:FlxUIButton;
    var pauseBtn:FlxUIButton;
    var stopBtn:FlxUIButton;
    var _dragging:Bool = false;

    public function new(editor:CutSceneCreator) {
        super(CutSceneCreator.PREVIEW_X, CutSceneCreator.PREVIEW_Y);
        this.editor = editor;

        bg = new FlxSprite().makeGraphic(CutSceneCreator.PREVIEW_W, CutSceneCreator.PREVIEW_H, 0xFF1A1A1A);
        add(bg);

        var pw = CutSceneCreator.PREVIEW_W - 4;
        var ph = Std.int(pw * 9.0 / 16.0);
        var px = 2;
        var py = Std.int((CutSceneCreator.PREVIEW_H - ph) / 2);

        borderLeft   = new FlxSprite(px - 1, py).makeGraphic(1, ph, 0xFF444444);
        borderRight  = new FlxSprite(px + pw, py).makeGraphic(1, ph, 0xFF444444);
        borderTop    = new FlxSprite(px - 1, py - 1).makeGraphic(pw + 2, 1, 0xFF444444);
        borderBottom = new FlxSprite(px - 1, py + ph).makeGraphic(pw + 2, 1, 0xFF444444);
        add(borderLeft); add(borderRight); add(borderTop); add(borderBottom);

        var btnY = CutSceneCreator.PREVIEW_H - 20;
        playBtn  = new FlxUIButton(4,  btnY, "", () -> editor.playPreview());
        pauseBtn = new FlxUIButton(24, btnY, "", () -> editor.pausePreview());
        stopBtn  = new FlxUIButton(44, btnY, "", () -> editor.stopPreview());
        var i:Int = 0;
        for (b in [playBtn, pauseBtn, stopBtn]) {
            b.loadGraphic(Paths.image('ui/menu', "button_square"), true, 20, 20);
            b.updateHitbox();
            b.autoCenterLabel();
            b.addIcon(new FlxSprite().loadGraphic([Paths.DEBUG("cc_play", "png"), Paths.DEBUG("cc_pause", "png"), Paths.DEBUG("cc_stop", "png")][i], 0, 0, true));
            add(b);
            i++;
        }
    }

    public function refresh() {
        _clearOverlays();
        if (editor.doc.snapshots.length == 0) return;

        var frame = editor.currentFrame;
        var snap  = frame < editor.doc.snapshots.length ? editor.doc.snapshots[frame] : null;

        // ── onion skinning ───────────────────────────────────────────
        if (editor.onionEnabled && snap != null) {
            for (delta in [-editor.onionBefore, -1, 1, editor.onionAfter]) {
                if (delta == 0) continue;
                var of = frame + delta;
                if (of < 0 || of >= editor.doc.snapshots.length) continue;
                var os = editor.doc.snapshots[of];
                var alpha = delta < 0 ? 0.25 : 0.15;
                var color = delta < 0 ? 0xFFFF4444 : 0xFF4488FF;
                for (objName in editor.selectedObjNames) {
                    if (!os.exists(objName)) continue;
                    var props = os.get(objName);
                    var wx = props.get("x") ?? 0;
                    var wy = props.get("y") ?? 0;
                    var sx = props.get("scale.x") ?? 1;
                    var sy = props.get("scale.y") ?? 1;
                    var sp = new FlxSprite(_worldToPreviewX(wx), _worldToPreviewY(wy));
                    sp.makeGraphic(Std.int(16 * sx), Std.int(16 * sy), color);
                    sp.alpha = alpha;
                    onionSprites.push(sp);
                    add(sp);
                }
            }
        }

        // ── tween visualisation ──────────────────────────────────────
        var kf = editor.doc.frames.get(frame);
        if (kf != null && snap != null) {
            for (tw in kf.tweens) {
                var props = snap.get(tw.obj);
                if (props == null) continue;

                var isPositional = tw.prop == "x" || tw.prop == "y";
                var isScale      = tw.prop == "scale.x" || tw.prop == "scale.y" || tw.prop == "scaleX" || tw.prop == "scaleY";

                if (isPositional) {
                    var startX = props.get("x") ?? 0;
                    var startY = props.get("y") ?? 0;
                    var endX   = tw.prop == "x" ? tw.to : startX;
                    var endY   = tw.prop == "y" ? tw.to : startY;

                    var sx = _worldToPreviewX(startX);
                    var sy = _worldToPreviewY(startY);
                    var ex = _worldToPreviewX(endX);
                    var ey = _worldToPreviewY(endY);

                    _drawLine(sx, sy, ex, ey, 0xFFFFAA00, 1);

                    var box = new FlxSprite(ex - 4, ey - 4).makeGraphic(8, 8, 0xFFFFAA00);
                    tweenEndBoxes.push(box);
                    add(box);
                } else if (isScale) {
                    var wx = props.get("x") ?? 0;
                    var wy = props.get("y") ?? 0;
                    var endScale = tw.to;
                    var px2 = _worldToPreviewX(wx);
                    var py2 = _worldToPreviewY(wy);
                    var scaledW = Std.int(32 * endScale * _previewScale());
                    var scaledH = Std.int(32 * endScale * _previewScale());
                    _drawDashedRect(px2 - scaledW / 2, py2 - scaledH / 2, scaledW, scaledH, 0xFF44FFAA);
                }
            }
        }
    }

    override public function update(elapsed:Float) {
        super.update(elapsed);

        var mx = FlxG.mouse.x - CutSceneCreator.PREVIEW_X;
        var my = FlxG.mouse.y - CutSceneCreator.PREVIEW_Y;
        var inPanel = mx >= 0 && my >= 0 && mx < CutSceneCreator.PREVIEW_W && my < CutSceneCreator.PREVIEW_H;

        if (!inPanel) return;

        var worldX = _previewToWorldX(mx);
        var worldY = _previewToWorldY(my);

        if (FlxG.mouse.justPressed) {
            var hit = _hitTestObject(worldX, worldY);
            if (hit != "") {
                _dragging = true;
                editor.selectObject(hit, FlxG.keys.pressed.SHIFT);
                editor.beginDrag(hit, worldX, worldY);
            }
        } else if (FlxG.mouse.pressed && _dragging) {
            editor.updateDrag(worldX, worldY);
        } else if (FlxG.mouse.justReleased && _dragging) {
            _dragging = false;
            editor.endDrag(worldX, worldY);
        }
    }

    function _hitTestObject(worldX:Float, worldY:Float):String {
        var snap = editor.currentFrame < editor.doc.snapshots.length ? editor.doc.snapshots[editor.currentFrame] : null;
        if (snap == null) return "";
        for (objName => props in snap) {
            var ox = props.get("x") ?? 0;
            var oy = props.get("y") ?? 0;
            var sw = (props.get("scale.x") ?? 1) * 64;
            var sh = (props.get("scale.y") ?? 1) * 64;
            if (worldX >= ox - sw / 2 && worldX <= ox + sw / 2 &&
                worldY >= oy - sh / 2 && worldY <= oy + sh / 2) return objName;
        }
        return "";
    }

    function _clearOverlays() {
        for (s in onionSprites)  { remove(s, true); s.destroy(); }
        for (s in tweenLines)    { remove(s, true); s.destroy(); }
        for (s in tweenEndBoxes) { remove(s, true); s.destroy(); }
        for (s in tweenHitboxes) { remove(s, true); s.destroy(); }
        onionSprites = []; tweenLines = []; tweenEndBoxes = []; tweenHitboxes = [];
    }

    function _previewScale():Float {
        var pw = CutSceneCreator.PREVIEW_W - 4;
        return pw / 1280.0;
    }

    function _worldToPreviewX(wx:Float):Float {
        return 2 + wx * _previewScale();
    }

    function _worldToPreviewY(wy:Float):Float {
        var pw = CutSceneCreator.PREVIEW_W - 4;
        var ph = Std.int(pw * 9.0 / 16.0);
        var pyo = Std.int((CutSceneCreator.PREVIEW_H - ph) / 2);
        return pyo + wy * _previewScale();
    }

    function _previewToWorldX(px:Float):Float return (px - 2) / _previewScale();
    function _previewToWorldY(py:Float):Float {
        var pw = CutSceneCreator.PREVIEW_W - 4;
        var ph = Std.int(pw * 9.0 / 16.0);
        var pyo = Std.int((CutSceneCreator.PREVIEW_H - ph) / 2);
        return (py - pyo) / _previewScale();
    }

    function _drawLine(x1:Float, y1:Float, x2:Float, y2:Float, color:Int, thickness:Int) {
        var dx = x2 - x1; var dy = y2 - y1;
        var len = Math.sqrt(dx * dx + dy * dy);
        if (len < 1) return;
        var steps = Std.int(len);
        for (i in 0...steps) {
            var t = i / steps;
            var px2 = x1 + dx * t;
            var py2 = y1 + dy * t;
            var dot = new FlxSprite(px2, py2).makeGraphic(thickness, thickness, color);
            tweenLines.push(dot);
            add(dot);
        }
    }

    function _drawDashedRect(rx:Float, ry:Float, rw:Int, rh:Int, color:Int) {
        var dashLen = 4; var gap = 3;
        var x = rx;
        while (x < rx + rw) {
            var len = Std.int(Math.min(dashLen, (rx + rw) - x));
            var t = new FlxSprite(x, ry).makeGraphic(len, 1, color);
            var b2 = new FlxSprite(x, ry + rh).makeGraphic(len, 1, color);
            tweenHitboxes.push(t); tweenHitboxes.push(b2);
            add(t); add(b2);
            x += dashLen + gap;
        }
        var y = ry;
        while (y < ry + rh) {
            var len = Std.int(Math.min(dashLen, (ry + rh) - y));
            var l = new FlxSprite(rx, y).makeGraphic(1, len, color);
            var r2 = new FlxSprite(rx + rw, y).makeGraphic(1, len, color);
            tweenHitboxes.push(l); tweenHitboxes.push(r2);
            add(l); add(r2);
            y += dashLen + gap;
        }
    }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  TOOLBAR
// ═══════════════════════════════════════════════════════════════════════════════

class KFToolbar extends FlxSpriteGroup {
    var editor:CutSceneCreator;
    var fpsInput:FlxInputText;
    var frameCountInput:FlxInputText;
    var onionCheckBox:FlxUICheckBox;

    public function new(editor:CutSceneCreator) {
        super(0, 0);
        this.editor = editor;
        add(new FlxSprite().makeGraphic(FlxG.width, CutSceneCreator.TOOLBAR_H, 0xFF383838));

        var x = 4;
        x = _btn(x, "New",     () -> editor.openSubState(new KFNewCutsceneDialog(editor)));
        x = _btn(x, "Load",    () -> editor.loadFromFile(Flags.CC_DEFAULTLOADPATH));
        @:privateAccess x = _btn(x, "Save",    () -> editor.saveToFile(editor._filePath, FlxG.keys.pressed.SHIFT));
        x = _sep(x);
        x = _btn(x, "Undo",    () -> editor.undo());
        x = _sep(x);
        x = _btn(x, "> Play",  () -> editor.playPreview());
        x = _btn(x, ">> Full", () -> editor.startFullTest());
        x = _sep(x);

        x = _chkbx(x, "Onion", editor.previewPanel.refresh);

        var lbl1 = new FlxText(x, 4, 30, "-B:", 8); lbl1.color = 0xFF999999; add(lbl1); x += 22;
        var beforeIn = new FlxInputText(x, 3, 24, "2", 8);
        beforeIn.backgroundColor = 0xFF2A2A2A; beforeIn.fieldBorderColor = 0xFF555555;
        beforeIn.fieldBorderThickness = 1;
        beforeIn.callback = (t, _) -> { var v = Std.parseInt(t); if (v != null) editor.onionBefore = v; };
        add(beforeIn); x += 28;
        var lbl2 = new FlxText(x, 4, 30, "+A:", 8); lbl2.color = 0xFF999999; add(lbl2); x += 22;
        var afterIn = new FlxInputText(x, 3, 24, "2", 8);
        afterIn.backgroundColor = 0xFF2A2A2A; afterIn.fieldBorderColor = 0xFF555555;
        afterIn.fieldBorderThickness = 1;
        afterIn.callback = (t, _) -> { var v = Std.parseInt(t); if (v != null) editor.onionAfter = v; };
        add(afterIn); x += 28;
        x = _sep(x);

        var fpsLbl = new FlxText(x, 4, 30, "FPS:", 8); fpsLbl.color = 0xFF999999; add(fpsLbl); x += 28;
        fpsInput = new FlxInputText(x, 3, 30, "60", 8);
        fpsInput.backgroundColor = 0xFF2A2A2A; fpsInput.fieldBorderColor = 0xFF555555;
        fpsInput.fieldBorderThickness = 1;
        fpsInput.callback = (t, _) -> { var v = Std.parseInt(t); if (v != null && v > 0) { editor.doc.fps = v; editor.doc.snapshotsDirty = true; editor.rebakeAndRefresh(); }};
        add(fpsInput); x += 34;

        var frLbl = new FlxText(x, 4, 50, "Frames:", 8); frLbl.color = 0xFF999999; add(frLbl); x += 46;
        frameCountInput = new FlxInputText(x, 3, 40, "120", 8);
        frameCountInput.backgroundColor = 0xFF2A2A2A; frameCountInput.fieldBorderColor = 0xFF555555;
        frameCountInput.fieldBorderThickness = 1;
        frameCountInput.callback = (t, _) -> { var v = Std.parseInt(t); if (v != null && v > 0) editor.setTotalFrames(v); };
        add(frameCountInput); x += 44;

        x = _sep(x);
        _btn(x, "Back", () -> FlxG.switchState(() -> new MainMenuState(true)));
    }

    function _chkbx(x:Int, label:String, cb:Void->Void):Int {
        onionCheckBox = new FlxUICheckBox(x, 2, null, null, label, 0, [], cb);
        add(onionCheckBox);
        return Std.int(x + (onionCheckBox.width + onionCheckBox.getLabel().frameWidth) + 3);
    }

    function _btn(x:Int, label:String, cb:Void->Void):Int {
        var b = new FlxButton(x, 2, label, cb);
        b.label.setFormat(null, 8, FlxColor.BLACK);
        add(b);
        return Std.int(x + b.width + 3);
    }

    function _sep(x:Int):Int {
        add(new FlxSprite(x, 4).makeGraphic(1, CutSceneCreator.TOOLBAR_H - 8, 0xFF555555));
        return x + 5;
    }

    override public function update(elapsed:Float) {
        super.update(elapsed);
        if (editor.onionEnabled != onionCheckBox.checked) editor.onionEnabled = onionCheckBox.checked;
    }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  OBJECT PANEL (left column)
// ═══════════════════════════════════════════════════════════════════════════════

class KFObjectPanel extends FlxSpriteGroup {
    var editor:CutSceneCreator;
    var rows:Array<FlxSpriteGroup> = [];
    var scrollOffset:Int = 0;
    static inline var ROW_H = 18;

    public function new(editor:CutSceneCreator) {
        super(0, CutSceneCreator.TOOLBAR_H);
        this.editor = editor;
        add(new FlxSprite().makeGraphic(CutSceneCreator.OBJPANEL_W,
            FlxG.height - CutSceneCreator.TOOLBAR_H - CutSceneCreator.TIMELINE_H - CutSceneCreator.STATUS_H, 0xFF2C2C2C));

        var header = new FlxText(4, 2, CutSceneCreator.OBJPANEL_W - 50, "Objects", 8);
        header.color = 0xFF888888;
        add(header);

        var addBtn = new FlxUIButton(CutSceneCreator.OBJPANEL_W - 44, 2, "+", () -> editor.addObjectDialog.visible = true);
        addBtn.loadGraphic(Paths.image('ui/menu', "button_square"), true, 20, 20);
        addBtn.updateHitbox();
        addBtn.autoCenterLabel();
        addBtn.label.setFormat(null, 7, FlxColor.BLACK);
        add(addBtn);

        rebuild();
    }

    public function rebuild() {
        for (r in rows) { remove(r, true); r.destroy(); }
        rows = [];
        var yy = 18;
        var panelH = FlxG.height - CutSceneCreator.TOOLBAR_H - CutSceneCreator.TIMELINE_H - CutSceneCreator.STATUS_H;
        _buildRows(editor.doc.objects, panelH, yy, 0);
    }

    function _buildRows(list:Array<KFObject>, panelH:Int, startY:Int, depth:Int):Int {
        var yy = startY;
        var idx = 0;
        for (o in list) {
            // Skip scrolled items at root only
            if (depth == 0 && idx < scrollOffset) { idx++; continue; }
            if (yy + ROW_H > panelH) break;
            var row = _buildRow(o, yy, depth);
            add(row);
            rows.push(row);
            yy += ROW_H;
            idx++;

            // Recursively draw children if expanded
            var expanded = editor.expandedObjects.get(o.name) ?? false;
            if (expanded && o.children.length > 0) {
                yy = _buildRows(o.children, panelH, yy, depth + 1);
            }
        }
        return yy;
    }

    function _buildRow(o:KFObject, yy:Int, depth:Int):FlxSpriteGroup {
        var g = new FlxSpriteGroup(0, yy);

        var isSelected = editor.selectedObjNames.contains(o.name);
        var bgColor = isSelected ? 0xFF3A3A5A : 0xFF2C2C2C;
        g.add(new FlxSprite(0, 0).makeGraphic(CutSceneCreator.OBJPANEL_W, ROW_H, bgColor));

        var typeColor = o.type == "Sprite" ? 0xFF1D9E75 : o.type == "Text" ? 0xFF378ADD : 0xFF7F77DD;
        g.add(new FlxSprite(4 + depth * 12, Std.int(ROW_H / 2) - 3).makeGraphic(6, 6, typeColor));

        var lbl = new FlxText(14 + depth * 12, 2, CutSceneCreator.OBJPANEL_W - 60 - depth * 12, o.name, 8);
        lbl.color = isSelected ? FlxColor.WHITE : 0xFFCCCCCC;
        g.add(lbl);

        if (o.children.length > 0) {
            var exp = editor.expandedObjects.get(o.name) ?? false;
            var expBtn = new FlxUIButton(CutSceneCreator.OBJPANEL_W - 60, 1, "", () -> {
                editor.expandedObjects.set(o.name, !(editor.expandedObjects.get(o.name) ?? false));
                rebuild();
            });
            expBtn.loadGraphic(Paths.image('ui/menu', "button_square"), true, 20, 20);
            expBtn.updateHitbox();
            expBtn.autoCenterLabel();
            expBtn.addIcon(new FlxSprite().loadGraphic(Paths.DEBUG('cc_${exp ? "down" : "right"}', "png")), 0, 0, true);
            expBtn.label.setFormat(null, 7, FlxColor.WHITE);
            g.add(expBtn);
        }

        var delBtn = new FlxUIButton(CutSceneCreator.OBJPANEL_W - 20, 1, "", () -> editor.removeObject(o.name));
        delBtn.loadGraphic(Paths.image('ui/menu', "button_square"), true, 20, 20);
        delBtn.updateHitbox();
        delBtn.autoCenterLabel();
        delBtn.addIcon(new FlxSprite().loadGraphic(Paths.image('ui/menu', "icon_delete")), 0, 0, true);
        g.add(delBtn);

        var objName = o.name;
        var hit = new FlxButton(0, 0, "", () -> editor.selectObject(objName, FlxG.keys.pressed.SHIFT));
        hit.makeGraphic(CutSceneCreator.OBJPANEL_W - 20, ROW_H, FlxColor.TRANSPARENT);
        g.add(hit);

        return g;
    }

    public function refresh() rebuild();

    override public function update(elapsed:Float) {
        super.update(elapsed);
        if (FlxG.mouse.wheel != 0 && FlxG.mouse.x < CutSceneCreator.OBJPANEL_W) {
            scrollOffset = Std.int(Math.max(0, scrollOffset - FlxG.mouse.wheel));
            rebuild();
        }
    }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  PROPERTIES PANEL (right column)
// ═══════════════════════════════════════════════════════════════════════════════

class KFPropsPanel extends FlxSpriteGroup {
    var editor:CutSceneCreator;
    var rows:Array<FlxSpriteGroup> = [];
    var headerLbl:FlxText;
    static inline var ROW_H = 22;
    static inline var W = CutSceneCreator.PROPSPANEL_W;

    public function new(editor:CutSceneCreator) {
        super(FlxG.width - W, CutSceneCreator.TOOLBAR_H);
        this.editor = editor;
        add(new FlxSprite().makeGraphic(W,
            FlxG.height - CutSceneCreator.TOOLBAR_H - CutSceneCreator.TIMELINE_H - CutSceneCreator.STATUS_H, 0xFF2A2A2A));
        headerLbl = new FlxText(4, 3, W - 8, "Properties", 8);
        headerLbl.color = 0xFF888888;
        add(headerLbl);
    }

    public function loadFrame(frame:Int) {
        for (r in rows) { remove(r, true); r.destroy(); }
        rows = [];

        if (editor.selectedObjName == "") { headerLbl.text = "Properties — no object selected"; return; }

        var multiSel = editor.selectedObjNames.length > 1;
        headerLbl.text = multiSel
            ? 'Frame $frame — ${editor.selectedObjNames.length} objects'
            : 'Frame $frame — ${editor.selectedObjName}';

        var snap = frame < editor.doc.snapshots.length ? editor.doc.snapshots[frame] : null;
        var kf   = editor.doc.frames.get(frame);

        // Which props have keyframes on this obj?
        var trackedProps:Map<String, Bool> = [];
        if (kf != null) {
            for (d in kf.data)   if (d.obj == editor.selectedObjName) for (p in d.props.keys()) trackedProps.set(p, true);
            for (tw in kf.tweens) if (tw.obj == editor.selectedObjName) trackedProps.set(tw.prop, true);
        }

        var yy = 16;

        // ── tracked property rows ────────────────────────────────────
        for (prop => _ in trackedProps) {
            var curVal:String = "0";
            if (snap != null && snap.exists(editor.selectedObjName))
                curVal = Std.string(snap.get(editor.selectedObjName).get(prop) ?? 0);

            var row = _buildPropRow(prop, curVal, frame, yy);
            add(row); rows.push(row);
            yy += ROW_H + 2;
        }

        // ── tweens on this frame for selected object ──────────────────
        var tweensHeader = new FlxSpriteGroup(0, yy);
        tweensHeader.add(new FlxSprite(0, 0).makeGraphic(W, 14, 0xFF202020));
        var th = new FlxText(4, 2, W - 8, "Tweens on this frame", 7);
        th.color = 0xFF666688;
        tweensHeader.add(th);
        add(tweensHeader); rows.push(tweensHeader);
        yy += 16;

        if (kf != null) {
            for (tw in kf.tweens) {
                if (tw.obj != editor.selectedObjName) continue;
                var twRef = tw;
                var twFrame = frame;
                var twRow = _buildTweenRow(twRef, twFrame, yy);
                add(twRow); rows.push(twRow);
                yy += ROW_H + 2;
            }
        }

        // ── Add Tween button ─────────────────────────────────────────
        var addTweenBtn = new FlxButton(4, yy, "+ Add Tween", () -> {
            editor.tweenEditDialog.openNew(editor.selectedObjName, frame);
        });
        addTweenBtn.label.setFormat(null, 7, FlxColor.BLACK);
        var r3 = new FlxSpriteGroup(0, yy);
        r3.add(addTweenBtn);
        add(r3); rows.push(r3);
        yy += ROW_H + 2;

        // ── Add Property button ──────────────────────────────────────
        var addPropBtn = new FlxButton(4, yy, "+ Track Property", () -> editor.addPropDialog.open(editor.selectedObjName, frame));
        addPropBtn.label.setFormat(null, 7, FlxColor.BLACK);
        var r2 = new FlxSpriteGroup(0, yy);
        r2.add(addPropBtn);
        add(r2); rows.push(r2);
    }

    function _buildPropRow(prop:String, currentVal:String, frame:Int, yy:Int):FlxSpriteGroup {
        var g = new FlxSpriteGroup(0, yy);
        g.add(new FlxSprite(0, 0).makeGraphic(W, ROW_H, 0xFF323232));

        var lbl = new FlxText(4, 3, 70, prop, 8);
        lbl.color = 0xFFAAAAAA;
        g.add(lbl);

        var input = new FlxInputText(76, 2, W - 110, currentVal, 8);
        input.backgroundColor = 0xFF1E1E1E;
        input.fieldBorderColor = 0xFF555555;
        input.fieldBorderThickness = 1;
        input.callback = (text, _) -> {
            var v = Std.parseFloat(text);
            if (!Math.isNaN(v)) editor.addDataToFrame(frame, editor.selectedObjName, prop, v);
        };
        g.add(input);

        var hasDiamond = _hasKeyframeAt(frame, editor.selectedObjName, prop);
        var diamond = new FlxSprite(W - 18, Std.int(ROW_H / 2) - 4).makeGraphic(8, 8, hasDiamond ? 0xFFFFD700 : 0xFF555555);
        diamond.angle = 45;
        g.add(diamond);

        var rem = new FlxButton(W - 12, 2, "×", () -> editor.removeDataFromFrame(frame, editor.selectedObjName, prop));
        rem.setGraphicSize(12, 18); rem.updateHitbox();
        rem.label.setFormat(null, 7, FlxColor.WHITE);
        g.add(rem);

        return g;
    }

    function _buildTweenRow(tw:KFTween, frame:Int, yy:Int):FlxSpriteGroup {
        var g = new FlxSpriteGroup(0, yy);
        g.add(new FlxSprite(0, 0).makeGraphic(W, ROW_H, 0xFF28283A));

        // Teal left accent
        g.add(new FlxSprite(0, 0).makeGraphic(3, ROW_H, 0xFF336688));

        var summary = new FlxText(6, 3, W - 50, '${tw.prop}: →${tw.to} (${tw.duration}f, ${tw.ease})', 7);
        summary.color = 0xFF88AACC;
        g.add(summary);

        // Edit button
        var editBtn = new FlxButton(W - 42, 2, "Edit", () -> {
            editor.tweenEditDialog.openEdit(tw, frame);
        });
        editBtn.setGraphicSize(36, 18); editBtn.updateHitbox();
        editBtn.label.setFormat(null, 7, FlxColor.BLACK);
        g.add(editBtn);

        // Delete button
        var delBtn = new FlxButton(W - 8, 2, "×", () -> {
            editor.removeTweenFromFrame(frame, tw);
        });
        delBtn.setGraphicSize(10, 18); delBtn.updateHitbox();
        delBtn.label.setFormat(null, 7, FlxColor.WHITE);
        g.add(delBtn);

        return g;
    }

    function _hasKeyframeAt(frame:Int, obj:String, prop:String):Bool {
        var kf = editor.doc.frames.get(frame);
        if (kf == null) return false;
        for (d in kf.data) if (d.obj == obj && d.props.exists(prop)) return true;
        return false;
    }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  TWEEN EDIT DIALOG — create or edit a tween on a frame
// ═══════════════════════════════════════════════════════════════════════════════

class KFTweenEditDialog extends FlxSpriteGroup {
    var editor:CutSceneCreator;
    var propInput:FlxInputText;
    var fromInput:FlxInputText;
    var toInput:FlxInputText;
    var durationInput:FlxInputText;
    var easeLabel:FlxText;
    var errLbl:FlxText;
    var titleLbl:FlxText;

    // State
    var _objName:String  = "";
    var fr:Int       = 0;
    var _editingTween:KFTween = null; // null = new
    var _easeIndex:Int   = 0;

    static inline var W = 340;
    static inline var H = 200;

    public function new(editor:CutSceneCreator) {
        super();
        this.editor = editor;
        var px = Std.int((FlxG.width - W) / 2);
        var py = Std.int((FlxG.height - H) / 2);

        add(new FlxSprite().makeGraphic(FlxG.width, FlxG.height, 0xAA000000));
        add(new FlxSprite(px, py).makeGraphic(W, H, 0xFF333333));
        add(new FlxSprite(px, py).makeGraphic(W, 2, 0xFF336688));

        titleLbl = new FlxText(px + 6, py + 6, W - 12, "Add Tween", 9);
        titleLbl.color = 0xFF88AACC;
        add(titleLbl);

        var ly = py + 24;
        var lx = px + 6;
        var iw = W - 90;

        // Property
        _addLbl(lx, ly, "Prop:"); propInput = _addInput(lx + 80, ly, iw, "x"); ly += 22;

        // From (optional)
        _addLbl(lx, ly, "From (opt):"); fromInput = _addInput(lx + 80, ly, iw, ""); ly += 22;

        // To
        _addLbl(lx, ly, "To:"); toInput = _addInput(lx + 80, ly, iw, "0"); ly += 22;

        // Duration
        _addLbl(lx, ly, "Duration (f):"); durationInput = _addInput(lx + 80, ly, iw, "24"); ly += 22;

        // Ease — prev/next cycle
        _addLbl(lx, ly, "Ease:");
        var prevEase = new FlxButton(lx + 80, ly, "<", () -> { _easeIndex = (_easeIndex - 1 + KFTween.ALL_EASES.length) % KFTween.ALL_EASES.length; _updateEaseLabel(); });
        prevEase.setGraphicSize(16, 16); prevEase.updateHitbox(); prevEase.label.setFormat(null, 7, FlxColor.BLACK);
        add(prevEase);
        easeLabel = new FlxText(lx + 100, ly + 2, 130, "linear", 8);
        easeLabel.color = 0xFFCCCCCC;
        add(easeLabel);
        var nextEase = new FlxButton(lx + 234, ly, ">", () -> { _easeIndex = (_easeIndex + 1) % KFTween.ALL_EASES.length; _updateEaseLabel(); });
        nextEase.setGraphicSize(16, 16); nextEase.updateHitbox(); nextEase.label.setFormat(null, 7, FlxColor.BLACK);
        add(nextEase);
        ly += 22;

        errLbl = new FlxText(lx, ly, W - 12, "", 8); errLbl.color = 0xFFE24B4A; add(errLbl);

        var cancel = new FlxButton(px + W - 84, py + H - 22, "Cancel", () -> visible = false);
        cancel.label.setFormat(null, 8, FlxColor.BLACK); add(cancel);
        var ok = new FlxButton(px + W - 168, py + H - 22, "Apply", _onApply);
        ok.label.setFormat(null, 8, FlxColor.BLACK); add(ok);
    }

    function _addLbl(x:Float, y:Float, t:String) {
        var l = new FlxText(x, y + 2, 78, t, 7); l.color = 0xFFAAAAAA; add(l);
    }

    function _addInput(x:Float, y:Float, w:Int, def:String):FlxInputText {
        var i = new FlxInputText(x, y, w, def, 8);
        i.backgroundColor = 0xFF1E1E1E; i.fieldBorderColor = 0xFF555555; i.fieldBorderThickness = 1;
        add(i); return i;
    }

    function _updateEaseLabel() {
        easeLabel.text = KFTween.ALL_EASES[_easeIndex];
    }

    /** Open in "new tween" mode. */
    public function openNew(objName:String, frame:Int) {
        _objName = objName;
        fr   = frame;
        _editingTween = null;
        titleLbl.text = 'Add Tween to "$objName" @ frame $frame';
        propInput.text = "x";
        fromInput.text = "";
        toInput.text   = "0";
        durationInput.text = "24";
        _easeIndex = 0;
        _updateEaseLabel();
        errLbl.text = "";
        visible = true;
    }

    /** Open in "edit existing tween" mode. */
    public function openEdit(tw:KFTween, frame:Int) {
        _objName      = tw.obj;
        fr        = frame;
        _editingTween = tw;
        titleLbl.text = 'Edit Tween "${tw.prop}" on "${tw.obj}"';
        propInput.text     = tw.prop;
        fromInput.text     = tw.from != null ? Std.string(tw.from) : "";
        toInput.text       = Std.string(tw.to);
        durationInput.text = Std.string(tw.duration);
        _easeIndex = KFTween.ALL_EASES.indexOf(tw.ease);
        if (_easeIndex < 0) _easeIndex = 0;
        _updateEaseLabel();
        errLbl.text = "";
        visible = true;
    }

    function _onApply() {
        var prop = propInput.text.trim();
        if (prop == "") { errLbl.text = "Property required."; return; }

        var to = Std.parseFloat(toInput.text);
        if (Math.isNaN(to)) { errLbl.text = "To value must be a number."; return; }

        var dur = Std.parseInt(durationInput.text);
        if (dur == null || dur <= 0) { errLbl.text = "Duration must be a positive integer."; return; }

        var fromStr = fromInput.text.trim();
        var fromVal:Null<Float> = fromStr == "" ? null : Std.parseFloat(fromStr);
        if (fromStr != "" && (fromVal == null || Math.isNaN(fromVal))) {
            errLbl.text = "From must be a number or empty."; return;
        }

        var ease = KFTween.ALL_EASES[_easeIndex];

        if (_editingTween != null) {
            // Mutate the existing tween in-place, then mark dirty
            editor.snapshot();
            _editingTween.prop     = prop;
            _editingTween.from     = fromVal;
            _editingTween.to       = to;
            _editingTween.duration = dur;
            _editingTween.ease     = ease;
            editor.doc.snapshotsDirty = true;
            editor.rebakeAndRefresh();
            editor.setStatus('Updated tween "$prop" on "${_editingTween.obj}".');
        } else {
            var tw = new KFTween();
            tw.obj      = _objName;
            tw.prop     = prop;
            tw.from     = fromVal;
            tw.to       = to;
            tw.duration = dur;
            tw.ease     = ease;
            editor.addTweenToFrame(fr, tw);
            editor.setStatus('Added tween "$prop" to "${_objName}" @ frame $fr.');
        }
        visible = false;
    }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  TIMELINE — Adobe Animate style
// ═══════════════════════════════════════════════════════════════════════════════

class KFTimeline extends FlxSpriteGroup {
    var editor:CutSceneCreator;

    static inline var ROW_H    = 18;
    static inline var LABEL_W  = 130;
    static inline var HEADER_H = 20;
    static var PANEL_W(get, never):Int; static function get_PANEL_W() return FlxG.width;

    var framesVisible:Int = 60;
    var scrollFrameOffset:Int = 0;

    var playheadSprite:FlxSprite;
    var rowSprites:Array<FlxSpriteGroup> = [];
    var headerSprites:Array<FlxSprite>   = [];
    var headerTexts:Array<FlxText>       = [];

    // Right-click tween context menu
    var _contextMenu:KFTweenContextMenu;

    public function new(editor:CutSceneCreator) {
        var y = FlxG.height - CutSceneCreator.TIMELINE_H - CutSceneCreator.STATUS_H;
        super(0, y);
        this.editor = editor;

        add(new FlxSprite().makeGraphic(FlxG.width, CutSceneCreator.TIMELINE_H, 0xFF1E1E1E));
        add(new FlxSprite().makeGraphic(FlxG.width, 1, 0xFF444444));

        playheadSprite = new FlxSprite(LABEL_W, HEADER_H).makeGraphic(2, CutSceneCreator.TIMELINE_H - HEADER_H, 0xFFFF4444);
        add(playheadSprite);

        _contextMenu = new KFTweenContextMenu(editor);
        _contextMenu.visible = false;
        add(_contextMenu);

        rebuild();
    }

    public function rebuild() {
        for (r in rowSprites)    { remove(r, true); r.destroy(); }
        for (s in headerSprites) { remove(s, true); s.destroy(); }
        for (t in headerTexts)   { remove(t, true); t.destroy(); }
        rowSprites = []; headerSprites = []; headerTexts = [];

        _buildHeader();
        _buildRows();
        _updatePlayhead();

        // Keep playhead and context menu on top
        members.remove(playheadSprite);
        members.push(playheadSprite);
        members.remove(_contextMenu);
        members.push(_contextMenu);
    }

    public function refresh() {
        _updatePlayhead();
        rebuild();
    }

    function _buildHeader() {
        var frameW = _frameWidth();
        add(new FlxSprite(0, 0).makeGraphic(FlxG.width, HEADER_H, 0xFF2A2A2A));

        for (i in 0...framesVisible) {
            var absFrame = scrollFrameOffset + i;
            if (absFrame >= editor.doc.totalFrames) break;
            var px = LABEL_W + Std.int(i * frameW);

            var tick = new KFTimelineTick(px, HEADER_H - 12, absFrame, editor);
            tick.makeGraphic(Std.int(frameW * 5), 12, 0x00000000);
            tick.drawRect(0, 0, Std.int(frameW * 5), 12, 0x00000000);
            tick.drawRect(0, 0, 1, 12, 0xFF555555);
            headerSprites.push(tick);
            add(tick);

            if (i % 5 == 0) {
                var lbl = new FlxText(px + 1, 3, Std.int(frameW * 5), Std.string(absFrame), 7);
                lbl.color = 0xFF888888;
                headerTexts.push(lbl);
                add(lbl);
            }
        }
    }

    function _buildRows() {
        var yy = HEADER_H;
        var frameW = _frameWidth();

        for (o in editor.doc.objects) {
            if (yy + ROW_H > CutSceneCreator.TIMELINE_H) break;
            var row = _buildObjectRow(o, yy, frameW);
            add(row); rowSprites.push(row);
            yy += ROW_H;

            var expanded = editor.expandedObjects.get(o.name) ?? false;
            if (expanded) {
                var trackedProps = _getTrackedProps(o.name);
                for (prop in trackedProps) {
                    if (yy + ROW_H > CutSceneCreator.TIMELINE_H) break;
                    var prow = _buildPropRow(o.name, prop, yy, frameW);
                    add(prow); rowSprites.push(prow);
                    yy += ROW_H;
                }
            }
        }
    }

    function _buildObjectRow(o:KFObject, yy:Int, frameW:Float):FlxSpriteGroup {
        var g = new FlxSpriteGroup(0, yy);
        var isSelected = editor.selectedObjNames.contains(o.name);

        g.add(new FlxSprite(0, 0).makeGraphic(LABEL_W, ROW_H, isSelected ? 0xFF303050 : 0xFF252525));
        g.add(new FlxSprite(LABEL_W, 0).makeGraphic(FlxG.width - LABEL_W, ROW_H, isSelected ? 0xFF282838 : 0xFF202020));
        g.add(new FlxSprite(0, ROW_H - 1).makeGraphic(FlxG.width, 1, 0xFF333333));

        var typeColor = o.type == "Sprite" ? 0xFF1D9E75 : 0xFF378ADD;
        g.add(new FlxSprite(4, Std.int(ROW_H / 2) - 3).makeGraphic(6, 6, typeColor));

        var exp = editor.expandedObjects.get(o.name) ?? false;
        var expBtn = new FlxUIButton(12, 1, "", () -> {
            editor.expandedObjects.set(o.name, !exp);
            rebuild();
        });
        expBtn.loadGraphic(Paths.image('ui/menu', "button_square"), true, 20, 20);
        expBtn.updateHitbox();
        expBtn.autoCenterLabel();
        expBtn.addIcon(new FlxSprite().loadGraphic(Paths.DEBUG('cc_${exp ? "down" : "right"}', "png")), 0, 0, true);
        g.add(expBtn);

        var lbl = new FlxText(28, 3, LABEL_W - 32, o.name, 8);
        lbl.color = isSelected ? FlxColor.WHITE : 0xFFBBBBBB;
        g.add(lbl);

        _addDiamonds(g, o.name, null, frameW);
        _addTweenBars(g, o.name, null, frameW, yy);

        var objName = o.name;
        var hit = new FlxButton(0, 0, "", () -> editor.selectObject(objName, FlxG.keys.pressed.SHIFT));
        hit.makeGraphic(LABEL_W, ROW_H, FlxColor.TRANSPARENT);
        g.add(hit);

        return g;
    }

    function _buildPropRow(objName:String, prop:String, yy:Int, frameW:Float):FlxSpriteGroup {
        var g = new FlxSpriteGroup(0, yy);
        g.add(new FlxSprite(0, 0).makeGraphic(LABEL_W, ROW_H, 0xFF1E1E2A));
        g.add(new FlxSprite(LABEL_W, 0).makeGraphic(FlxG.width - LABEL_W, ROW_H, 0xFF1A1A24));
        g.add(new FlxSprite(0, ROW_H - 1).makeGraphic(FlxG.width, 1, 0xFF2A2A2A));
        g.add(new FlxSprite(20, Std.int(ROW_H / 2)).makeGraphic(8, 1, 0xFF444466));

        var lbl = new FlxText(30, 3, LABEL_W - 34, prop, 7);
        lbl.color = 0xFF7777BB;
        g.add(lbl);

        _addDiamonds(g, objName, prop, frameW);
        _addTweenBars(g, objName, prop, frameW, yy);

        return g;
    }

    function _addDiamonds(g:FlxSpriteGroup, objName:String, ?prop:String, frameW:Float) {
        for (frameNum => kf in editor.doc.frames) {
            var i = frameNum - scrollFrameOffset;
            if (i < 0 || i >= framesVisible) continue;
            var px = LABEL_W + Std.int(i * frameW);

            var hasData = false;
            if (prop == null) {
                for (d in kf.data)   if (d.obj == objName) { hasData = true; break; }
                if (!hasData) for (tw in kf.tweens) if (tw.obj == objName) { hasData = true; break; }
            } else {
                for (d in kf.data)   if (d.obj == objName && d.props.exists(prop)) { hasData = true; break; }
                if (!hasData) for (tw in kf.tweens) if (tw.obj == objName && tw.prop == prop) { hasData = true; break; }
            }

            if (hasData) {
                var isCurrentFrame = frameNum == editor.currentFrame;
                var diamond = new FlxSprite(px - 4, Std.int(ROW_H / 2) - 4).makeGraphic(8, 8, isCurrentFrame ? 0xFFFFD700 : 0xFFAA8800);
                diamond.angle = 45;
                g.add(diamond);

                var ff = frameNum;
                var seekHit = new FlxButton(px - 6, 0, "", () -> editor.seekToFrame(ff));
                seekHit.makeGraphic(12, ROW_H, FlxColor.TRANSPARENT);
                g.add(seekHit);
            }
        }
    }

    function _addTweenBars(g:FlxSpriteGroup, objName:String, ?prop:String, frameW:Float, rowY:Int) {
        for (frameNum => kf in editor.doc.frames) {
            for (tw in kf.tweens) {
                if (tw.obj != objName) continue;
                if (prop != null && tw.prop != prop) continue;

                var startI = frameNum - scrollFrameOffset;
                var endI   = (frameNum + tw.duration) - scrollFrameOffset;
                if (endI < 0 || startI >= framesVisible) continue;

                var sx = LABEL_W + Std.int(Math.max(0, startI) * frameW);
                var ex = LABEL_W + Std.int(Math.min(framesVisible, endI) * frameW);
                var barW = Std.int(ex - sx);
                if (barW > 0) {
                    var bar = new FlxSprite(sx, Std.int(ROW_H / 2) - 2).makeGraphic(barW, 4, 0xFF336688);
                    bar.alpha = 0.6;
                    g.add(bar);

                    // Right-click on bar to edit
                    var twRef   = tw;
                    var twFrame = frameNum;
                    var barHit  = new FlxButton(sx, 0, "", () -> {});
                    barHit.makeGraphic(barW, ROW_H, FlxColor.TRANSPARENT);
                    // We'll handle right-click in the update override via a helper
                    g.add(barHit);

                    // Invisible right-click zone stored as a custom sprite subclass
                    var rcZone = new KFTweenBarRightClickZone(sx, 0, barW, ROW_H, twRef, twFrame, editor, _contextMenu);
                    g.add(rcZone);
                }
            }
        }
    }

    function _getTrackedProps(objName:String):Array<String> {
        var props:Map<String, Bool> = [];
        for (_ => kf in editor.doc.frames) {
            for (d in kf.data)   if (d.obj == objName) for (p in d.props.keys()) props.set(p, true);
            for (tw in kf.tweens) if (tw.obj == objName) props.set(tw.prop, true);
        }
        return [for (p in props.keys()) p];
    }

    public function _updatePlayhead() {
        var frameW = _frameWidth();
        var relFrame = editor.currentFrame - scrollFrameOffset;
        playheadSprite.x = LABEL_W + relFrame * frameW;
        playheadSprite.visible = relFrame >= 0 && relFrame < framesVisible;
    }

    function _frameWidth():Float return (FlxG.width - LABEL_W) / framesVisible;

    override public function update(elapsed:Float) {
        super.update(elapsed);

        // Dismiss context menu on left click
        if (FlxG.mouse.justPressed && _contextMenu.visible) {
            _contextMenu.visible = false;
            return;
        }

        var my = FlxG.mouse.y;
        var timelineY = FlxG.height - CutSceneCreator.TIMELINE_H - CutSceneCreator.STATUS_H;
        var inTimeline = my >= timelineY && my < FlxG.height - CutSceneCreator.STATUS_H;

        if (!inTimeline || FlxG.mouse.wheel == 0) return;

        if (FlxG.keys.pressed.SHIFT) {
            scrollFrameOffset = Std.int(Math.max(0, scrollFrameOffset - FlxG.mouse.wheel));
            rebuild();
        } else {
            framesVisible = Std.int(Math.max(10, Math.min(200, framesVisible - FlxG.mouse.wheel * 5)));
            rebuild();
        }

        if (FlxG.mouse.justPressed && my < timelineY + HEADER_H) {
            var relX = FlxG.mouse.x - LABEL_W;
            if (relX >= 0) {
                var frameW = _frameWidth();
                var clickedFrame = scrollFrameOffset + Std.int(relX / frameW);
                editor.seekToFrame(clickedFrame);
            }
        }
    }
}

// ── Right-click zone sprite on tween bars ────────────────────────────────────

class KFTweenBarRightClickZone extends FlxSprite {
    var tw:KFTween;
    var fr:Int;
    var editor:CutSceneCreator;
    var contextMenu:KFTweenContextMenu;

    public function new(x:Float, y:Float, w:Int, h:Int, tw:KFTween, frame:Int, editor:CutSceneCreator, menu:KFTweenContextMenu) {
        super(x, y);
        makeGraphic(w, h, FlxColor.TRANSPARENT);
        this.tw = tw; fr = frame;
        this.editor = editor; this.contextMenu = menu;
    }

    override public function update(elapsed:Float) {
        super.update(elapsed);
        #if desktop
        if (FlxG.mouse.justPressedRight && FlxG.mouse.overlaps(this)) {
            contextMenu.openFor(tw, fr, FlxG.mouse.x, FlxG.mouse.y);
        }
        #end
    }
}

// ── Tween context menu ───────────────────────────────────────────────────────

class KFTweenContextMenu extends FlxSpriteGroup {
    var editor:CutSceneCreator;
    static inline var W = 120;
    static inline var ITEM_H = 18;

    public function new(editor:CutSceneCreator) {
        super();
        this.editor = editor;
        visible = false;
        cameras = [FlxG.camera];
    }

    public function openFor(tw:KFTween, frame:Int, mx:Float, my:Float) {
        // Clear previous items
        for (m in members) { remove(m, true); m.destroy(); }

        var items = [
            { label: "Edit Tween", cb: () -> { editor.tweenEditDialog.openEdit(tw, frame); visible = false; } },
            { label: "Delete",     cb: () -> { editor.removeTweenFromFrame(frame, tw); visible = false; } }
        ];

        // Position the menu, clamp to screen
        var menuH = items.length * ITEM_H;
        var px = Std.int(Math.min(mx, FlxG.width - W - 2));
        var py = Std.int(Math.min(my, FlxG.height - menuH - 2));

        add(new FlxSprite(px - 1, py - 1).makeGraphic(W + 2, menuH + 2, 0xFF555555));
        add(new FlxSprite(px, py).makeGraphic(W, menuH, 0xFF2A2A2A));

        for (i in 0...items.length) {
            var item = items[i];
            var iy = py + i * ITEM_H;
            var bg = new FlxSprite(px, iy).makeGraphic(W, ITEM_H, 0xFF2A2A2A);
            add(bg);
            var lbl = new FlxText(px + 6, iy + 3, W - 8, item.label, 8);
            lbl.color = 0xFFDDDDDD;
            add(lbl);
            var btn = new FlxButton(px, iy, "", item.cb);
            btn.makeGraphic(W, ITEM_H, FlxColor.TRANSPARENT);
            add(btn);
        }

        visible = true;
        cameras = [FlxG.camera];
    }
}

class KFTimelineTick extends FlxSprite {
    private var f:Int = 0;
    private var editor:CutSceneCreator;

    public function new(x:Float, y:Float, frameIndex:Int, e:CutSceneCreator) {
        super(x, y);
        f = frameIndex;
        editor = e;
    }

    override public function update(elapsed:Float) {
        super.update(elapsed);
        if (FlxG.mouse.overlaps(this) && FlxG.mouse.justPressed) {
            editor.currentFrame = f;
            @:privateAccess editor.timeline._updatePlayhead();
        }
    }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  STOP OVERLAY
// ═══════════════════════════════════════════════════════════════════════════════

class KFStopOverlay extends FlxSpriteGroup {
    public function new(editor:CutSceneCreator) {
        super();
        cameras = [FlxG.camera];
        var bar = new FlxSprite(CutSceneCreator.PREVIEW_X, CutSceneCreator.PREVIEW_Y).makeGraphic(CutSceneCreator.PREVIEW_W, 20, 0xBB000000);
        bar.cameras = [FlxG.camera];
        add(bar);

        var hint = new FlxText(CutSceneCreator.PREVIEW_X + 4, CutSceneCreator.PREVIEW_Y + 2, CutSceneCreator.PREVIEW_W - 70, "ESC or click ■ to stop", 7);
        hint.color = 0xFFAAAAAA; hint.cameras = [FlxG.camera];
        add(hint);

        var stopBtn = new FlxButton(CutSceneCreator.PREVIEW_X + CutSceneCreator.PREVIEW_W - 58, CutSceneCreator.PREVIEW_Y + 1, "■ STOP", editor.stopPreview);
        stopBtn.setGraphicSize(54, 18); stopBtn.updateHitbox();
        stopBtn.label.setFormat(null, 8, FlxColor.WHITE);
        stopBtn.cameras = [FlxG.camera];
        add(stopBtn);
    }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  ERROR POPUP
// ═══════════════════════════════════════════════════════════════════════════════

class KFErrorPopup extends Popup {
    public function new(editor:CutSceneCreator, error:String) {
        Flags.CC_THEREISAPOPUPOPENDONOTUSECUTSCENECONTROLS = true;
        super("Error", error, [{l:"Dismiss",c:true,f:null}], false, #if(html5)null#else""#end, false, FlxPoint.weak(0, 0), true, true);
        background.color  = 0xFF3A1A1A;
        background2.color = 0xFFE24B4A;
        header.color      = 0xFFE24B4A;
        body.wordWrap     = true;
        body.color        = 0xFFEEEEEE;
        subStateClosed.add((_) -> { Flags.CC_THEREISAPOPUPOPENDONOTUSECUTSCENECONTROLS = false; });
    }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  NEW CUTSCENE DIALOG
// ═══════════════════════════════════════════════════════════════════════════════

class KFNewCutsceneDialog extends Popup {
    var editor:CutSceneCreator;
    var nameInput:FlxInputText;
    var fpsInput:FlxInputText;
    var framesInput:FlxInputText;
    var _nameLabel:FlxText;
    var _fpsLabel:FlxText;
    var _framesLabel:FlxText;

    public function new(editor:CutSceneCreator) {
        Flags.CC_THEREISAPOPUPOPENDONOTUSECUTSCENECONTROLS = true;
        this.editor = editor;
        super("New Cutscene", "", [{l:"Load Cutscene",c:false,f:() -> {
            editor.loadFromFile(Flags.CC_DEFAULTLOADPATH);
            close();
            Flags.CC_THEREISAPOPUPOPENDONOTUSECUTSCENECONTROLS = false;
            Flags.CC_MADECUTSCENE = true;
        }}, {l:"Create",c:true,f:() -> {
            _onCreate();
            Flags.CC_THEREISAPOPUPOPENDONOTUSECUTSCENECONTROLS = false;
        }}], false, #if(html5)null#else""#end, false, FlxPoint.weak(0, 0), false, true);
        background.color = header.color = 0xFF4488FF;
        background2.color = 0xFF333333;

        _nameLabel = _lbl(5, 15, "Name:");
        nameInput  = _input(5 + _nameLabel.fieldWidth, 15, background2.width - _nameLabel.fieldWidth, "untitled");

        _fpsLabel = _lbl(5, 35, "FPS:");
        fpsInput  = _input(5 + _fpsLabel.fieldWidth, 35, background2.width - _fpsLabel.fieldWidth, "60");

        _framesLabel = _lbl(5, 55, "Frames:");
        framesInput  = _input(5 + _framesLabel.fieldWidth, 55, background2.width - _framesLabel.fieldWidth, "120");
    }

    function _lbl(x:Float, y:Float, t:String):FlxText {
        var l = new FlxText(x, y + 2, 0, t, 8); l.color = 0xFFAAAAAA; l.camera = camera; group.add(l);
        return l;
    }

    function _input(x:Float, y:Float, w:Float, def:String):FlxInputText {
        var i = new FlxInputText(x, y + 2, w.floor(), def, 8);
        i.backgroundColor = 0xFF1E1E1E; i.textField.textColor = 0xFFFFFF;
        i.fieldBorderColor = 0xFF555555; i.camera = camera; i.fieldBorderThickness = 1;
        group.add(i); return i;
    }

    function _onCreate() {
        var fps    = Std.parseInt(fpsInput.text) ?? 24;
        var frames = Std.parseInt(framesInput.text) ?? 120;
        editor.doc = new KFDocument();
        editor.doc.name = nameInput.text.trim() == "" ? "untitled" : nameInput.text.trim();
        editor.doc.fps  = fps;
        editor.doc.totalFrames = frames;
        editor.doc.bakeSnapshots();
        editor.buildLivePreview(); // start live preview for fresh doc
        editor.rebakeAndRefresh();
        editor.setStatus('Created "${editor.doc.name}" @ ${fps}fps, $frames frames.');
        Flags.CC_MADECUTSCENE = true;
    }

    override function update(elapsed:Float) {
        super.update(elapsed);
        if (Flags.CC_MADECUTSCENE && FlxG.keys.justPressed.ESCAPE) close();
    }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  ADD PROPERTY DIALOG
// ═══════════════════════════════════════════════════════════════════════════════

class KFAddPropDialog extends FlxSpriteGroup {
    var editor:CutSceneCreator;
    var propInput:FlxInputText;
    var valInput:FlxInputText;
    var errLbl:FlxText;
    var _objName:String = "";
    var _curFrame:Int   = 0;

    public function new(editor:CutSceneCreator) {
        super();
        this.editor = editor;
        var pw = 320; var ph = 120;
        var px = Std.int((FlxG.width - pw) / 2);
        var py = Std.int((FlxG.height - ph) / 2);

        add(new FlxSprite().makeGraphic(FlxG.width, FlxG.height, 0xAA000000));
        add(new FlxSprite(px, py).makeGraphic(pw, ph, 0xFF333333));

        var title = new FlxText(px + 6, py + 5, pw - 12, "Track Property", 9); title.color = 0xFFCCCCCC; add(title);

        var lbl1 = new FlxText(px + 6, py + 22, 70, "Property:", 8); lbl1.color = 0xFFAAAAAA; add(lbl1);
        propInput = new FlxInputText(px + 80, py + 20, pw - 86, "x", 8);
        propInput.backgroundColor = 0xFF1E1E1E; propInput.fieldBorderColor = 0xFF555555; propInput.fieldBorderThickness = 1;
        add(propInput);

        var lbl2 = new FlxText(px + 6, py + 46, 70, "Value:", 8); lbl2.color = 0xFFAAAAAA; add(lbl2);
        valInput = new FlxInputText(px + 80, py + 44, 80, "0", 8);
        valInput.backgroundColor = 0xFF1E1E1E; valInput.fieldBorderColor = 0xFF555555; valInput.fieldBorderThickness = 1;
        add(valInput);

        errLbl = new FlxText(px + 6, py + 68, pw - 12, "", 8); errLbl.color = 0xFFE24B4A; add(errLbl);

        var cancel = new FlxButton(px + pw - 84, py + ph - 22, "Cancel", () -> visible = false);
        cancel.label.setFormat(null, 8, FlxColor.BLACK); add(cancel);

        var ok = new FlxButton(px + pw - 168, py + ph - 22, "Add", _onAdd);
        ok.label.setFormat(null, 8, FlxColor.BLACK); add(ok);
    }

    public function open(objName:String, frame:Int) {
        _objName = objName;
        _curFrame = frame;
        errLbl.text = "";
        visible = true;
    }

    function _onAdd() {
        var prop = propInput.text.trim();
        var val  = Std.parseFloat(valInput.text);
        if (Math.isNaN(val)) { errLbl.text = "Value must be a number."; return; }

        var obj = _findLiveObject(prop);
        if (obj == null) { errLbl.text = 'Property "$prop" not found on $_objName.'; return; }

        editor.addDataToFrame(_curFrame, _objName, prop, val);
        visible = false;
    }

    function _findLiveObject(prop:String):Dynamic {
        var kfObj = KFDocument.findObject(_objName, editor.doc.objects);
        if (kfObj == null) return null;

        var testObj:Dynamic = null;
        switch(kfObj.type) {
            case "Sprite": testObj = new FlxSprite();
            case "Text":   testObj = new FlxText(0, 0, 0, "", 16);
            default:       testObj = new FlxSpriteGroup();
        }

        if (prop.indexOf(".") >= 0) {
            var parts = prop.split(".");
            var target:Dynamic = testObj;
            for (i in 0...parts.length - 1) {
                target = Reflect.getProperty(target, parts[i]);
                if (target == null) { testObj.destroy(); return null; }
            }
            var exists = Reflect.hasField(target, parts[parts.length - 1]) ||
                         Reflect.getProperty(target, parts[parts.length - 1]) != null;
            testObj.destroy();
            return exists ? target : null;
        } else {
            var exists = Reflect.hasField(testObj, prop) || Reflect.getProperty(testObj, prop) != null;
            testObj.destroy();
            return exists ? testObj : null;
        }
    }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  ADD OBJECT DIALOG
// ═══════════════════════════════════════════════════════════════════════════════

class KFAddObjectDialog extends FlxSpriteGroup {
    var editor:CutSceneCreator;
    var nameInput:FlxInputText;
    var imgDirInput:FlxInputText;
    var imgInput:FlxInputText;
    var textInput:FlxInputText;
    var selectedType:String = "Sprite";
    var typeButtons:Map<String, FlxButton> = [];
    var spriteFields:FlxSpriteGroup;
    var textFields:FlxSpriteGroup;

    public function new(editor:CutSceneCreator) {
        super();
        this.editor = editor;
        var pw = 340; var ph = 170;
        var px = Std.int((FlxG.width - pw) / 2);
        var py = Std.int((FlxG.height - ph) / 2);

        add(new FlxSprite().makeGraphic(FlxG.width, FlxG.height, 0xAA000000));
        add(new FlxSprite(px, py).makeGraphic(pw, ph, 0xFF333333));
        add(new FlxSprite(px, py).makeGraphic(pw, 2, 0xFF44AA66));

        var title = new FlxText(px + 6, py + 6, pw - 12, "Add Object", 10); title.color = 0xFF44AA66; add(title);

        var lbl1 = new FlxText(px + 6, py + 22, 50, "Name:", 8); lbl1.color = 0xFFAAAAAA; add(lbl1);
        nameInput = new FlxInputText(px + 60, py + 20, pw - 66, "obj_name", 8);
        nameInput.backgroundColor = 0xFF1E1E1E; nameInput.fieldBorderColor = 0xFF555555; nameInput.fieldBorderThickness = 1;
        add(nameInput);

        var lbl2 = new FlxText(px + 6, py + 44, 50, "Type:", 8); lbl2.color = 0xFFAAAAAA; add(lbl2);
        var types = ["Sprite", "Text", "Group"];
        var tx = px + 60;
        for (t in types) {
            var tt = t;
            var b = new FlxButton(tx, py + 42, tt, () -> _setType(tt));
            b.setGraphicSize(60, 16); b.updateHitbox(); b.label.setFormat(null, 7, FlxColor.BLACK);
            add(b);
            typeButtons.set(tt, b);
            tx += 64;
        }

        spriteFields = new FlxSpriteGroup(px, py + 62);
        var l1 = new FlxText(6, 2, 60, "image_dir:", 7); l1.color = 0xFFAAAAAA; spriteFields.add(l1);
        imgDirInput = new FlxInputText(70, 0, pw - 76, "", 8);
        imgDirInput.backgroundColor = 0xFF1E1E1E; imgDirInput.fieldBorderColor = 0xFF555555; imgDirInput.fieldBorderThickness = 1;
        spriteFields.add(imgDirInput);
        var l2 = new FlxText(6, 22, 60, "image:", 7); l2.color = 0xFFAAAAAA; spriteFields.add(l2);
        imgInput = new FlxInputText(70, 20, pw - 76, "", 8);
        imgInput.backgroundColor = 0xFF1E1E1E; imgInput.fieldBorderColor = 0xFF555555; imgInput.fieldBorderThickness = 1;
        spriteFields.add(imgInput);
        add(spriteFields);

        textFields = new FlxSpriteGroup(px, py + 62);
        textFields.visible = false;
        var l3 = new FlxText(6, 2, 50, "text:", 7); l3.color = 0xFFAAAAAA; textFields.add(l3);
        textInput = new FlxInputText(60, 0, pw - 66, "Hello, World!", 8);
        textInput.backgroundColor = 0xFF1E1E1E; textInput.fieldBorderColor = 0xFF555555; textInput.fieldBorderThickness = 1;
        textFields.add(textInput);
        add(textFields);

        var cancel = new FlxButton(px + pw - 84, py + ph - 22, "Cancel", () -> visible = false);
        cancel.label.setFormat(null, 8, FlxColor.BLACK); add(cancel);

        var create = new FlxButton(px + pw - 168, py + ph - 22, "Create", _onCreate);
        create.label.setFormat(null, 8, FlxColor.BLACK); add(create);
    }

    function _setType(t:String) {
        selectedType = t;
        spriteFields.visible = t == "Sprite";
        textFields.visible   = t == "Text";
    }

    function _onCreate() {
        var name = nameInput.text.trim();
        if (name == "") return;
        var attrs:Map<String, String> = ["name" => name, "x" => "0", "y" => "0"];
        switch(selectedType) {
            case "Sprite":
                attrs.set("image_dir", imgDirInput.text.trim());
                attrs.set("image", imgInput.text.trim());
                attrs.set("animated", "false");
                attrs.set("frameWidth", "64");
                attrs.set("frameHeight", "64");
            case "Text":
                attrs.set("text", textInput.text);
                attrs.set("size", "16");
                attrs.set("width", "0");
                attrs.set("alignment", "left");
        }
        // parentName is auto-detected from selectedObjName inside addObject
        editor.addObject(selectedType, name, attrs, null);
        visible = false;
    }
}

#end