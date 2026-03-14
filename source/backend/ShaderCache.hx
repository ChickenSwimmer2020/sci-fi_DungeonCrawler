package backend;

class ShaderCache {
    private static var mask:MaskShader;
    private static var rail:RailFire;


    public static function preload() {
        mask = new MaskShader(null); 
        rail = new RailFire();

        Functions.wait(0.5, (_)->{
            mask=null;
            rail=null;
        });
    }
}