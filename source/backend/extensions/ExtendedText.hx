package backend.extensions;

class ExtendedText extends FlxText {
    public static var globalFont(default, set):String = FlxAssets.FONT_DEFAULT;
    public var overrideFont:String = "";
    public static var instances:Array<ExtendedText> = [];

    public static function set_globalFont(s:String):String {
        globalFont = s;
        for(instance in instances) instance.updateFontRender();
        return s;
    }
    public function new(x:Float = 0, y:Float = 0, w:Float = 0, ?t:String, s:Int = 12, ef:Bool = true) {
        super(x, y, w, t, s, ef);

        instances.push(this);
    }

    override public function destroy() {
        instances.remove(this);
        super.destroy();
    }

    public function updateFontRender() {
        font = overrideFont==""?globalFont:overrideFont; //if the font is set manually, its going to override the global font status.
        regenGraphic(); //handy.
    }
}