package backend.parsing;

class Json extends haxe.Json {
    public static inline function parse(text:String):Dynamic return haxe.Json.parse(text);

    static var attempts:Int = Flags.DEFAULT_JSON_RECURSION_CHECKS;

    public static function checkRecursive(data:Dynamic, key:String):Dynamic {
        var current:Dynamic = data;
        for (part in key.toLowerCase().split(".")) {
            if (current == null) return null;
            var found = false;
            for (field in Reflect.fields(current)) {
                if (field.toLowerCase() == part) {
                    current = Reflect.field(current, field);
                    found = true;
                    break;
                }
            }
            if (!found) return null;
        }

        return current;
    }
}