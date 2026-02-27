package backend.shaders;

import flixel.system.FlxAssets;

class RailFire extends FlxAssets.FlxShader {
    @:glFragmentSource('
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
        }
    ')
    public function new(){
        super();
        intensity.value=[0.0];
        speed.value=[0.0];
        iTime.value=[0.0];
    }
}