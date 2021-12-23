// NOTE: Based on URP Lighting.hlsl which replaced some half3 with floats to avoid lighting artifacts on mobile

#ifndef UNIVERSAL_TOONLIGHTING_INCLUDED
#define UNIVERSAL_TOONLIGHTING_INCLUDED

#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Common.hlsl"
#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/EntityLighting.hlsl"
#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/ImageBasedLighting.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl"


//  Toon
    TEXTURE2D(_GradientMap); float4 _GradientMap_TexelSize;
    SAMPLER(s_point_clamp_sampler);
    SAMPLER(s_linear_clamp_sampler);


//  ///////////////////////////////////////////////////////////
//
//  Custom functions

half3 LightingSpecular_Toon (Light light, half lightingRemap, half3 normalWS, half3 viewDirectionWS, half3 specular, half specularSmoothness, half smoothness, half specularStep, half specularUpper, bool energyConservation){
    half3 halfVec = SafeNormalize(light.direction + viewDirectionWS);
    half NdotH = saturate(dot(normalWS, halfVec));
    half modifier = pow(NdotH /* lightingRemap*/, specularSmoothness);
//  Normalization? Na, we just multiply by smoothness in the return statement.
    // #define ONEOVERTWOPI 0.159155h
    // half normalization = (specularSmoothness + 1) * ONEOVERTWOPI;
//  Sharpen
    half modifierSharpened = smoothstep(specularStep, specularUpper, modifier);
    half toonNormalization = (energyConservation == 1.0h) ? smoothness : 1;
    return light.color * specular * modifierSharpened * toonNormalization; // * smoothness;
}

// https://www.ronja-tutorials.com/2019/11/29/fwidth.html
half aaStep(half compValue, half gradient, half softness){
    half change = fwidth(gradient) * softness;
//  Base the range of the inverse lerp on the change over two pixels
    half lowerEdge = compValue - change;
    half upperEdge = compValue + change;
//  Do the inverse interpolation
    half stepped = (gradient - lowerEdge) / (upperEdge - lowerEdge);
    stepped = saturate(stepped);
    return stepped;
}


half4 LuxURPToonFragmentPBR(InputData inputData,
    half3 albedo, half3 shadedAlbedo,
    half metallic, half3 specular,
    half steps, half diffuseStep, half diffuseFalloff, 
    half energyConservation, half specularStep, half specularFalloff,
    half mainLightAttenContribution, half addLightAttenContribution, half lightColorContribution, half addLightFalloff,
    half shadowFalloff, half shadowBiasDirectional, half shadowBiasAdditional,
    half3 toonRimColor, half toonRimPower, half toonRimFallOff, half toonRimAttenuation,
    half smoothness, half occlusion, half3 emission, half alpha
)
{

    BRDFData brdfData;
//  We can't use our specular here as it can be anything. So we simply use the default dielectric value here.
    InitializeBRDFData(albedo, metallic, kDieletricSpec.rgb, smoothness, alpha, brdfData);


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

//  SSAO
    #if defined(_SCREEN_SPACE_OCCLUSION)
        #if defined(_SSAO_ENABLED)
            AmbientOcclusionFactor aoFactor = GetScreenSpaceAmbientOcclusion(inputData.normalizedScreenSpaceUV);
            mainLight.color *= aoFactor.directAmbientOcclusion;
            occlusion = min(occlusion, aoFactor.indirectAmbientOcclusion);
        #endif
    #endif
    
    mainLight.shadowAttenuation = smoothstep( (1 - shadowFalloff) * shadowFalloff, shadowFalloff, mainLight.shadowAttenuation);
    MixRealtimeAndBakedGI(mainLight, inputData.normalWS, inputData.bakedGI, half4(0, 0, 0, 0));

//  We really do not want any reflections
    #if defined(_ENVIRONMENTREFLECTIONS_OFF)
        _GlossyEnvironmentColor.rgb = half3(0,0,0);
    #endif
//  Global Illumination
    half3 GI = GlobalIllumination(brdfData, inputData.bakedGI, occlusion, inputData.normalWS, inputData.viewDirectionWS);

//  Set up Lighting
    half lightIntensity = 0.0h;
    half3 specularLighting = 0.0h;
    half3 rimLighting = 0.0h;
    half3 lightColor = 0.0h;
    half luminance;

//  Main Light
//  Remap old diffuseStep and diffuseFalloff in order to match new function
    diffuseStep = diffuseStep + 1.0h;
    diffuseFalloff = diffuseFalloff * 4.0h + 1.0h;    

    half NdotL = dot(inputData.normalWS, mainLight.direction);
    NdotL = saturate((NdotL + 1.0h) - diffuseStep);

    #if !defined(_RAMP_SMOOTHSAMPLING) && !defined(_RAMP_POINTSAMPLING)
    //  We have to use steps - 1 here!
        half oneOverSteps = 1.0h / steps;
        half quantizedNdotL = floor(NdotL * steps);
    //  IMPORTANT: no saturate on the 2nd param: NdotL - 0.01. 0.01 is eyballed.
        NdotL = (quantizedNdotL + aaStep(saturate(quantizedNdotL * oneOverSteps), NdotL - 0.01h, diffuseFalloff )) * oneOverSteps;
    #else
        #if defined(_RAMP_SMOOTHSAMPLING)
            NdotL = SAMPLE_TEXTURE2D(_GradientMap, s_linear_clamp_sampler, float2 (NdotL, 0.5f)).r;
        #else
            half NdotL0 = SAMPLE_TEXTURE2D(_GradientMap, s_point_clamp_sampler, float2 (NdotL, 0.5f)).r;
            half NdotL1 = SAMPLE_TEXTURE2D(_GradientMap, s_point_clamp_sampler, float2 (NdotL + fwidth(NdotL) * _GradientMap_TexelSize.x, 0.5f)).r;
            NdotL = (NdotL0 + NdotL1) * 0.5h;
        #endif
    #endif

    half atten = NdotL * mainLight.distanceAttenuation * saturate(shadowBiasDirectional + mainLight.shadowAttenuation);
    mainLight.color = lerp(Luminance(mainLight.color).xxx, mainLight.color, lightColorContribution.xxx);
    // #if defined(_COLORIZEMAIN)
    //     lightColor = mainLight.color * mainLight.distanceAttenuation;  
    // #else
    //     lightColor = mainLight.color * atten;
    // #endif
    lightColor = mainLight.color * lerp(atten, mainLight.distanceAttenuation, mainLightAttenContribution);
    luminance = Luminance(mainLight.color); 
    lightIntensity += luminance * atten;

//  Specular
    #if !defined(_SPECULARHIGHLIGHTS_OFF)
        half specularSmoothness;
        half3 spec;
        half specularUpper;
        specularSmoothness = exp2(10 * smoothness + 1);
        specularUpper = saturate(specularStep + specularFalloff * (1.0h + smoothness));
        spec = LightingSpecular_Toon(mainLight, NdotL, inputData.normalWS, inputData.viewDirectionWS, specular, specularSmoothness, smoothness, specularStep, specularUpper, energyConservation);
        specularLighting = spec * atten;
    #endif

//  Rim 
    #if defined(_TOONRIM)
        half rim = saturate(1.0h - saturate( dot(inputData.normalWS, inputData.viewDirectionWS)) );
        //rimLighting = smoothstep(rimPower, rimPower + rimFalloff, rim) * rimColor.rgb;
    //  Stabilize rim
        float delta = fwidth(rim);
        rimLighting = smoothstep(toonRimPower - delta, toonRimPower + toonRimFallOff + delta, rim) * toonRimColor.rgb;
    #endif

//  Additional lights
    #ifdef _ADDITIONAL_LIGHTS
        int pixelLightCount = GetAdditionalLightsCount();
        for (uint i = 0u; i < pixelLightCount; ++i) {
            Light light = GetAdditionalLight(i, inputData.positionWS);
            #if defined(_SCREEN_SPACE_OCCLUSION)
                #if defined(_SSAO_ENABLED)
                    light.color *= aoFactor.directAmbientOcclusion;
                #endif
            #endif
            //light.shadowAttenuation = smoothstep(0.0h, shadowFalloff, light.shadowAttenuation);
            light.shadowAttenuation = smoothstep( (1.0h - shadowFalloff) * shadowFalloff, shadowFalloff, light.shadowAttenuation);
            
            NdotL = dot(inputData.normalWS, light.direction);
            NdotL = saturate((NdotL + 1.0h) - diffuseStep);
            #if !defined(_RAMP_SMOOTHSAMPLING) && !defined(_RAMP_POINTSAMPLING)
                half quantizedNdotL = floor(NdotL * steps);
            //  IMPORTANT: no saturate on the 2nd param: NdotL - 0.01. 0.01 is eyballed.
                NdotL = (quantizedNdotL + aaStep(saturate(quantizedNdotL * oneOverSteps), NdotL - 0.01h, diffuseFalloff )) * oneOverSteps;
            #else
                #if defined(_RAMP_SMOOTHSAMPLING)
                    NdotL = SAMPLE_TEXTURE2D(_GradientMap, s_linear_clamp_sampler, float2 (NdotL, 0.5f)).r;
                #else
                    half NdotL0 = SAMPLE_TEXTURE2D(_GradientMap, s_point_clamp_sampler, float2 (NdotL, 0.5f)).r;
                    half NdotL1 = SAMPLE_TEXTURE2D(_GradientMap, s_point_clamp_sampler, float2 (NdotL + fwidth(NdotL) * _GradientMap_TexelSize.x, 0.5f)).r;
                    NdotL = (NdotL0 + NdotL1) * 0.5h;
                #endif
            #endif

        //  No smoothstep here! as is totally fucks up the distanceAttenuation: It is not linear!
            //half distanceAttenuation = smoothstep(0, addLightFalloff, light.distanceAttenuation);
            half distanceAttenuation = (addLightFalloff < 1.0h) ? saturate(light.distanceAttenuation / addLightFalloff) : light.distanceAttenuation;
            atten = NdotL * distanceAttenuation * saturate(shadowBiasAdditional + light.shadowAttenuation);
            light.color = lerp(Luminance(light.color).xxx, light.color, lightColorContribution.xxx);
            // #if defined(_COLORIZEADD)
            //     lightColor += light.color * light.distanceAttenuation;
            // #else
            //     lightColor += light.color * atten;
            // #endif
            lightColor += light.color * lerp(atten, distanceAttenuation, addLightAttenContribution);
            luminance = Luminance(light.color);
            lightIntensity += luminance * atten;
            #if !defined(_SPECULARHIGHLIGHTS_OFF)
                spec = LightingSpecular_Toon(light, NdotL, inputData.normalWS, inputData.viewDirectionWS, specular, specularSmoothness, smoothness, specularStep, specularUpper, energyConservation);
                specularLighting += spec * atten;
            #endif
        }
    #endif


//  Combine Lighting
    half3 litAlbedo = lerp(shadedAlbedo, albedo, saturate(lightIntensity.xxx) );

//lightColor = 1;

    half3 Lighting =
    //  ambient diffuse lighting
        GI
        //inputData.bakedGI * albedo //litAlbedo
    //  direct diffuse lighting
        + litAlbedo * lightColor
    //  spec lighting    
        #if !defined(_SPECULARHIGHLIGHTS_OFF)
            + (specularLighting * lightIntensity * lightColor)
        #endif
    //  rim lighting 
        #if defined(_TOONRIM)
            + rimLighting * lerp(1.0h, lightIntensity, toonRimAttenuation)
        #endif
    //  old version multiplied rim with lightColor ...
        //#if !defined(_SPECULARHIGHLIGHTS_OFF)
        //    ) 
        //#endif
        //    * lightColor
    ;

#ifdef _ADDITIONAL_LIGHTS_VERTEX
        Lighting += inputData.vertexLighting * albedo;
#endif
    Lighting += emission;

//return half4(lightIntensity.xxx, alpha);
//return half4(inputData.normalWS * 0.5 + 0.5, 1);

    return half4(Lighting, alpha);
}
#endif