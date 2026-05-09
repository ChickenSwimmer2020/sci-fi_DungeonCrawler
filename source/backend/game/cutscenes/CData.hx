package backend.game.cutscenes;

/** <data obj="sky" y="-720" alpha="1" scale.x="2"/> */
class CData {
    public var obj:String;
    public var props:Map<String, Float> = [];

    public function new(obj:String) { this.obj = obj; }

    public static function fromXml(el:Xml):CData {
        var d = new CData(el.get("obj") ?? "");
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
