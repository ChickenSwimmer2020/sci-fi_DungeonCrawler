package backend;

import flixel.addons.display.FlxRuntimeShader;
import openfl.display.ShaderParameter;
import backend.shaders.Invert;

class ShaderCache extends FlxState{
    var sprites:Array<FlxSprite>=[];
    var shaders:Array<OneOfTwo<FlxRuntimeShader, flixel.system.FlxAssets.FlxShader>> = [];


    final shaderProps:Array<Array<Dynamic>> = [
        ["useless."],                   //invert
        [0.25, 60.0],                   //railfire
        [0.25, 60.0, false],            //screenshake
        [0.75, 120.0, true]              //static
    ];
    public function new() {
        super();

        add(new FlxText(((FlxG.width/2)-(200)), 0, 400, "Preloading shaders, please wait.", 24, true));

        for(i in 0...4) {
            var testSprite:FlxSprite = new FlxSprite(0+(37*i), ((i%(FlxG.width/(25)))+(20*i))).loadGraphic(Paths.image('items/images', "DEBUGCONSUMABLE"));
            add(testSprite);
            sprites.push(testSprite);
            shaders.push([ //love that i have to do it like this.
                new Invert(),
                new RailFire(shaderProps[1][0], shaderProps[1][1]),
                new ScreenShake(shaderProps[2][0], shaderProps[2][1], shaderProps[2][2]),
                new ScreenShake(shaderProps[3][0], shaderProps[3][1], shaderProps[3][2]) //static
            ][i]);
            testSprite.shader = shaders[i];
        }

        //TODO: solar, please put the bar that automatically fills as shaders compile and shows a like, percentage of all the shaders compiled,
        //TODO: that then automatically moves to IntroState afterwards, thank you.

        Functions.wait(10, (_)->{
            FlxG.switchState(()->new IntroState());
        });
    }
    var shaderTime:Float=0.0;
    override public function update(elapsed:Float) {
        super.update(elapsed);
        shaderTime+=elapsed;

        for(shader in shaders) {
            if(Std.isOfType(shader, FlxRuntimeShader)) { //ignore FlxShader, because the only one that uses it DOESNT have iTime
                var shad:FlxRuntimeShader = cast(shader);
                shad.setFloat("iTime", shaderTime);
                trace(shaderTime);
            }
        }
    }
}