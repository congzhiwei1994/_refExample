// https://github.com/UnityLabs/procedural-stochastic-texturing/blob/master/Editor/ProceduralTexture2D/SampleProceduralTexture2DNode.cs
// Unity 2019.1. needs a float version


// https://www.shadertoy.com/view/4djSRW
float2 hash22(float2 p) {
    float3 p3 = frac(float3(p.xyx) * float3(.1031, .1030, .0973));
    p3 += dot(p3, p3.yzx+33.33);
    return frac((p3.xx+p3.yz)*p3.zy);
}

void StochasticSampleSimple_half (
    SamplerState samplerTex,
//  Base inputs
    half Blend,
    float2 uv,
    float stochasticScale,
//  Albedo
    Texture2D textureAlbedo,
//  Normal
    Texture2D textureNormal,
    half normalScale,
//  MetallicSpecular
    Texture2D textureMetallicSpec,
//  MaskMap
    Texture2D textureMask,

//  Output
    out half3 FinalAlbedo,
    out half FinalAlpha,
    out half3 FinalNormal,
    out half4 FinalMetallicSpecular,
    out half4 FinalMask
)
{
    
    float2 uvScaled = uv * 3.464 * stochasticScale; // 2 * sqrt(3)
    const float2x2 gridToSkewedGrid = float2x2(1.0, 0.0, -0.57735027, 1.15470054);
    float2 skewedCoord = mul(gridToSkewedGrid, uvScaled);
    int2 baseId = int2(floor(skewedCoord));
    float3 temp = float3(frac(skewedCoord), 0);
    temp.z = 1.0 - temp.x - temp.y;
    half w1, w2, w3;
    int2 vertex1, vertex2, vertex3;
    if (temp.z > 0.0) {
        w1 = temp.z;
        w2 = temp.y;
        w3 = temp.x;
        vertex1 = baseId;
        vertex2 = baseId + int2(0, 1);
        vertex3 = baseId + int2(1, 0);
    }
    else {
        w1 = -temp.z;
        w2 = 1.0 - temp.y;
        w3 = 1.0 - temp.x;
        vertex1 = baseId + int2(1, 1);
        vertex2 = baseId + int2(1, 0);
        vertex3 = baseId + int2(0, 1);
    }

    const float2x2 hashMatrix = float2x2(127.1, 311.7, 269.5, 183.3);
    const float hashFactor = 3758.5453;
    float2 uv1 = uv + frac(sin(mul(hashMatrix, (float2)vertex1)) * hashFactor);
    float2 uv2 = uv + frac(sin(mul(hashMatrix, (float2)vertex2)) * hashFactor);
    float2 uv3 = uv + frac(sin(mul(hashMatrix, (float2)vertex3)) * hashFactor);

//  Use a hash function which does not include sin
//  Adds a little bit visible tiling...   
    // float2 uv1 = uv + hash22( (float2)vertex1 );
    // float2 uv2 = uv + hash22( (float2)vertex2 );
    // float2 uv3 = uv + hash22( (float2)vertex3 );

    float2 duvdx = ddx(uv);
    float2 duvdy = ddy(uv);

//  Here we have to sample first as we want to calculate the wights based on luminance
//  Albedo – Sample Gaussion values from transformed input
    half4 G1 = SAMPLE_TEXTURE2D_GRAD(textureAlbedo, samplerTex, uv1, duvdx, duvdy);
    half4 G2 = SAMPLE_TEXTURE2D_GRAD(textureAlbedo, samplerTex, uv2, duvdx, duvdy);
    half4 G3 = SAMPLE_TEXTURE2D_GRAD(textureAlbedo, samplerTex, uv3, duvdx, duvdy);

    w1 *= Luminance(G1.rgb);
    w2 *= Luminance(G2.rgb);
    w3 *= Luminance(G3.rgb);
    
//  Get weights
    half exponent = 1.0h + Blend * 15.0h;
    w1 = pow(w1, exponent);
    w2 = pow(w2, exponent);
    w3 = pow(w3, exponent);

//  Lets help the compiler here:
    half sum = 1.0h / (w1 + w2 + w3);
    w1 = w1 * sum;
    w2 = w2 * sum;
    w3 = w3 * sum;
    
//  Albedo
    half4 G = w1 * G1 + w2 * G2 + w3 * G3;
    FinalAlbedo = G.rgb;
    FinalAlpha = G.a;

//  Normal
    half4 N1 = SAMPLE_TEXTURE2D_GRAD(textureNormal, samplerTex, uv1, duvdx, duvdy);
    half4 N2 = SAMPLE_TEXTURE2D_GRAD(textureNormal, samplerTex, uv2, duvdx, duvdy);
    half4 N3 = SAMPLE_TEXTURE2D_GRAD(textureNormal, samplerTex, uv3, duvdx, duvdy);
    half4 N = w1 * N1 + w2 * N2 + w3 * N3;
//  Normal is either BC5 or DXT5nm – what is about mobile?
    #if defined(UNITY_NO_DXT5nm)
        FinalNormal = UnpackNormalRGBNoScale(N);
    #else
        FinalNormal = UnpackNormalmapRGorAG(N, normalScale);
    #endif
//  MetallicSpecular
    half4 MS1 = SAMPLE_TEXTURE2D_GRAD(textureMetallicSpec, samplerTex, uv1, duvdx, duvdy);
    half4 MS2 = SAMPLE_TEXTURE2D_GRAD(textureMetallicSpec, samplerTex, uv2, duvdx, duvdy);
    half4 MS3 = SAMPLE_TEXTURE2D_GRAD(textureMetallicSpec, samplerTex, uv3, duvdx, duvdy);
    FinalMetallicSpecular = w1 * MS1 + w2 * MS2 + w3 * MS3;
//  Mask
    half4 M1 = SAMPLE_TEXTURE2D_GRAD(textureMask, samplerTex, uv1, duvdx, duvdy);
    half4 M2 = SAMPLE_TEXTURE2D_GRAD(textureMask, samplerTex, uv2, duvdx, duvdy);
    half4 M3 = SAMPLE_TEXTURE2D_GRAD(textureMask, samplerTex, uv3, duvdx, duvdy);
    FinalMask = w1 * M1 + w2 * M2 + w3 * M3;
}

void StochasticSampleSimple_float(
    SamplerState samplerTex,
//  Base inputs
    half Blend,
    float2 uv,
    float stochasticScale,
//  Albedo
    Texture2D textureAlbedo,
//  Normal
    Texture2D textureNormal,
    half normalScale,
//  MetallicSpecular
    Texture2D textureMetallicSpec,
//  MaskMap
    Texture2D textureMask,

//  Output
    out half3 FinalAlbedo,
    out half FinalAlpha,
    out half3 FinalNormal,
    out half4 FinalMetallicSpecular,
    out half4 FinalMask
)
{
    StochasticSampleSimple_half (
        samplerTex, Blend, uv, stochasticScale,
        textureAlbedo,
        textureNormal, normalScale,
        textureMetallicSpec,
        textureMask,
        FinalAlbedo, FinalAlpha, FinalNormal, FinalMetallicSpecular, FinalMask
    );
}