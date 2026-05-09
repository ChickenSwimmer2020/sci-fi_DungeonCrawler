package backend.game.cutscenes;

/** Object declaration in <objects> block. */
class CObject {
    public var name:String;
    public var type:String;
    public var attrs:Map<String, String> = [];
    public var children:Array<CObject> = [];

    public function new(type:String, name:String) { this.type = type; this.name = name; }

    public static function fromXml(el:Xml):CObject {
        var o = new CObject(el.nodeName, el.get("name") ?? "unnamed");
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