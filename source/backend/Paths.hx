package backend;

import flixel.util.typeLimit.OneOfThree;

class Paths {
    //public static final paths:Map<String,String>=[
    //    "tiles"=>"assets/tiles",
    //    "lang"=>"assets/lang",
    //    "item"=>"assets/items",
    //    "weapon"=>"assets/items/weapons",
    //    "music"=>"assets/audio/music",
    //    "sfx"=>"assets/audio/sfx",
    //    "cutscene"=>"assets/cutscenes",
    //    #if(debug)"debug"=>"assets/debug"#end
    //];

    public static inline function save(f:String):String return 'assets/saves/$f.sf';

    public static inline function data(path:String):Dynamic {return null;};
    public static inline function getPath(f:String, o:String, ex:String):String return 'assets/$f/$o.$ex';

    public static inline function sfx(t:String):String return 'assets/audio/sfx/$t.${'ogg'}';
    public static inline function font(t:String):String return 'assets/fonts/$t';
    public static inline function getXml(path:String):String return File.getContent(path);
    public static inline function lang(l:String):String return 'assets/lang/${l.toUpperCase()}.lang';
    public static inline function tiles(i:String):String return Paths.image('tiles', i);
    public static inline function exists(p:String, o:String, ex:String):Bool return FileSystem.exists('$p/$o.$ex');
    public static inline function weapon(w:String):String return 'assets/items/weapons/$w.weapon';
    public static inline function weaponExists(w:String):Bool return FileSystem.exists('assets/items/weapons/$w.weapon');

    public static inline function image(folder:String,i:String):String{
        if(FlxG.bitmap.get('assets/$folder/$i.png')!=null) FlxG.bitmap.add('assets/$folder/$i.png', true, 'assets/$folder/$i.png');
        return 'assets/$folder/$i.png';
    }
    #if (debug)
        public static inline function DEBUG(i:String,?ext:String="png"):String return Paths.image('debug', i);
    #end
}