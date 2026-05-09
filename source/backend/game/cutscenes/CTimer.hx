package backend.game.cutscenes;

/** <timer frames="48"> children... </timer> */
class CTimer {
    public var frames:Int;
    public var children:Array<CData> = [];

    public function new(f:Int) { this.frames = f; }

    public static function fromXml(el:Xml):CTimer {
        var t = new CTimer(Std.parseInt(el.get("frames") ?? "24") ?? 24);
        for (child in el.elements())
            if (child.nodeName == "data") t.children.push(CData.fromXml(child));
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
