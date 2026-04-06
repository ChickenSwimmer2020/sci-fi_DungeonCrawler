package backend.shaders;

class ScreenShake extends FlxAssets.FlxShader {
    @:glFragmentSource('
        #pragma header

        uniform float intensity;
        uniform float speed;
        uniform float iTime;

        void main() {
            vec2 uv = openfl_TextureCoordv.xy;
            vec4 ogColor = texture2D(bitmap, uv);

            // pseudo-random offsets using different frequencies so movement feels random
            float randX = sin(iTime * speed * 1.3 + 1.7) * cos(iTime * speed * 0.7 + 3.1);
            float randY = sin(iTime * speed * 0.9 + 5.3) * cos(iTime * speed * 1.1 + 2.4);

            vec4 secondColor = texture2D(bitmap, vec2(uv.x + randX * intensity, uv.y + randY * intensity));

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