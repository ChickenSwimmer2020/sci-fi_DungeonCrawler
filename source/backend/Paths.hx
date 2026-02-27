package backend;

class Paths {
    public static final savePath:String="assets/saves";
    public static final mapsPath:String="assets/maps";
    public static final tilesPath:String="assets/tiles";
    public static final langPath:String="assets/lang";
    public static final itemPath:String="assets/items";
    public static final weaponsPath:String="assets/items/weapons";
    #if debug public static final debugPath:String="assets/debug"; #end

    public static inline function weaponExists(w:String):Bool return FileSystem.exists(Paths.weapon(w));

    public static inline function tiles(image:String):String{
        return Paths.image('tiles', image);
    }
    public static inline function lang(l:String):String return '${langPath}/$l.lang';
    public static inline function image(folder:String,i:String):String{
        #if debug @:privateAccess FlxG.debugger.windows.get_debugger().bitmapLog.add(BitmapData.fromFile('assets/$folder/$i.png')); #end
        return 'assets/$folder/$i.png';
    }
    public static inline function weapon(w:String):String return '${weaponsPath}/$w.weapon';
    public static inline function map(m:String):String return '$mapsPath/$m.map';

    #if debug public static inline function DEBUG(i:String,?ext:String="png"):String return Paths.image('debug', i); #end
}