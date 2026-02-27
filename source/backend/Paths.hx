package backend;

class Paths {
    public static final savePath:String = "assets/saves";
    public static final mapsPath:String = "assets/maps";
    public static final tilesPath:String = "assets/tiles";
    public static function tiles(image:String):String return '${tilesPath}/$image.png';
}