// https://github.com/UnityLabs/procedural-stochastic-texturing/blob/master/Editor/ProceduralTexture2D/SampleProceduralTexture2DNode.cs
// Unity 2019.1. needs a float version


// https://www.shadertoy.com/view/4djSRW
float2 hash22(float2 p) {
    float3 p3 = frac(float3(p.xyx) * float3(.1031, .1030, .0973));
    p3 += dot(p3, p3.yzx+33.33);
    return frac((p3.xx+p3.yz)*p3.zy);

}

void StochasticSample_half(

    SamplerState samplerTex,  // We have to use trilinear/repeat on all textures
    SamplerState samplerLUT,

//  Base inputs
    half Blend,
    float2 uv,

//  Albedo
    Texture2D textureAlbedo,
    Texture2D LUT,
    float3 InputSize,
    half4 CompressionScalars_Albedo,
//  sRGB Color Inputs
    half3 ColorSpaceOrigin_Albedo,
    half3 ColorSpaceVector1_Albedo,
    half3 ColorSpaceVector2_Albedo,
    half3 ColorSpaceVector3_Albedo,
    
//  Normal
    Texture2D textureNormal,
    Texture2D LUTNormal,
    float3 InputSize_Normal,
    float4 CompressionScalars_Normal,

//  MaskMap – might be Specular/Smoothness or Metallic Smoothness
    Texture2D textureMask,
    Texture2D LUTMask,
    float3 InputSize_Mask,
    half4 CompressionScalars_Mask,

    bool MaskUsesSRGB,
//  sRGB Color Inputs
    half3 ColorSpaceOrigin_Mask,
    half3 ColorSpaceVector1_Mask,
    half3 ColorSpaceVector2_Mask,
    half3 ColorSpaceVector3_Mask,


//  Output
    out half3 FinalAlbedo,
    out half FinalAlpha,
    out half3 FinalNormal,
    out half4 FinalMask
)
{
    
    float2 uvScaled = uv * 3.464; // 2 * sqrt(3)
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

//  Get weights
    half exponent = 1.0h + Blend * 15.0h;
    w1 = pow(w1, exponent);
    w2 = pow(w2, exponent);
    w3 = pow(w3, exponent);
//  As all pows use the same exponent we can help the compiler:
//  Why does this introduce artifacts?
    //exponent = log(exponent);
    //w1 = exp(w1 * exponent);
    //w2 = exp(w2 * exponent);
    //w3 = exp(w3 * exponent);

//  Lets help the compiler here:
    half sum = 1.0h / (w1 + w2 + w3);
    w1 = w1 * sum;
    w2 = w2 * sum;
    w3 = w3 * sum;

    half wrsrqt = rsqrt(w1 * w1 + w2 * w2 + w3 * w3);
    
//  Albedo – Sample Gaussion values from transformed input
    half4 G1 = SAMPLE_TEXTURE2D_GRAD(textureAlbedo, samplerTex, uv1, duvdx, duvdy);
    half4 G2 = SAMPLE_TEXTURE2D_GRAD(textureAlbedo, samplerTex, uv2, duvdx, duvdy);
    half4 G3 = SAMPLE_TEXTURE2D_GRAD(textureAlbedo, samplerTex, uv3, duvdx, duvdy);
    half4 G = w1 * G1 + w2 * G2 + w3 * G3;

    G = G - 0.5h;
    G = G * wrsrqt; //rsqrt(w1 * w1 + w2 * w2 + w3 * w3);
    G = G * CompressionScalars_Albedo;
    G = G + 0.5h;
    

//  Normal – Sample Gaussion values from transformed input
    half4 N1 = SAMPLE_TEXTURE2D_GRAD(textureNormal, samplerTex, uv1, duvdx, duvdy);
    half4 N2 = SAMPLE_TEXTURE2D_GRAD(textureNormal, samplerTex, uv2, duvdx, duvdy);
    half4 N3 = SAMPLE_TEXTURE2D_GRAD(textureNormal, samplerTex, uv3, duvdx, duvdy);
    half4 N = w1 * N1 + w2 * N2 + w3 * N3;
    N = N - 0.5h;
    N = N * wrsrqt; //rsqrt(w1 * w1 + w2 * w2 + w3 * w3);
    N = N * CompressionScalars_Normal;
    N = N + 0.5h;

//  Mask – Sample Gaussion values from transformed input
    half4 M1 = SAMPLE_TEXTURE2D_GRAD(textureMask, samplerTex, uv1, duvdx, duvdy);
    half4 M2 = SAMPLE_TEXTURE2D_GRAD(textureMask, samplerTex, uv2, duvdx, duvdy);
    half4 M3 = SAMPLE_TEXTURE2D_GRAD(textureMask, samplerTex, uv3, duvdx, duvdy);
    half4 M = w1 * M1 + w2 * M2 + w3 * M3;
    M = M - 0.5h;
    M = M * wrsrqt; //rsqrt(w1 * w1 + w2 * w2 + w3 * w3);
    M = M * CompressionScalars_Normal;
    M = M + 0.5h;

//  TODO: Check if we need to use scalars if normal or mask have different sizes compared to albedo.
//  I think it looks totally fine without using scalars.
    duvdx *= InputSize.xy;
    duvdy *= InputSize.xy;
    float delta_max_sqr = max(dot(duvdx, duvdx), dot(duvdy, duvdy));
    float mml = 0.5 * log2(delta_max_sqr);
    float LOD = max(0, mml) * InputSize.z; // was: max(0, mml) / InputSize.z; // but we feed in: (1.0 / InputSize.z)

//  Albedo – Fetch LUT
    half4 color;
    color.r = SAMPLE_TEXTURE2D_LOD(LUT, samplerLUT, float2(G.r, LOD), 0).r;
    color.g = SAMPLE_TEXTURE2D_LOD(LUT, samplerLUT, float2(G.g, LOD), 0).g;  
    color.b = SAMPLE_TEXTURE2D_LOD(LUT, samplerLUT, float2(G.b, LOD), 0).b;  
    color.a = SAMPLE_TEXTURE2D_LOD(LUT, samplerLUT, float2(G.a, LOD), 0).a;    

//  Needed by sRGB color textures
    FinalAlbedo = ColorSpaceOrigin_Albedo + ColorSpaceVector1_Albedo * color.r + ColorSpaceVector2_Albedo * color.g + ColorSpaceVector3_Albedo * color.b;
    FinalAlpha = color.a;

//  Normal – Fetch LUT
    half4 normal;
    normal.r = SAMPLE_TEXTURE2D_LOD(LUTNormal, samplerLUT, float2(N.r, LOD), 0).r;
    normal.g = SAMPLE_TEXTURE2D_LOD(LUTNormal, samplerLUT, float2(N.g, LOD), 0).g;  
    normal.b = SAMPLE_TEXTURE2D_LOD(LUTNormal, samplerLUT, float2(N.b, LOD), 0).b;
    normal.a = SAMPLE_TEXTURE2D_LOD(LUTNormal, samplerLUT, float2(N.a, LOD), 0).a; 
//  Normal is either BC5 or DXT5nm – what is about mobile?
    #if defined(UNITY_NO_DXT5nm)
        FinalNormal = UnpackNormalRGBNoScale(normal);
    #else
        FinalNormal = UnpackNormalmapRGorAG(normal);
    #endif

//  Mask – Fetch LUT
    half4 mask;
    mask.r = SAMPLE_TEXTURE2D_LOD(LUTMask, samplerLUT, float2(M.r, LOD), 0).r;
    mask.g = SAMPLE_TEXTURE2D_LOD(LUTMask, samplerLUT, float2(M.g, LOD), 0).g;  
    mask.b = SAMPLE_TEXTURE2D_LOD(LUTMask, samplerLUT, float2(M.b, LOD), 0).b;
    mask.a = SAMPLE_TEXTURE2D_LOD(LUTMask, samplerLUT, float2(M.a, LOD), 0).a;
//  Handle sRGB
    if(MaskUsesSRGB) {
        FinalMask.rgb = ColorSpaceOrigin_Mask + ColorSpaceVector1_Mask * mask.r + ColorSpaceVector2_Mask * mask.g + ColorSpaceVector3_Mask * mask.b;
        FinalMask.a = mask.a;
    }
    else {
        FinalMask = mask;
    }
}

void StochasticSample_float(

    SamplerState samplerTex,  // We have to use trilinear/repeat on all textures
    SamplerState samplerLUT,

//  Base inputs
    half Blend,
    float2 uv,

//  Albedo
    Texture2D textureAlbedo,
    Texture2D LUT,
    float3 InputSize,
    half4 CompressionScalars_Albedo,
//  sRGB Color Inputs
    half3 ColorSpaceOrigin_Albedo,
    half3 ColorSpaceVector1_Albedo,
    half3 ColorSpaceVector2_Albedo,
    half3 ColorSpaceVector3_Albedo,
    
//  Normal
    Texture2D textureNormal,
    Texture2D LUTNormal,
    float3 InputSize_Normal,
    float4 CompressionScalars_Normal,

//  MaskMap – might be Specular/Smoothness or Metallic Smoothness
    Texture2D textureMask,
    Texture2D LUTMask,
    float3 InputSize_Mask,
    half4 CompressionScalars_Mask,

    bool MaskUsesSRGB,
//  sRGB Color Inputs
    half3 ColorSpaceOrigin_Mask,
    half3 ColorSpaceVector1_Mask,
    half3 ColorSpaceVector2_Mask,
    half3 ColorSpaceVector3_Mask,


//  Output
    out half3 FinalAlbedo,
    out half FinalAlpha,
    out half3 FinalNormal,
    out half4 FinalMask
)
{
    StochasticSample_half (
        samplerTex, samplerLUT, Blend, uv,
        textureAlbedo, LUT, InputSize, CompressionScalars_Albedo, ColorSpaceOrigin_Albedo, ColorSpaceVector1_Albedo, ColorSpaceVector2_Albedo, ColorSpaceVector3_Albedo,
        textureNormal, LUTNormal, InputSize_Normal, CompressionScalars_Normal,
        textureMask, LUTMask, InputSize_Mask, CompressionScalars_Mask, MaskUsesSRGB, ColorSpaceOrigin_Mask, ColorSpaceVector1_Mask, ColorSpaceVector2_Mask, ColorSpaceVector3_Mask,
        FinalAlbedo, FinalAlpha, FinalNormal, FinalMask
    );
}