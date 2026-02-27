package backend.shaders;

import flixel.system.FlxAssets;

class MaskShader extends FlxAssets.FlxShader {
    @:glFragmentSource('
        #pragma header
        uniform float vAlpha;
        uniform float maskValue; // 0-100 input
        uniform sampler2D msk;
        void main() { // Normalize movement: 0-100 → 0.0-1.0 UV shift
            float shift = maskValue / 100.0; // Background UV (moves)
            vec2 bgUV = openfl_TextureCoordv.xy;
            bgUV.y += shift; // Sample background using shifted UV
            vec4 bg = texture2D(bitmap, bgUV); // Sample mask normally (mask does NOT move)
            float mask = texture2D(msk, openfl_TextureCoordv.xy).a; // If mask or background alpha is zero, output transparent
            if (bg.a == 0.0 || mask == 0.0) {discard;} // Un-premultiply background RGB
            vec3 rgb = bg.rgb / bg.a; // Apply mask + alpha
            gl_FragColor = vec4(rgb, bg.a * mask * vAlpha);
        }
    ')
    public function new(maskImage:BitmapData, ?alpha:Float=1.0) {
        super();
        //TODO: fix
        maskValue.value=[0];
        msk.input = maskImage;
        vAlpha.value = [alpha];
    }
}