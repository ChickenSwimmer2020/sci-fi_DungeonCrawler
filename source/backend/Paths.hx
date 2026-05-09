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

    #if(windows||hl)public static inline function save(f:String):String return 'assets/saves/$f.sf';#end

    public static inline function data(path:String):Dynamic {return null;};
    public static inline function getPath(f:String, o:String, ex:String):String return 'assets/$f/$o.$ex';

    public static inline function sfx(t:String):String return 'assets/audio/sfx/$t.${#if(html5)'mp3'#else'ogg'#end}';
    public static inline function font(t:String):String return 'assets/fonts/$t';
    public static inline function getXml(path:String):String#if(html5)return Assets.getText(path);#else return File.getContent(path);#end
    public static inline function lang(l:String):String return 'assets/lang/${l.toUpperCase()}.lang';
    public static inline function tiles(i:String)#if(html5):BitmapData#else:String#end return Paths.image('tiles', i);
    public static inline function exists(p:String, o:String, ex:String):Bool return #if(html5)Assets.exists('$p/$o.$ex');#else FileSystem.exists('$p/$o.$ex');#end
    public static inline function weapon(w:String):String #if(html5)return 'assets/items/weapons/$w.weapon';#else return 'assets/items/weapons/$w.weapon';#end
    public static inline function weaponExists(w:String):Bool #if(html5)return Assets.exists('assets/items/weapons/$w.weapon');#else return FileSystem.exists('assets/items/weapons/$w.weapon');#end

    public static inline function image(folder:String,i:String)#if(html5):BitmapData#else:String#end{
        if(FlxG.bitmap.get('assets/$folder/$i.png')!=null) FlxG.bitmap.add('assets/$folder/$i.png', true, 'assets/$folder/$i.png');
        #if (html5) return Assets.getBitmapData('assets/$folder/$i.png');
        #else return 'assets/$folder/$i.png';#end
    }
    #if (debug)
        public static inline function DEBUG(i:String,?ext:String="png")#if(html5):BitmapData#else:String#end return Paths.image('debug', i);
    #end
}