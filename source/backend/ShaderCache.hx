package backend;

import lime.app.Application;
import flixel.util.FlxTimer;
import backend.shaders.RailFire;
import backend.shaders.MaskShader;

class ShaderCache {
    private static var mask:MaskShader;
    private static var rail:RailFire;


    public static function preload() {
        mask = new MaskShader(null); 
        rail = new RailFire();

        new FlxTimer().start(0.5, (_)->{
            mask=null;
            rail=null;
        });
    }
}