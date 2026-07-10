package backend.shaders;

class Distort extends FlxRuntimeShader {
    public function new(dis:Float = 0.0){
        super('
#pragma header
uniform float strength; // e.g. 0.2

void main() {
    vec2 uv = openfl_TextureCoordv.xy;
    vec2 center = vec2(0.5);
    vec2 offset = uv - center;
    float dist = length(offset);

    float factor = 1.0 - strength * pow(dist, 2.0);

    vec2 warpedUV = clamp(center + offset * factor, 0.0, 1.0);
    vec4 color = texture2D(bitmap, warpedUV);
    
    if((warpedUV.x > 0.9 || warpedUV.x < 0.1) || (warpedUV.y > 0.9 || warpedUV.y < 0.1)){
        gl_FragColor = vec4(1.0, 0.0, 1.0, 1.0);
        return;
    }

    gl_FragColor = color;
}', "");

        setFloat("strength", dis);
    }
}



