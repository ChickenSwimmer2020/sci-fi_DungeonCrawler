package backend.shaders;

import flixel.addons.display.FlxRuntimeShader;

class RailFire extends FlxRuntimeShader {
    public function new(ibnt:Float = 0.0, spd:Float = 0.0){
        super('
#pragma header

uniform float intensity;
uniform float speed;
uniform float iTime;

void main() {
    vec2 uv = openfl_TextureCoordv.xy;
    vec4 ogColor = texture2D(bitmap, uv);
    vec4 secondColor = texture2D(bitmap, uv);


    secondColor.rgb = texture2D(bitmap, vec2(uv.x + sin(iTime*speed)*intensity, uv.y)).rgb;


    gl_FragColor = mix(ogColor, secondColor, 0.5);
}', "");

        setFloat("intensity", ibnt);
        setFloat("speed", spd);
        setFloat("iTime", 0.0);
    }
}