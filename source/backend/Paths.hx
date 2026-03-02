package backend;

class Paths {
    public static final mapsPath:String="assets/maps";
    public static final tilesPath:String="assets/tiles";
    public static final langPath:String="assets/lang";
    public static final itemPath:String="assets/items";
    public static final weaponsPath:String="assets/items/weapons";
    #if (debug && !android) public static final debugPath:String="assets/debug"; #end

    public static inline function weaponExists(w:String):Bool{
        #if (android || html5)
            return Assets.getText(Paths.weapon(w))!=null;
        #else
            return FileSystem.exists(Paths.weapon(w));
        #end
    }

    public static inline function tiles(image:String)#if (android||html5) :BitmapData#else:String#end{
        return Paths.image('tiles', image);
    }
    public static inline function lang(l:String):String return '${langPath}/$l.lang';
    public static inline function image(folder:String,i:String)#if (android||html5) :BitmapData#else:String#end{
        //TODO: fix the bitmap logger crashing stuff.
        //#if (debug && !android) @:privateAccess FlxG.debugger.windows.get_debugger().bitmapLog.add(BitmapData.fromFile('assets/$folder/$i.png')); #end
        #if (android || html5)
            return Assets.getBitmapData('assets/$folder/$i.png');
        #else
            return 'assets/$folder/$i.png';
        #end
    }
    public static inline function weapon(w:String):String return '${weaponsPath}/$w.weapon'; 
    public static inline function map(m:String):String return '$mapsPath/$m.map';

    #if (debug && !android)
        public static inline function DEBUG(i:String,?ext:String="png")#if(html5):BitmapData#else:String#end
            return Paths.image('debug', i);
    #end
}