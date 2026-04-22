package backend;

import flixel.util.typeLimit.OneOfThree;

class Paths {
    public static final paths:Map<String,String>=[
        "tiles"=>"assets/tiles",
        "lang"=>"assets/lang",
        "item"=>"assets/items",
        "weapon"=>"assets/items/weapons",
        "music"=>"assets/audio/music",
        "sfx"=>"assets/audio/sfx",
        "cutscene"=>"assets/cutscenes",
        #if(debug)"debug"=>"assets/debug"#end
    ];

    public static function exists(p:String, o:String, ex:String):Bool {
        var assetToCheckFor:String = '$p/$o.$ex';
        return #if(html5)Assets.exists(assetToCheckFor)?true:false; #else FileSystem.exists(assetToCheckFor);#end
    }

    public static inline function tiles(image:String)#if (html5) :BitmapData#else:String#end{
        return Paths.image('tiles', image);
    }
    public static inline function lang(l:String):String return '${paths.get('lang')}/${l.toUpperCase()}.lang';
    public static inline function image(folder:String,i:String)#if(html5):BitmapData#else:String#end{
        if(FlxG.bitmap.get('assets/$folder/$i.png')!=null) FlxG.bitmap.add('assets/$folder/$i.png', true, 'assets/$folder/$i.png');
        #if (html5) return Assets.getBitmapData('assets/$folder/$i.png');
        #else return 'assets/$folder/$i.png';#end
    }
    public static inline function weapon(w:String):String return '${paths.get('weapon')}/$w.weapon'; 
    #if (debug)
        public static inline function DEBUG(i:String,?ext:String="png")#if(html5):BitmapData#else:String#end return Paths.image('debug', i);
    #end
}