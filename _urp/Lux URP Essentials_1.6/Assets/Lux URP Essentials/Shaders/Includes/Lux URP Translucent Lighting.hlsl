// NOTE: Based on URP Lighting.hlsl which rplaced some half3 with floats to avoid lighting artifacts on mobile


#ifndef LIGHTWEIGHT_TRANSLUCENTLIGHTING_INCLUDED
#define LIGHTWEIGHT_TRANSLUCENTLIGHTING_INCLUDED



// Based on Minimalist CookTorrance BRDF
// Implementation is slightly different from original derivation: http://www.thetenthplanet.de/archives/255
//
// * NDF [Modified] GGX
// * Modified Kelemen and Szirmay-​Kalos for Visibility term
// * Fresnel approximated with 1/LdotH
half3 DirectBDRF_Lux(BRDFData brdfData, half3 normalWS, half3 lightDirectionWS, half3 viewDirectionWS)
{
#ifndef _SPECULARHIGHLIGHTS_OFF
    float3 halfDir = SafeNormalize(lightDirectionWS + viewDirectionWS);

    float NoH = saturate(dot(normalWS, halfDir));
    half LoH = saturate(dot(lightDirectionWS, halfDir));

    // GGX Distribution multiplied by combined approximation of Visibility and Fresnel
    // BRDFspec = (D * V * F) / 4.0
    // D = roughness² / ( NoH² * (roughness² - 1) + 1 )²
    // V * F = 1.0 / ( LoH² * (roughness + 0.5) )
    // See "Optimizing PBR for Mobile" from Siggraph 2015 moving mobile graphics course
    // https://community.arm.com/events/1155

    // Final BRDFspec = roughness² / ( NoH² * (roughness² - 1) + 1 )² * (LoH² * (roughness + 0.5) * 4.0)
    // We further optimize a few light invariant terms
    // brdfData.normalizationTerm = (roughness + 0.5) * 4.0 rewritten as roughness * 4.0 + 2.0 to a fit a MAD.
    float d = NoH * NoH * brdfData.roughness2MinusOne + 1.00001f;

    half LoH2 = LoH * LoH;
    half specularTerm = brdfData.roughness2 / ((d * d) * max(0.1h, LoH2) * brdfData.normalizationTerm);

    // On platforms where half actually means something, the denominator has a risk of overflow
    // clamp below was added specifically to "fix" that, but dx compiler (we convert bytecode to metal/gles)
    // sees that specularTerm have only non-negative terms, so it skips max(0,..) in clamp (leaving only min(100,...))
#if defined (SHADER_API_MOBILE) || defined (SHADER_API_SWITCH)
    specularTerm = specularTerm - HALF_MIN;
    specularTerm = clamp(specularTerm, 0.0, 100.0); // Prevent FP16 overflow on mobiles
#endif

    half3 color = specularTerm * brdfData.specular + brdfData.diffuse;
    return color;
#else
    return brdfData.diffuse;
#endif
}

half3 GlobalIllumination_Lux(BRDFData brdfData, half3 bakedGI, half occlusion, half3 normalWS, half3 viewDirectionWS, 
    half specOccluison)
{
    half3 reflectVector = reflect(-viewDirectionWS, normalWS);
    half fresnelTerm = Pow4(1.0 - saturate(dot(normalWS, viewDirectionWS)));

    half3 indirectDiffuse = bakedGI * occlusion;
    half3 indirectSpecular = GlossyEnvironmentReflection(reflectVector, brdfData.perceptualRoughness, occlusion)        * specOccluison;

    return EnvironmentBRDF(brdfData, indirectDiffuse, indirectSpecular, fresnelTerm);
}


half3 LightingPhysicallyBasedWrapped(BRDFData brdfData, half3 lightColor, half3 lightDirectionWS, half lightAttenuation, half3 normalWS, half3 viewDirectionWS, half NdotL)
{
    half3 radiance = lightColor * (lightAttenuation * NdotL);
    return DirectBDRF_Lux(brdfData, normalWS, lightDirectionWS, viewDirectionWS) * radiance;
}

half3 LightingPhysicallyBasedWrapped(BRDFData brdfData, Light light, half3 normalWS, half3 viewDirectionWS, half NdotL)
{
    return LightingPhysicallyBasedWrapped(brdfData, light.color, light.direction, light.distanceAttenuation * light.shadowAttenuation, normalWS, viewDirectionWS, NdotL);
}



half4 LuxLWRPTranslucentFragmentPBR(InputData inputData, half3 albedo, half metallic, half3 specular,
    half smoothness, half occlusion, half3 emission, half alpha, half4 translucency, half AmbientReflection
    #if defined(_CUSTOMWRAP)
        , half wrap
    #endif
    #if defined(_STANDARDLIGHTING)
        , half mask
    #endif
    , half maskbyshadowstrength
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
    half3 mainLightColor = mainLight.color;
//  SSAO
    #if defined(_SCREEN_SPACE_OCCLUSION)
        AmbientOcclusionFactor aoFactor = GetScreenSpaceAmbientOcclusion(inputData.normalizedScreenSpaceUV);
        mainLight.color *= aoFactor.directAmbientOcclusion;
        occlusion = min(occlusion, aoFactor.indirectAmbientOcclusion);
    #endif

    MixRealtimeAndBakedGI(mainLight, inputData.normalWS, inputData.bakedGI, half4(0, 0, 0, 0));

    half3 color = GlobalIllumination_Lux(brdfData, inputData.bakedGI, occlusion, inputData.normalWS, inputData.viewDirectionWS,     AmbientReflection);

//  Wrapped Diffuse
    #if defined(_CUSTOMWRAP)
        half w = wrap;
        #if defined(_STANDARDLIGHTING)
             w *= mask;
        #endif
    #else
        half w = 0.4;
    #endif
    half NdotL = saturate((dot(inputData.normalWS, mainLight.direction) + w) / ((1 + w) * (1 + w)));
    // NdotL = saturate( dot(inputData.normalWS, mainLight.direction) );
    color += LightingPhysicallyBasedWrapped(brdfData, mainLight, inputData.normalWS, inputData.viewDirectionWS, NdotL);

//  translucency
    half transPower = translucency.y;
    half3 transLightDir = mainLight.direction + inputData.normalWS * translucency.w;
    half transDot = dot( transLightDir, -inputData.viewDirectionWS );
    transDot = exp2(saturate(transDot) * transPower - transPower);
    color += brdfData.diffuse * transDot * (1.0 - NdotL) * mainLightColor * lerp(1.0h, mainLight.shadowAttenuation, translucency.z) * translucency.x * 4
    #if defined(_STANDARDLIGHTING)
        * mask
    #endif
    ;


    #ifdef _ADDITIONAL_LIGHTS
        int pixelLightCount = GetAdditionalLightsCount();
        for (int i = 0; i < pixelLightCount; ++i)
        {
            //Light light = GetAdditionalLight(i, inputData.positionWS);
        //  Get index upfront as we need it for GetAdditionalLightShadowParams();
            int index = GetPerObjectLightIndex(i);
        //  URP 10: We have to use the new GetAdditionalLight function or reconstruct it:
            Light light = GetAdditionalPerObjectLight(index, inputData.positionWS);
            half3 lightColor = light.color;
            #if defined(_SCREEN_SPACE_OCCLUSION)
                light.color *= aoFactor.directAmbientOcclusion;
            #endif
            #if USE_STRUCTURED_BUFFER_FOR_LIGHT_DATA
                half4 occlusionProbeChannels = _AdditionalLightsBuffer[index].occlusionProbeChannels;
            #else
                half4 occlusionProbeChannels = _AdditionalLightsOcclusionProbes[index];
            #endif
            light.shadowAttenuation = AdditionalLightShadow(index, inputData.positionWS, shadowMask, occlusionProbeChannels);

    //  Wrapped Diffuse
            NdotL = saturate((dot(inputData.normalWS, light.direction) + w) / ((1 + w) * (1 + w)));
            color += LightingPhysicallyBasedWrapped(brdfData, light, inputData.normalWS, inputData.viewDirectionWS, NdotL);

    //  Transmission
            half4 shadowParams = GetAdditionalLightShadowParams(index);
            light.color *= lerp(1, shadowParams.x, maskbyshadowstrength); // shadowParams.x == shadow strength, which is 0 for point lights

            transLightDir = light.direction + inputData.normalWS * translucency.w;
            transDot = dot( transLightDir, -inputData.viewDirectionWS );
            transDot = exp2(saturate(transDot) * transPower - transPower);
            color += brdfData.diffuse * transDot * (1.0 - NdotL) * lightColor * lerp(1.0h, light.shadowAttenuation, translucency.z) * light.distanceAttenuation * translucency.x * 4
            #if defined(_STANDARDLIGHTING)
                * mask
            #endif
            ;
        }
    #endif

    #ifdef _ADDITIONAL_LIGHTS_VERTEX
        color += inputData.vertexLighting * brdfData.diffuse;
    #endif

    color += emission;

    return half4(color, alpha);
}




#endif
