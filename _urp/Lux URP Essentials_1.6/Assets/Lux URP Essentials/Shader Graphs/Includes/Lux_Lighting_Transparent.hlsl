#if !defined(SHADERGRAPH_PREVIEW) || defined(LIGHTWEIGHT_LIGHTING_INCLUDED)

//  As we do not have access to the vertex lights we will make the shader always sample add lights per pixel
    #if defined(_ADDITIONAL_LIGHTS_VERTEX)
        #undef _ADDITIONAL_LIGHTS_VERTEX
        #define _ADDITIONAL_LIGHTS
    #endif
#endif


void Lighting_half(

//  Base inputs
    float3 positionWS,
    half3 viewDirectionWS,

//  Normal inputs    
    half3 normalWS,
    half3 tangentWS,
    half3 bitangentWS,
    bool enableNormalMapping,
    half3 normalTS,

//  Surface description
    half3 albedo,
    half metallic,
    half3 specular,
    half smoothness,
    half occlusion,
    half alpha,

//  Lightmapping
    float2 lightMapUV,

//  Final lit color
    out half3 MetaAlbedo,
    out half3 FinalLighting,
    out half3 MetaSpecular
)
{

//#ifdef SHADERGRAPH_PREVIEW
#if defined(SHADERGRAPH_PREVIEW) || ( !defined(LIGHTWEIGHT_LIGHTING_INCLUDED) && !defined(UNIVERSAL_LIGHTING_INCLUDED) )
    FinalLighting = albedo;
    MetaAlbedo = half3(0,0,0);
    MetaSpecular = half3(0,0,0);
#else

//  This fixes the fog issue
    #if defined (_ALPHAPREMULTIPLY_ON)
        unity_FogColor *= alpha;
    //  Two Materials Setup: We would have to tweak alpha according to fog intensity? which we do not have.
    #endif


//  Real Lighting ----------

    if (enableNormalMapping) {
        normalWS = TransformTangentToWorld(normalTS, half3x3(tangentWS.xyz, bitangentWS.xyz, normalWS.xyz));
    }
    normalWS = NormalizeNormalPerPixel(normalWS);
    viewDirectionWS = SafeNormalize(viewDirectionWS);

//  GI Lighting
    half3 bakedGI;
    #ifdef LIGHTMAP_ON
        lightMapUV = lightMapUV * unity_LightmapST.xy + unity_LightmapST.zw;
        bakedGI = SAMPLE_GI(lightMapUV, half3(0,0,0), normalWS);
    #else
        bakedGI = SampleSH(normalWS); 
    #endif

    BRDFData brdfData;
    InitializeBRDFData(albedo, metallic, specular, smoothness, alpha, brdfData);

    float4 clipPos = TransformWorldToHClip(positionWS);

//  Get Shadow Sampling Coords / Unfortunately per pixel...
    #if SHADOWS_SCREEN
        float4 shadowCoord = ComputeScreenPos(clipPos);
    #else
        float4 shadowCoord = TransformWorldToShadowCoord(positionWS);
    #endif

//  Shadow mask 
    #if defined(SHADOWS_SHADOWMASK) && defined(LIGHTMAP_ON)
        half4 shadowMask = SAMPLE_SHADOWMASK(lightMapUV);
    #elif !defined (LIGHTMAP_ON)
        half4 shadowMask = unity_ProbesOcclusion;
    #else
        half4 shadowMask = half4(1, 1, 1, 1);
    #endif

    //Light mainLight = GetMainLight(shadowCoord);
    Light mainLight = GetMainLight(shadowCoord, positionWS, shadowMask);

//  SSAO - no ssao here as it does not write into the depth/depthnormal buffer
        
    FinalLighting = GlobalIllumination(brdfData, bakedGI, occlusion, normalWS, viewDirectionWS);
    MixRealtimeAndBakedGI(mainLight, normalWS, bakedGI, half4(0, 0, 0, 0));

//  GetMainLight will return screen space shadows.
    #if defined(_MAIN_LIGHT_SHADOWS)
        float4 shadowCoordWS = TransformWorldToShadowCoord(positionWS);
        ShadowSamplingData shadowSamplingData = GetMainLightShadowSamplingData();
        half shadowStrength = GetMainLightShadowStrength();
        mainLight.shadowAttenuation = SampleShadowmap(shadowCoordWS, TEXTURE2D_ARGS(_MainLightShadowmapTexture, sampler_MainLightShadowmapTexture), shadowSamplingData, shadowStrength, false);
    #endif


//  Main Light
    FinalLighting += LightingPhysicallyBased(brdfData, mainLight, normalWS, viewDirectionWS);

//  Handle additional lights
    #ifdef _ADDITIONAL_LIGHTS
        int pixelLightCount = GetAdditionalLightsCount();
        for (int i = 0; i < pixelLightCount; ++i) {
            // Light light = GetAdditionalPerObjectLight(index, positionWS); // here; shadowAttenuation = 1.0;
        //  URP 10: We have to use the new GetAdditionalLight function
            Light light = GetAdditionalLight(i, positionWS, shadowMask);
            FinalLighting += LightingPhysicallyBased(brdfData, light, normalWS, viewDirectionWS);
        }
    #endif

//  Set Albedo for meta pass
    #if defined(LIGHTWEIGHT_META_PASS_INCLUDED) || defined(UNIVERSAL_META_PASS_INCLUDED)
        FinalLighting = half3(0,0,0);
        MetaAlbedo = albedo;
        MetaSpecular = specular;
    #else
        MetaAlbedo = half3(0,0,0);
        MetaSpecular = half3(0,0,0);
    #endif

//  End Real Lighting ----------

#endif
}

// Unity 2019.1. needs a float version

void Lighting_float(

//  Base inputs
    float3 positionWS,
    half3 viewDirectionWS,

//  Normal inputs    
    half3 normalWS,
    half3 tangentWS,
    half3 bitangentWS,
    bool enableNormalMapping,
    half3 normalTS,

//  Surface description
    half3 albedo,
    half metallic,
    half3 specular,
    half smoothness,
    half occlusion,
    half alpha,

//  Lightmapping
    float2 lightMapUV,

//  Final lit color
    out half3 MetaAlbedo,
    out half3 FinalLighting,
    out half3 MetaSpecular
)
{
    Lighting_half(
        positionWS, viewDirectionWS, normalWS, tangentWS, bitangentWS, enableNormalMapping, normalTS, 
        albedo, metallic, specular, smoothness, occlusion, alpha,
        lightMapUV, MetaAlbedo, FinalLighting, MetaSpecular);
}