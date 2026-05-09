package backend.shaders;

class Invert extends FlxAssets.FlxShader {
    @:glFragmentSource('
        #pragma header

        void main() {
            vec2 uv = openfl_TextureCoordv.xy;
            vec4 col = texture2D(bitmap, uv);

            vec4 colr = vec4(vec3(1.0-col.r, 1.0-col.g, 1.0-col.b), col.a);
            gl_FragColor=colr;
        }
    ')
    public function new(){
        super();
    }
}