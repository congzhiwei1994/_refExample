// NOTE: Based on URP Lighting.hlsl which replaced some half3 with floats to avoid lighting artifacts on mobile

#ifndef LIGHTWEIGHT_FUZZLIGHTING_INCLUDED
#define LIGHTWEIGHT_FUZZHLIGHTING_INCLUDED

#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Common.hlsl"
#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/EntityLighting.hlsl"
#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/ImageBasedLighting.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl"

real Fuzz(real NdotV, real fuzzPower, real fuzzBias)
{
    return exp2( (1.0h - NdotV) * fuzzPower - fuzzPower) + fuzzBias;
}

real WrappedDiffuse(real NdotL, real3 normalWS, real3 lightDirectionWS, real wrap)
{
    return saturate( (dot(normalWS, lightDirectionWS) + wrap) * rcp( (1.0h + wrap) * (1.0h + wrap) ) );
}

// ---------

struct AdditionalData {
    half    fuzzWrap;
    half    fuzz;
};

half3 DirectBDRF_LuxFuzz(BRDFData brdfData, half3 normalWS, half3 lightDirectionWS, half3 viewDirectionWS, half NdotL)
{
//  Regular Code
    #ifndef _SPECULARHIGHLIGHTS_OFF
        float3 halfDir = SafeNormalize(lightDirectionWS + viewDirectionWS);

        float NoH = saturate(dot(normalWS, halfDir));
        half LoH = saturate(dot(lightDirectionWS, halfDir));

    //  Standard specular lighting
        float d = NoH * NoH * brdfData.roughness2MinusOne + 1.00001f;
        half LoH2 = LoH * LoH;
        half specularTerm = brdfData.roughness2 / ((d * d) * max(0.1h, LoH2) * brdfData.normalizationTerm);
        #if defined (SHADER_API_MOBILE) || defined (SHADER_API_SWITCH)
            specularTerm = specularTerm - HALF_MIN;
            specularTerm = clamp(specularTerm, 0.0, 100.0); // Prevent FP16 overflow on mobiles
        #endif

        return specularTerm * brdfData.specular + brdfData.diffuse;
    #else
        return brdfData.diffuse;
    #endif
}

half3 LightingPhysicallyBased_LuxFuzz(BRDFData brdfData,
    #if defined(_SIMPLEFUZZ)
        AdditionalData addData,
    #endif
    half3 lightColor, half3 lightDirectionWS, half lightAttenuation, half3 normalWS, half3 viewDirectionWS, half NdotL)
{
    half3 radiance = lightColor * (lightAttenuation * NdotL);
    #if defined(_SIMPLEFUZZ)
        half wrappedNdotL = WrappedDiffuse(NdotL, normalWS, lightDirectionWS, addData.fuzzWrap);
    #endif

    return DirectBDRF_LuxFuzz(brdfData, normalWS, lightDirectionWS, viewDirectionWS, NdotL) * radiance 
    #if defined(_SIMPLEFUZZ)
          + (addData.fuzz * brdfData.diffuse) * lightColor * (lightAttenuation * wrappedNdotL )
    #endif
    ;
}

half3 LightingPhysicallyBased_LuxFuzz(BRDFData brdfData,
    #if defined(_SIMPLEFUZZ)
        AdditionalData addData,
    #endif
    Light light, half3 normalWS, half3 viewDirectionWS, half NdotL)
{
    return LightingPhysicallyBased_LuxFuzz(brdfData,
        #if defined(_SIMPLEFUZZ) 
            addData,
        #endif
        light.color, light.direction, light.distanceAttenuation * light.shadowAttenuation, normalWS, viewDirectionWS, NdotL);
}



half4 LuxURPSimpleFuzzFragmentPBR(InputData inputData, half3 albedo, half metallic, half3 specular,
    half smoothness, half occlusion, half3 emission, half alpha, half4 translucency, half fuzzMask, half fuzzPower, half fuzzBias, half fuzzWrap, half fuzzStrength, half fuzzAmbient)
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

    half NdotL = saturate(dot(inputData.normalWS, mainLight.direction ));

    #if defined(_SIMPLEFUZZ)
        AdditionalData addData;
        addData.fuzzWrap = fuzzWrap;
    //  We tweak the diffuse to get some ambient fuzz lighting as well.
        half NdotV = saturate(dot(inputData.normalWS, inputData.viewDirectionWS ));
        addData.fuzz = Fuzz(NdotV, fuzzPower, fuzzBias);
        addData.fuzz *= fuzzMask * fuzzStrength;
        half3 diffuse = brdfData.diffuse;
        brdfData.diffuse *= 1.0h + addData.fuzz * fuzzAmbient;
    #endif

    half3 color = GlobalIllumination(brdfData, inputData.bakedGI, occlusion, inputData.normalWS, inputData.viewDirectionWS);
    #if defined(_SIMPLEFUZZ)
    //  Reset diffuse as we want to use WrappedNdotL lighting.
        brdfData.diffuse = diffuse;
    #endif
    
    color += LightingPhysicallyBased_LuxFuzz(brdfData,
        #if defined(_SIMPLEFUZZ) 
            addData,
        #endif
        mainLight, inputData.normalWS, inputData.viewDirectionWS, NdotL);
//  translucency
    #if defined(_SCATTERING)
        half transPower = translucency.y;
        half3 transLightDir = mainLight.direction + inputData.normalWS * translucency.w;
        half transDot = dot( transLightDir, -inputData.viewDirectionWS );
        transDot = exp2(saturate(transDot) * transPower - transPower);
        color += brdfData.diffuse * transDot * (1.0 - NdotL) * mainLightColor * lerp(1.0h, mainLight.shadowAttenuation, translucency.z) * translucency.x * 4;
    #endif

    #ifdef _ADDITIONAL_LIGHTS
        int pixelLightCount = GetAdditionalLightsCount();
        for (int i = 0; i < pixelLightCount; ++i)
        {
            // Light light = GetAdditionalPerObjectLight(index, positionWS); // here; shadowAttenuation = 1.0;
        //  URP 10: We have to use the new GetAdditionalLight function
            Light light = GetAdditionalLight(i, inputData.positionWS, shadowMask);
            half3 lightColor = light.color;
            #if defined(_SCREEN_SPACE_OCCLUSION)
                light.color *= aoFactor.directAmbientOcclusion;
            #endif
            NdotL = saturate(dot(inputData.normalWS, light.direction ));
            color += LightingPhysicallyBased_LuxFuzz(brdfData,
                #if defined(_SIMPLEFUZZ) 
                    addData,
                #endif
                light, inputData.normalWS, inputData.viewDirectionWS, NdotL);
    //  translucency
        #if defined(_SCATTERING)
            transPower = translucency.y;
            transLightDir = light.direction + inputData.normalWS * translucency.w;
            transDot = dot( transLightDir, -inputData.viewDirectionWS );
            transDot = exp2(saturate(transDot) * transPower - transPower);
            color += brdfData.diffuse * transDot * (1.0 - NdotL) * lightColor * lerp(1.0h, light.shadowAttenuation, translucency.z) * light.distanceAttenuation  * translucency.x * 4;
        #endif
        }
    #endif

    #ifdef _ADDITIONAL_LIGHTS_VERTEX
        color += inputData.vertexLighting * brdfData.diffuse;
    #endif
    //color += emission;
    return half4(color, alpha);
}
#endif