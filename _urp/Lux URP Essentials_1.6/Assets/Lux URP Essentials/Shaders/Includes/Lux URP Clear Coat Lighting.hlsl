// NOTE: Based on URP Lighting.hlsl which replaced some half3 with floats to avoid lighting artifacts on mobile
// Hair lighting functions renamed to solves problems with LWRP 6.x


// https://google.github.io/filament/Filament.md.html#materialsystem/clothmodel
// SheenColor

#ifndef UNIVERSAL_CLEARCOATLIGHTING_INCLUDED
#define UNIVERSAL_CLEARCOATLIGHTING_INCLUDED

#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Common.hlsl"
#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/EntityLighting.hlsl"
#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/ImageBasedLighting.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl"



// ---------

struct AdditionalData {
    half coatThickness;
    half3 coatSpecular;
    half3 normalWS;
    half perceptualRoughness;
    half roughness;
    half roughness2;
    half normalizationTerm;
    half roughness2MinusOne;    // roughness² - 1.0
    half reflectivity;
    half grazingTerm;
    half specOcclusion;
};

half3 DirectBDRF_LuxClearCoat(BRDFData brdfData, AdditionalData addData, half3 normalWS, half3 lightDirectionWS, half3 viewDirectionWS, half NdotL)
{
#ifndef _SPECULARHIGHLIGHTS_OFF
    
    float3 halfDir = SafeNormalize(lightDirectionWS + viewDirectionWS);
    half LoH = saturate(dot(lightDirectionWS, halfDir));

//  Base Lobe
    float NoH = saturate(dot(normalWS, halfDir));
    float d = NoH * NoH * brdfData.roughness2MinusOne + 1.00001f;
    half LoH2 = LoH * LoH;
    LoH2 = max(0.1h, LoH2);
    half specularTerm = brdfData.roughness2 / ((d * d) * LoH2 /* max(0.1h, LoH2 */ * brdfData.normalizationTerm);
#if defined (SHADER_API_MOBILE) || defined (SHADER_API_SWITCH)
    specularTerm = specularTerm - HALF_MIN;
    specularTerm = clamp(specularTerm, 0.0, 100.0); // Prevent FP16 overflow on mobiles
#endif

    half3 spec = specularTerm * brdfData.specular * NdotL;

//  Coat Lobe

//  From HDRP: Scale base specular

    #if defined (_MASKMAP) && defined(_STANDARDLIGHTING)
        [branch]
        if (addData.coatThickness > 0.0h) {
    #endif
            half coatF = F_Schlick(addData.reflectivity /*addData.coatSpecular*/ /*CLEAR_COAT_F0*/, LoH) * addData.coatThickness;
            spec *= Sq(1.0h - coatF);

            NoH = saturate(dot(addData.normalWS, halfDir));
            d = NoH * NoH * addData.roughness2MinusOne + 1.00001f;
            // LoH2 = LoH * LoH;
            specularTerm = addData.roughness2 / ((d * d) * LoH2 /* max(0.1h, LoH2 */ * addData.normalizationTerm);
        #if defined (SHADER_API_MOBILE) || defined (SHADER_API_SWITCH)
            specularTerm = specularTerm - HALF_MIN;
            specularTerm = clamp(specularTerm, 0.0, 100.0); // Prevent FP16 overflow on mobiles
        #endif
            spec += specularTerm * addData.coatSpecular * saturate(dot(addData.normalWS, lightDirectionWS));
    #if defined (_MASKMAP) && defined(_STANDARDLIGHTING)
        }
    #endif

    half3 color = spec + brdfData.diffuse * NdotL; // from HDRP (but does not do much?) * lerp(1.0h, 1.0h - coatF, addData.coatThickness);
    return color;
#else
    return brdfData.diffuse * NdotL;
#endif
}

half3 LightingPhysicallyBased_LuxClearCoat(BRDFData brdfData, AdditionalData addData, half3 lightColor, half3 lightDirectionWS, half lightAttenuation, half3 normalWS, half3 viewDirectionWS)
{
    half NdotL = saturate(dot(normalWS, lightDirectionWS));
    half3 radiance = lightColor * (lightAttenuation); // * NdotL);
    return DirectBDRF_LuxClearCoat(brdfData, addData, normalWS, lightDirectionWS, viewDirectionWS, NdotL) * radiance;
}

half3 LightingPhysicallyBased_LuxClearCoat(BRDFData brdfData, AdditionalData addData, Light light, half3 normalWS, half3 viewDirectionWS)
{
    return LightingPhysicallyBased_LuxClearCoat(brdfData, addData, light.color, light.direction, light.distanceAttenuation * light.shadowAttenuation, normalWS, viewDirectionWS);
}

half3 EnvironmentBRDF_LuxClearCoat(BRDFData brdfData, AdditionalData addData, half3 indirectDiffuse, half3 indirectSpecular, half fresnelTerm)
{
    half3 c = indirectDiffuse * brdfData.diffuse;
    float surfaceReduction = 1.0 / (addData.roughness2 + 1.0);
    c += surfaceReduction * indirectSpecular * lerp(addData.coatSpecular, addData.grazingTerm, fresnelTerm);
    return c;
}


half3 GlobalIllumination_LuxClearCoat(BRDFData brdfData, AdditionalData addData, half3 bakedGI, half occlusion, half3 normalWS, half3 baseNormalWS, half3 viewDirectionWS, half NdotV)
{
    half3 reflectVector = reflect(-viewDirectionWS, normalWS);
    half fresnelTerm = Pow4(1.0 - NdotV);

    half3 indirectDiffuse = bakedGI * occlusion; 
    half3 indirectSpecular = GlossyEnvironmentReflection(reflectVector, addData.perceptualRoughness, addData.specOcclusion);
    //return EnvironmentBRDF_LuxClearCoat(brdfData, addData, indirectDiffuse, indirectSpecular, fresnelTerm);

    half3 res = EnvironmentBRDF_LuxClearCoat(brdfData, addData, indirectDiffuse, indirectSpecular, fresnelTerm);

    #if defined(_SECONDARYLOBE)
        #if defined (_MASKMAP) && defined(_STANDARDLIGHTING)
            [branch]
            if (addData.coatThickness > 0.0h) {
        #endif
                reflectVector = reflect(-viewDirectionWS, baseNormalWS);
                indirectSpecular = GlossyEnvironmentReflection(reflectVector, brdfData.perceptualRoughness, 1);
                float surfaceReduction = 1.0 / (brdfData.roughness2 + 1.0);
                res += NdotV * surfaceReduction * indirectSpecular * lerp(brdfData.specular, brdfData.grazingTerm, fresnelTerm);
        #if defined (_MASKMAP) && defined(_STANDARDLIGHTING)
            }
        #endif
    #endif
    return res;
}

half3 f0ClearCoatToSurface_Lux(half3 f0) 
{
    // Approximation of iorTof0(f0ToIor(f0), 1.5)
    // This assumes that the clear coat layer has an IOR of 1.5
#if defined(SHADER_API_MOBILE)
    return saturate(f0 * (f0 * 0.526868h + 0.529324h) - 0.0482256h);
#else
    return saturate(f0 * (f0 * (0.941892h - 0.263008h * f0) + 0.346479h) - 0.0285998h);
#endif
}


half4 LuxClearCoatFragmentPBR(InputData inputData, half3 albedo, half metallic, half3 specular,
    half smoothness, half occlusion, half3 emission, half alpha,
    half clearcoatSmoothness,
    half clearcoatThickness,
    half3 clearcoatSpecular,
    half3 vertexNormalWS,
    half3 baseColor,
    half3 secondaryColor
)
{
    
    half NdotV = saturate( dot(vertexNormalWS, inputData.viewDirectionWS) );
    #if defined(_SECONDARYCOLOR)
        albedo = lerp(secondaryColor, baseColor, NdotV);
    #else
        albedo = baseColor;
    #endif


    BRDFData brdfData;
    InitializeBRDFData(albedo, metallic, specular, smoothness, alpha, brdfData);


    //#if defined(_ADJUSTSPEC)
//        brdfData.specular = lerp(brdfData.specular, ConvertF0ForAirInterfaceToF0ForClearCoat15(brdfData.specular), clearcoatThickness);
          brdfData.specular = lerp(brdfData.specular, f0ClearCoatToSurface_Lux(brdfData.specular), clearcoatThickness);
    //#endif

//  URP does also modify the roughness
//  Modify Roughness of base layer
/*  half ieta = lerp(1.0h, CLEAR_COAT_IETA, outBRDFData.clearCoat);
    half coatRoughnessScale = Sq(ieta);
    half sigma = RoughnessToVariance(PerceptualRoughnessToRoughness(outBRDFData.perceptualRoughness));
    outBRDFData.perceptualRoughness = RoughnessToPerceptualRoughness(VarianceToRoughness(sigma * coatRoughnessScale));
*/

    AdditionalData addData; //  = (AdditionalData)0;

    #if defined (_MASKMAP) && defined(_STANDARDLIGHTING)
        [branch]
        if (clearcoatThickness == 0.0h) {
            addData.coatThickness = 0.0h;
            addData.coatSpecular = brdfData.specular;
            addData.normalWS = inputData.normalWS;
            addData.perceptualRoughness = brdfData.perceptualRoughness;
            addData.roughness = brdfData.roughness;
            addData.roughness2 = brdfData.roughness2;
            addData.normalizationTerm = brdfData.normalizationTerm;
            addData.roughness2MinusOne = brdfData.roughness2MinusOne; 
            addData.reflectivity = ReflectivitySpecular(brdfData.specular);
            addData.grazingTerm = brdfData.grazingTerm;
            addData.specOcclusion = occlusion;
        }
        else {
    #endif
        addData.coatThickness = clearcoatThickness;
        addData.coatSpecular = clearcoatSpecular;
        addData.normalWS = vertexNormalWS;
        addData.perceptualRoughness = PerceptualSmoothnessToPerceptualRoughness(clearcoatSmoothness);
        addData.roughness = PerceptualRoughnessToRoughness(addData.perceptualRoughness);
        addData.roughness2 = addData.roughness * addData.roughness;
        addData.normalizationTerm = addData.roughness * 4.0h + 2.0h;
        addData.roughness2MinusOne = addData.roughness2 - 1.0h;
        addData.reflectivity = ReflectivitySpecular(clearcoatSpecular);
        addData.grazingTerm = saturate(clearcoatSmoothness + addData.reflectivity);
        addData.specOcclusion = 1;
    #if defined (_MASKMAP) && defined(_STANDARDLIGHTING)
        }
    #endif

//  ShadowMask: To ensure backward compatibility we have to avoid using shadowMask input, as it is not present in older shaders
    #if defined(SHADOWS_SHADOWMASK) && defined(LIGHTMAP_ON)
        half4 shadowMask = inputData.shadowMask;
    #elif !defined (LIGHTMAP_ON)
        half4 shadowMask = unity_ProbesOcclusion;
    #else
        half4 shadowMask = half4(1, 1, 1, 1);
    #endif

    Light mainLight = GetMainLight(inputData.shadowCoord, inputData.positionWS, shadowMask);
    //Light mainLight = GetMainLight(inputData.shadowCoord);

//  SSAO
    #if defined(_SCREEN_SPACE_OCCLUSION)
        AmbientOcclusionFactor aoFactor = GetScreenSpaceAmbientOcclusion(inputData.normalizedScreenSpaceUV);
        mainLight.color *= aoFactor.directAmbientOcclusion;
        occlusion = min(occlusion, aoFactor.indirectAmbientOcclusion);
    #endif    

    MixRealtimeAndBakedGI(mainLight, addData.normalWS, inputData.bakedGI, half4(0, 0, 0, 0));

//  Approximation of refraction on BRDF
    half refractionScale = ((NdotV * 0.5 + 0.5) * NdotV - 1.0) * saturate(1.25 - 1.25 * (1.0 - clearcoatSmoothness)) + 1;
    brdfData.diffuse = lerp(brdfData.diffuse, brdfData.diffuse * refractionScale, clearcoatThickness);
//  brdfData.specular = brdfData.specular * lerp(1.0, refractionScale, clearcoatThickness);

    half3 color = GlobalIllumination_LuxClearCoat(brdfData, addData, inputData.bakedGI, occlusion, addData.normalWS, inputData.normalWS, inputData.viewDirectionWS, NdotV);

//  Adjust base specular as we have a transition from coat to material and not air to material
    #if defined(_ADJUSTSPEC)
//        brdfData.specular = lerp(brdfData.specular, ConvertF0ForAirInterfaceToF0ForClearCoat15(brdfData.specular), addData.coatThickness);
    #endif


    color += LightingPhysicallyBased_LuxClearCoat(brdfData, addData, mainLight, inputData.normalWS, inputData.viewDirectionWS);

    #ifdef _ADDITIONAL_LIGHTS
        int pixelLightCount = GetAdditionalLightsCount();
        for (int i = 0; i < pixelLightCount; ++i)
        {
            // Light light = GetAdditionalPerObjectLight(i, inputData.positionWS); // here; shadowAttenuation = 1.0;
        //  URP 10: We have to use the new GetAdditionalLight function
            Light light = GetAdditionalLight(i, inputData.positionWS, shadowMask);
            #if defined(_SCREEN_SPACE_OCCLUSION)
                light.color *= aoFactor.directAmbientOcclusion;
            #endif
            color += LightingPhysicallyBased_LuxClearCoat(brdfData, addData, light, inputData.normalWS, inputData.viewDirectionWS);
        }
    #endif

    #ifdef _ADDITIONAL_LIGHTS_VERTEX
        color += inputData.vertexLighting * brdfData.diffuse;
    #endif

if (addData.coatThickness == 0.0h) {
//color  = half3(1,0,0);
}

//color = clearcoatSmoothness.xxx;
    color += emission;
    return half4(color, alpha);
}

#endif