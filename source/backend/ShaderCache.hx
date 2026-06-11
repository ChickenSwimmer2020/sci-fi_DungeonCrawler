package backend;

import backend.shaders.Invert;

class ShaderCache extends FlxState{
    var sprites:Array<FlxSprite>=[];
    public function new() {
        super();

        for(i in 0...4) {
            var testSprite:FlxSprite = new FlxSprite(0+(20*i)+5, (i%12+(20*i))).makeGraphic(20, 20, 0xFFFF00FF);
            add(testSprite);
            sprites.push(testSprite);
            testSprite.shader = [ //love that i have to do it like this.
                new Invert(),
                new RailFire(),
                new ScreenShake(),
                new ScreenShake() //static
            ][i];
            for(value in ['intensity', 'speed']) {
                if(Reflect.getProperty(testSprite.shader.data, value)!=null) {
                    Reflect.setProperty(testSprite.shader.data, value, 12.0);
                }
            }
            if(i==4) testSprite.shader.data.staticMode = true;
        }
    }
    var shaderTime:Float=0.0;
    override public function update(elapsed:Float) {
        super.update(elapsed);
        shaderTime+=elapsed;
        for(sprite in sprites) {
            sprite.shader.data.iTime += shaderTime;
        }
    }
}