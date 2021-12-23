void AdvancedParallax_float(
//  Base inputs
    Texture2D textureHeight,
    float2 uv,
    float Parallax,

//	Fixed inputs
	SamplerState samplerTex,
	float3 viewDirTS,

//  Outputs
    out float2 ParallaxUV,
    out float Height
) {

    //  Parallax
    float3 v = viewDirTS;
    v.z += 0.42;
    v.xy /= v.z;
    float halfParallax = Parallax * 0.5f;
    float parallax = SAMPLE_TEXTURE2D(textureHeight, samplerTex, uv).g * Parallax - halfParallax;
    Height = parallax;
    float2 offset1 = parallax * v.xy;
//  Calculate 2nd height
    parallax = SAMPLE_TEXTURE2D(textureHeight, samplerTex, uv + offset1).g * Parallax - halfParallax;
    Height += parallax;
    float2 offset2 = parallax * v.xy;
//  Final UVs
    uv += (offset1 + offset2) * 0.5f;

    ParallaxUV = uv;
}