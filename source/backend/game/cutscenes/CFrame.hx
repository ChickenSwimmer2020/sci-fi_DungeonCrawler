package backend.game.cutscenes;

/** One frame in the <frames> block. */
class CFrame {
    public var frameNum:Int;
    public var data:Array<CData>    = [];
    public var tweens:Array<CTween> = [];
    public var timers:Array<CTimer> = [];

    public function new(n:Int) { this.frameNum = n; }

    public static function fromXml(el:Xml):CFrame {
        var kf = new CFrame(Std.parseInt(el.get("n") ?? "0") ?? 0);
        for (child in el.elements()) {
            switch(child.nodeName) {
                case "data":  kf.data.push(CData.fromXml(child));
                case "Tween": kf.tweens.push(CTween.fromXml(child));
                case "timer": kf.timers.push(CTimer.fromXml(child));
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