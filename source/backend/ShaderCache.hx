package backend;

class ShaderCache {
    private static var rail:RailFire;


    public static function preload() {
        rail = new RailFire();

        Functions.wait(0.5, (_)->{
            rail=null;
        });
    }
}