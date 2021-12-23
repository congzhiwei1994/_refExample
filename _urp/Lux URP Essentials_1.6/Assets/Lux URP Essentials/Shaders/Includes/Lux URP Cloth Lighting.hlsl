// NOTE: Based on URP Lighting.hlsl which replaced some half3 with floats to avoid lighting artifacts on mobile
// Hair lighting functions renamed to solves problems with LWRP 6.x


// https://google.github.io/filament/Filament.md.html#materialsystem/clothmodel
// SheenColor

#ifndef LIGHTWEIGHT_CLOTHLIGHTING_INCLUDED
#define LIGHTWEIGHT_CLOTHLIGHTING_INCLUDED

#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Common.hlsl"
#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/EntityLighting.hlsl"
#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/ImageBasedLighting.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl"

// --------- rename!!!!!!!!!

// Ref: https://knarkowicz.wordpress.com/2018/01/04/cloth-shading/
real D_CharlieNoPI_Lux(real NdotH, real roughness)
{
    float invR = rcp(roughness);
    float cos2h = NdotH * NdotH;
    float sin2h = 1.0 - cos2h;
    // Note: We have sin^2 so multiply by 0.5 to cancel it
    return (2.0 + invR) * PositivePow(sin2h, invR * 0.5) / 2.0;
}

real D_Charlie_Lux(real NdotH, real roughness)
{
    return INV_PI * D_CharlieNoPI_Lux(NdotH, roughness);
}

// We use V_Ashikhmin instead of V_Charlie in practice for game due to the cost of V_Charlie
real V_Ashikhmin_Lux(real NdotL, real NdotV)
{
    // Use soft visibility term introduce in: Crafting a Next-Gen Material Pipeline for The Order : 1886
    return 1.0 / (4.0 * (NdotL + NdotV - NdotL * NdotV));
}

// A diffuse term use with fabric done by tech artist - empirical
real FabricLambertNoPI_Lux(real roughness)
{
    return lerp(1.0, 0.5, roughness);
}

real FabricLambert_Lux(real roughness)
{
    return INV_PI * FabricLambertNoPI_Lux(roughness);
}

// ---------

struct AdditionalData {
    half3   tangentWS;
    half3   bitangentWS;
    float   partLambdaV;
    half    roughnessT;
    half    roughnessB;
    half3   anisoReflectionNormal;
    half3   sheenColor;
};

half3 DirectBDRF_LuxCloth(BRDFData brdfData, AdditionalData addData, half3 normalWS, half3 lightDirectionWS, half3 viewDirectionWS, half NdotL)
{
#ifndef _SPECULARHIGHLIGHTS_OFF
    float3 halfDir = SafeNormalize(lightDirectionWS + viewDirectionWS);

    float NoH = saturate(dot(normalWS, halfDir));
    half LoH = saturate(dot(lightDirectionWS, halfDir));

    half NdotV = saturate(dot(normalWS, viewDirectionWS ));

    #if defined(_COTTONWOOL)

    //  NOTE: We use the noPI version here!!!!!!
        float D = D_CharlieNoPI_Lux(NoH, brdfData.roughness);
    //  Unity: V_Charlie is expensive, use approx with V_Ashikhmin instead
    //  Unity: float Vis = V_Charlie(NdotL, NdotV, bsdfData.roughness);
        float Vis = V_Ashikhmin_Lux(NdotL, NdotV);

    //  Unity: Fabrics are dieletric but we simulate forward scattering effect with colored specular (fuzz tint term)
    //  Unity: We don't use Fresnel term for CharlieD
    //  SheenColor seemed way too dark (compared to HDRP) – so i multiply it with PI which looked ok and somehow matched HDRP
    //  Therefore we use the noPI charlie version. As PI is a constant factor the artists can tweak the look by adjusting the sheen color.
        float3 F = addData.sheenColor; // * PI;
        half3 specularLighting = F * Vis * D;

    //  Unity: Note: diffuseLighting originally is multiply by color in PostEvaluateBSDF
    //  So we do it here :)
    //  Using saturate to get rid of artifacts around the borders.
        return saturate(specularLighting) + brdfData.diffuse * FabricLambert_Lux(brdfData.roughness);
    
    #else
        float TdotH = dot(addData.tangentWS, halfDir);
        float TdotL = dot(addData.tangentWS, lightDirectionWS);
        float BdotH = dot(addData.bitangentWS, halfDir);
        float BdotL = dot(addData.bitangentWS, lightDirectionWS);

        float3 F = F_Schlick(brdfData.specular, LoH);

        //float TdotV = dot(addData.tangentWS, viewDirectionWS);
        //float BdotV = dot(addData.bitangentWS, viewDirectionWS);

        float DV = DV_SmithJointGGXAniso(
            TdotH, BdotH, NoH, NdotV, TdotL, BdotL, NdotL,
            addData.roughnessT, addData.roughnessB, addData.partLambdaV
        );
        // Check NdotL gets factores in outside as well.. correct?
        half3 specularLighting = F * DV;

        return specularLighting + brdfData.diffuse;
    #endif

    

    //half3 color = specularTerm * brdfData.specular + brdfData.diffuse;
    //return color;
#else
    return brdfData.diffuse;
#endif
}

half3 LightingPhysicallyBased_LuxCloth(BRDFData brdfData, AdditionalData addData, half3 lightColor, half3 lightDirectionWS, half lightAttenuation, half3 normalWS, half3 viewDirectionWS, half NdotL)
{
    //half NdotL = saturate(dot(normalWS, lightDirectionWS));
    half3 radiance = lightColor * (lightAttenuation * NdotL);
    return DirectBDRF_LuxCloth(brdfData, addData, normalWS, lightDirectionWS, viewDirectionWS, NdotL) * radiance;
}

half3 LightingPhysicallyBased_LuxCloth(BRDFData brdfData, AdditionalData addData, Light light, half3 normalWS, half3 viewDirectionWS, half NdotL)
{
    return LightingPhysicallyBased_LuxCloth(brdfData, addData, light.color, light.direction, light.distanceAttenuation * light.shadowAttenuation, normalWS, viewDirectionWS, NdotL);
}



half4 LuxLWRPClothFragmentPBR(InputData inputData, half3 albedo, half metallic, half3 specular,
    half smoothness, half occlusion, half3 emission, half alpha, half3 tangentWS, half3 bitangentWS, half anisotropy, half3 sheenColor, half4 translucency)
{
    
    #if defined(_COTTONWOOL)
        smoothness = lerp(0.0h, 0.6h, smoothness);
    #endif


    BRDFData brdfData;
    InitializeBRDFData(albedo, metallic, specular, smoothness, alpha, brdfData);

//  Do not apply energy conservtion
    brdfData.diffuse = albedo;
    brdfData.specular = specular;

    AdditionalData addData;
//  The missing bits - checked with per vertex bitangent and tangent    
    addData.bitangentWS = normalize( -cross(inputData.normalWS, tangentWS) ); //bitangentWS;
//  We can get away with a single normalize here
    addData.tangentWS = cross(inputData.normalWS, addData.bitangentWS); // tangentWS;

//  We do not apply ClampRoughnessForAnalyticalLights here
    addData.roughnessT = brdfData.roughness * (1 + anisotropy);
    addData.roughnessB = brdfData.roughness * (1 - anisotropy);

    #if !defined(_COTTONWOOL)
        float TdotV = dot(addData.tangentWS, inputData.viewDirectionWS);
        float BdotV = dot(addData.bitangentWS, inputData.viewDirectionWS);
        float NdotV = dot(inputData.normalWS, inputData.viewDirectionWS);
        addData.partLambdaV = GetSmithJointGGXAnisoPartLambdaV(TdotV, BdotV, NdotV, addData.roughnessT, addData.roughnessB);

    //  Set reflection normal and roughness – derived from GetGGXAnisotropicModifiedNormalAndRoughness
        half3 grainDirWS = (anisotropy >= 0.0) ? bitangentWS : tangentWS;
        half stretch = abs(anisotropy) * saturate(1.5h * sqrt(brdfData.perceptualRoughness));
        addData.anisoReflectionNormal = GetAnisotropicModifiedNormal(grainDirWS, inputData.normalWS, inputData.viewDirectionWS, stretch);
        half iblPerceptualRoughness = brdfData.perceptualRoughness * saturate(1.2 - abs(anisotropy));

    //  Overwrite perceptual roughness for ambient specular reflections
        brdfData.perceptualRoughness = iblPerceptualRoughness;
    #else
    //  partLambdaV should be 0.0f in case of cotton wool
        addData.partLambdaV = 0.0h;
        addData.anisoReflectionNormal = inputData.normalWS;

        float NdotV = dot(inputData.normalWS, inputData.viewDirectionWS);

    //  Only used for reflections - so we skip it
        /*float3 preFGD = SAMPLE_TEXTURE2D_LOD(_PreIntegratedLUT, sampler_PreIntegratedLUT, float2(NdotV, brdfData.perceptualRoughness), 0).xyz;
        // Denormalize the value
        preFGD.y = preFGD.y / (1 - preFGD.y);
        half3 specularFGD = preFGD.yyy * fresnel0;
        // z = FabricLambert
        half3 diffuseFGD = preFGD.z;
        half reflectivity = preFGD.y;*/
    #endif
    addData.sheenColor = sheenColor;

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
    half3 color = GlobalIllumination(brdfData, inputData.bakedGI, occlusion, addData.anisoReflectionNormal, inputData.viewDirectionWS);
    color += LightingPhysicallyBased_LuxCloth(brdfData, addData, mainLight, inputData.normalWS, inputData.viewDirectionWS, NdotL);

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
            color += LightingPhysicallyBased_LuxCloth(brdfData, addData, light, inputData.normalWS, inputData.viewDirectionWS, NdotL);
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

    color += emission;

    return half4(color, alpha);
}


#endif
