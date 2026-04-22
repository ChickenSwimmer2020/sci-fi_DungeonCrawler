package backend.shaders;

class ScreenShake extends FlxAssets.FlxShader {
    @:glFragmentSource('
        #pragma header

        uniform float intensity;
        uniform float speed;
        uniform float iTime;

        uniform bool staticMode;

        float random(vec2 st, float evolve) {
            float e = fract((evolve*0.01));
            
            // Coordinates
            float cx  = st.x*e;
            float cy  = st.y*e;
            
            // Generate a "random" black or white value
            return fract(23.0*fract(2.0/fract(fract(cx*2.4/cy*23.0)*fract(cx*evolve/pow(abs(cy),0.050)))));
        }

        void main() {
            vec2 uv = openfl_TextureCoordv.xy;
            vec4 ogColor = texture2D(bitmap, uv);
            float randX=0.0;
            float randY=0.0;

            if(staticMode){
                randX = random(uv + vec2(iTime * speed, 0.0), iTime) * 2.0 - 1.0;
                randY = random(uv + vec2(0.0, iTime * speed), iTime) * 2.0 - 1.0;
            }else{
                randX = sin(iTime * speed * 1.3 + 1.7) * cos(iTime * speed * 2.3 + 3.1) * sin(iTime * speed * 0.4 + 7.2);
                randY = cos(iTime * speed * 0.9 + 5.3) * sin(iTime * speed * 1.7 + 2.4) * cos(iTime * speed * 3.1 + 4.6);
            }



            vec4 secondColor = texture2D(bitmap, vec2(uv.x + randX * intensity, uv.y + randY * intensity));

            gl_FragColor = mix(ogColor, secondColor, 0.5);
        }
    ')
    public function new(){
        super();
        intensity.value=[0.0];
        speed.value=[0.0];
        iTime.value=[0.0];
        staticMode.value=[false];
    }
}