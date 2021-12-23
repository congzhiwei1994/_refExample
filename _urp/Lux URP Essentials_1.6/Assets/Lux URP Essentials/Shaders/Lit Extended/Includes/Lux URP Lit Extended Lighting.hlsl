

real GI_Luminance(real3 linearRgb)
{
    return dot(linearRgb, real3(0.2126729, 0.7151522, 0.0721750));
}

// Horizon Occlusion for Normal Mapped Reflections: http://marmosetco.tumblr.com/post/81245981087
half LuxGetHorizonOcclusion(half3 R, half3 normalWS, half3 vertexNormal, half horizonFade)
{
    //half3 R = reflect(-V, normalWS);
    half specularOcclusion = saturate(1.0 + horizonFade * dot(R, vertexNormal));
    // smooth it
    return specularOcclusion * specularOcclusion;
}
  

half3 LuxExtended_GlobalIllumination(BRDFData brdfData, half3 bakedGI, half occlusion, half3 normalWS, half3 viewDirectionWS,   half GItoAO, half GItoAOBias, half3 bentNormal, half3 geoNormalWS, half horizonOcllusion)
{
    half3 reflectVector = reflect(-viewDirectionWS, normalWS);
    half fresnelTerm = Pow4(1.0 - saturate(dot(normalWS, viewDirectionWS)));
    half3 indirectDiffuse = bakedGI * occlusion;

    half reflOcclusion = 1;
    #if defined(_BENTNORMAL)
        reflOcclusion = saturate(dot(normalWS, bentNormal));
        /*
        occlusion = sqrt(1.0 - saturate(occlusion/reflOcclusion));
        occlusion = TWO_PI *  (1.0 - occlusion);
        occlusion = saturate(occlusion * INV_FOUR_PI);
        reflOcclusion = 1;
        */
    #endif

//  Horizon Occlusion
    #if defined (_SAMPLENORMAL) && defined(_UBER)
        reflOcclusion *= LuxGetHorizonOcclusion( reflectVector, normalWS, geoNormalWS, horizonOcllusion);
    #endif

//  AO from lightmap
    #if defined(LIGHTMAP_ON) && defined(_ENABLE_AO_FROM_GI)
        half specOcclusion = saturate( GI_Luminance(bakedGI) * GItoAO + GItoAOBias);
        half3 indirectSpecular = GlossyEnvironmentReflection(reflectVector, brdfData.perceptualRoughness, reflOcclusion * occlusion   *   specOcclusion  );
    #else
        half3 indirectSpecular = GlossyEnvironmentReflection(reflectVector, brdfData.perceptualRoughness, reflOcclusion * occlusion);
    #endif

    return EnvironmentBRDF(brdfData, indirectDiffuse, indirectSpecular, fresnelTerm);

}



half4 LuxExtended_UniversalFragmentPBR(InputData inputData, half3 albedo, half metallic, half3 specular,
    half smoothness, half occlusion, half3 emission, half alpha,
    half GItoAO, half GItoAOBias, half3 bentNormal, half3 geoNormalWS, half horizonOcllusion
    )
{
    BRDFData brdfData;
    InitializeBRDFData(albedo, metallic, specular, smoothness, alpha, brdfData);

//  ShadowMask: To ensure backward compatibility we have to avoid using shadowMask input, as it is not present in older shaders
    #if defined(SHADOWS_SHADOWMASK) && defined(LIGHTMAP_ON)
        half4 shadowMask = inputData.shadowMask;
    #elif !defined (LIGHTMAP_ON)
        half4 shadowMask = unity_ProbesOcclusion;
    #else
        half4 shadowMask = half4(1, 1, 1, 1);
    #endif

    //Light mainLight = GetMainLight(inputData.shadowCoord);
    Light mainLight = GetMainLight(inputData.shadowCoord, inputData.positionWS, shadowMask);

    #if defined(_SCREEN_SPACE_OCCLUSION)
        AmbientOcclusionFactor aoFactor = GetScreenSpaceAmbientOcclusion(inputData.normalizedScreenSpaceUV);
        mainLight.color *= aoFactor.directAmbientOcclusion;
        occlusion = min(occlusion, aoFactor.indirectAmbientOcclusion);
    #endif

    MixRealtimeAndBakedGI(mainLight, inputData.normalWS, inputData.bakedGI, half4(0, 0, 0, 0));

    half3 color = LuxExtended_GlobalIllumination(brdfData, inputData.bakedGI, occlusion, inputData.normalWS, inputData.viewDirectionWS,  GItoAO, GItoAOBias, bentNormal, geoNormalWS, horizonOcllusion);
    color += LightingPhysicallyBased(brdfData, mainLight, inputData.normalWS, inputData.viewDirectionWS);

#ifdef _ADDITIONAL_LIGHTS
    uint pixelLightCount = GetAdditionalLightsCount();
    for (uint lightIndex = 0u; lightIndex < pixelLightCount; ++lightIndex)
    {
    //  Light light = GetAdditionalLight(lightIndex, inputData.positionWS);
    //  URP 10: We have to use the new GetAdditionalLight function
        Light light = GetAdditionalLight(lightIndex, inputData.positionWS, shadowMask);
        color += LightingPhysicallyBased(brdfData, light, inputData.normalWS, inputData.viewDirectionWS);
    }
#endif

#ifdef _ADDITIONAL_LIGHTS_VERTEX
    color += inputData.vertexLighting * brdfData.diffuse;
#endif
    color += emission;
    return half4(color, alpha);
}