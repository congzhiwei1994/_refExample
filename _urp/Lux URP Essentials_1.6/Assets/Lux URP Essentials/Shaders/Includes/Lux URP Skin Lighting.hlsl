// NOTE: Based on URP Lighting.hlsl which replaced some half3 with floats to avoid lighting artifacts on mobile


#ifndef LIGHTWEIGHT_SKINLIGHTING_INCLUDED
#define LIGHTWEIGHT_SKINLIGHTING_INCLUDED


TEXTURE2D(_SkinLUT); SAMPLER(sampler_SkinLUT); float4 _SkinLUT_TexelSize;


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

    half3 color = specularTerm * brdfData.specular; // + brdfData.diffuse;
    return color;
#else
    return 0; //brdfData.diffuse;
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


half3 LightingPhysicallyBasedSkin(BRDFData brdfData, half3 lightColor, half3 lightDirectionWS, half lightAttenuation, half3 normalWS, half3 viewDirectionWS, half NdotL, half NdotLUnclamped, half curvature, half skinMask)
{
    //half3 radiance = lightColor * NdotL;
    half3 diffuseLighting = brdfData.diffuse * SAMPLE_TEXTURE2D_LOD(_SkinLUT, sampler_SkinLUT, float2( (NdotLUnclamped * 0.5 + 0.5), curvature), 0).rgb;
    diffuseLighting = lerp(brdfData.diffuse * NdotL, diffuseLighting, skinMask);
    return ( DirectBDRF_Lux(brdfData, normalWS, lightDirectionWS, viewDirectionWS) * NdotL + diffuseLighting ) * lightColor * lightAttenuation;
}

half3 LightingPhysicallyBasedSkin(BRDFData brdfData, Light light, half3 normalWS, half3 viewDirectionWS, half NdotL, half NdotLUnclamped, half curvature, half skinMask)
{
    return LightingPhysicallyBasedSkin(brdfData, light.color, light.direction, light.distanceAttenuation * light.shadowAttenuation, normalWS, viewDirectionWS, NdotL, NdotLUnclamped, curvature, skinMask);
}


half4 LuxLWRPSkinFragmentPBR(InputData inputData, half3 albedo, half metallic, half3 specular,
    half smoothness, half occlusion, half3 emission, half alpha, half4 translucency, half AmbientReflection, half3 diffuseNormalWS, half3 subsurfaceColor, half curvature, half skinMask, half maskbyshadowstrength, half backScatter)
{
    
    // #if defined(SHADOWS_SHADOWMASK) && defined(LIGHTMAP_ON)
    //     half4 shadowMask = inputData.shadowMask;
    // #elif !defined (LIGHTMAP_ON)
    //     half4 shadowMask = unity_ProbesOcclusion;
    // #else
    //     half4 shadowMask = half4(1, 1, 1, 1);
    // #endif

    half4 shadowMask = half4(1, 1, 1, 1);   

    BRDFData brdfData;
    InitializeBRDFData(albedo, metallic, specular, smoothness, alpha, brdfData);

    Light mainLight = GetMainLight(inputData.shadowCoord);
    half3 mainLightColor = mainLight.color;
//  SSAO
    #if defined(_SCREEN_SPACE_OCCLUSION)
        AmbientOcclusionFactor aoFactor = GetScreenSpaceAmbientOcclusion(inputData.normalizedScreenSpaceUV);
        mainLight.color *= aoFactor.directAmbientOcclusion;
        occlusion = min(occlusion, aoFactor.indirectAmbientOcclusion);
    #endif

    MixRealtimeAndBakedGI(mainLight, inputData.normalWS, inputData.bakedGI, half4(0, 0, 0, 0));

    half3 color = GlobalIllumination_Lux(brdfData, inputData.bakedGI, occlusion, inputData.normalWS, inputData.viewDirectionWS,     AmbientReflection);

//	Backscattering
	#if defined(_BACKSCATTER)
    	color += backScatter * SampleSH(-diffuseNormalWS) * albedo * occlusion * translucency.x * subsurfaceColor * skinMask;
    #endif

    half NdotLUnclamped = dot(diffuseNormalWS, mainLight.direction);
    half NdotL = saturate( dot(inputData.normalWS, mainLight.direction) );
    color += LightingPhysicallyBasedSkin(brdfData, mainLight, inputData.normalWS, inputData.viewDirectionWS, NdotL, NdotLUnclamped, curvature, skinMask);

//  Subsurface Scattering
    half transPower = translucency.y;
    half3 transLightDir = mainLight.direction + inputData.normalWS * translucency.w;
    half transDot = dot( transLightDir, -inputData.viewDirectionWS );
    transDot = exp2(saturate(transDot) * transPower - transPower);
    color += skinMask * subsurfaceColor * transDot * (1.0 - saturate(NdotLUnclamped)) * mainLightColor * lerp(1.0h, mainLight.shadowAttenuation, translucency.z) * translucency.x;


    #ifdef _ADDITIONAL_LIGHTS
        int pixelLightCount = GetAdditionalLightsCount();
        for (int i = 0; i < pixelLightCount; ++i)
        {
            //Light light = GetAdditionalLight(i, inputData.positionWS);
        //  Get index upfront as we need it for GetAdditionalLightShadowParams();
            int index = GetPerObjectLightIndex(i);
            // Light light = GetAdditionalPerObjectLight(index, inputData.positionWS); // here; shadowAttenuation = 1.0;
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

            half NdotLUnclamped = dot(diffuseNormalWS, light.direction);
            NdotL = saturate( dot(inputData.normalWS, light.direction) );
            color += LightingPhysicallyBasedSkin(brdfData, light, inputData.normalWS, inputData.viewDirectionWS, NdotL, NdotLUnclamped, curvature, skinMask);
        
        //  Subsurface Scattering
            half4 shadowParams = GetAdditionalLightShadowParams(index);
            light.color *= lerp(1, shadowParams.x, maskbyshadowstrength); // shadowParams.x == shadow strength, which is 0 for point lights

            transLightDir = light.direction + inputData.normalWS * translucency.w;
            transDot = dot( transLightDir, -inputData.viewDirectionWS );
            transDot = exp2(saturate(transDot) * transPower - transPower);
            color += skinMask * subsurfaceColor * transDot * (1.0 - NdotL) * lightColor * lerp(1.0h, light.shadowAttenuation, translucency.z) * light.distanceAttenuation * translucency.x;
        }
    #endif
    #ifdef _ADDITIONAL_LIGHTS_VERTEX
        color += inputData.vertexLighting * brdfData.diffuse;
    #endif
    color += emission;

    return half4(color, alpha);
}

#endif