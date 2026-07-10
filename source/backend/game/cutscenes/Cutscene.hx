package backend.game.cutscenes;

/**
 * Keyframe-based cutscene runtime.
 * Can run as a substate (full test) OR be embedded directly into the editor
 * state and rendered to a dedicated camera (live preview).
 */
class Cutscene extends FlxSubState {
    public var doc:CDocument;
    public var currentFrame:Int = 0;
    public var playing:Bool     = false;
    public var onComplete:Void->Void;

    public var objects:Map<String, Dynamic> = [];

    var _frameTimer:Float = 0;
    var _secPerFrame:Float;
    var _activeFlxTweens:Array<FlxTween> = [];

    public function new(doc:OneOfTwo<CDocument, String>) {
        super(0x00000000);

        if(doc is String) {
            this.doc = CDocument.fromXml(Xml.parse(Paths.getXml(doc)));
            _secPerFrame = 1.0 / this.doc.fps;
        }else{
            this.doc = doc;
            _secPerFrame = 1.0 / this.doc.fps;
        }
    }

    override public function create() {
        super.create();
        _buildObjects(doc.objects, null);
        if (doc.snapshotsDirty) doc.bakeSnapshots();
        _applySnapshot(0);
    }

    // ── object construction ──────────────────────────────────────────

    function _buildObjects(list:Array<CObject>, ?parentGroup:FlxSpriteGroup) {
        for (o in list) {
            var built:Dynamic = null;
            switch(o.type) {
                case "Text":
                    var t = new ExtendedText(
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
                    built = new FlxSprite(0, 0).makeGraphic(4, 4, 0x00FFFFFF);
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

    public function play():Cutscene  { playing = true; return this; }
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

    public function setCompleteFunc(f:Void->Void):Cutscene {
        onComplete = f;
        return this;
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
            var ease = CTween.resolveEase(tw.ease);
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