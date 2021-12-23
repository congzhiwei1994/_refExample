#ifndef LIGHTWEIGHT_SKINLIGHTING_INCLUDED
#define LIGHTWEIGHT_SKINLIGHTING_INCLUDED

#if !defined(SHADERGRAPH_PREVIEW) || defined(LIGHTWEIGHT_LIGHTING_INCLUDED)

//  As we do not have access to the vertex lights we will make the shader always sample add lights per pixel
    #if defined(_ADDITIONAL_LIGHTS_VERTEX)
        #undef _ADDITIONAL_LIGHTS_VERTEX
        #define _ADDITIONAL_LIGHTS
    #endif
#endif


//TEXTURE2D(_SkinLUT); SAMPLER(sampler_SkinLUT); float4 _SkinLUT_TexelSize;

#if !defined(SHADERGRAPH_PREVIEW) || defined(LIGHTWEIGHT_LIGHTING_INCLUDED)

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
    half fresnelTerm = 0;
    half3 indirectSpecular = 0;
    if(specOccluison > 0) {
        half3 reflectVector = reflect(-viewDirectionWS, normalWS);
        fresnelTerm = Pow4(1.0 - saturate(dot(normalWS, viewDirectionWS)));
        indirectSpecular = GlossyEnvironmentReflection(reflectVector, brdfData.perceptualRoughness, occlusion)        * specOccluison;
    }
    half3 indirectDiffuse = bakedGI * occlusion;
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

#endif
   

void Lighting_half(

//  Base inputs
    half3 positionWS,
    half3 viewDirectionWS,

//  Normal inputs
    half3 normalWS,
    half3 tangentWS,
    half3 bitangentWS,
    bool enableNormalMapping,
    bool enableDiffuseNormalMapping,
    bool enableBackScattering,
    bool useVertexNormal,

//  Surface description
    half3 albedo,
    half metallic,
    half3 specular,
    half smoothness,
    half occlusion,
    half3 emission, 
    half alpha,

    half4 translucency,
    half AmbientReflection,

    half3 subsurfaceColor,
    half curvature,
    half skinMask,
    half maskbyshadowstrength,

    half backScattering,

    Texture2D normalMap,
    SamplerState sampler_Normal,
    float2 UV,
    float bumpScale,
    float diffuseBias,

//  Lightmapping
    float2 lightMapUV,

//  Final lit color
    out half3 MetaAlbedo,
    out half3 FinalLighting,
    out half3 MetaSpecular
)
{

#if defined(SHADERGRAPH_PREVIEW) || ( !defined(LIGHTWEIGHT_LIGHTING_INCLUDED) && !defined(UNIVERSAL_LIGHTING_INCLUDED) )
    FinalLighting = albedo;
    MetaAlbedo = half3(0,0,0);
    MetaSpecular = half3(0,0,0);
#else

    half3 diffuseNormalWS;
    if (enableNormalMapping) {
        half3x3 ToW = half3x3(tangentWS.xyz, bitangentWS.xyz, normalWS.xyz);

        half4 sampleNormal = SAMPLE_TEXTURE2D(normalMap, sampler_Normal, UV);
        half3 normalTS = UnpackNormalScale(sampleNormal, bumpScale);

    //  Get specular normal
        half3 snormalWS = TransformTangentToWorld(normalTS, ToW);
        snormalWS = NormalizeNormalPerPixel(snormalWS);
    //  Get diffuse normal
        if(enableDiffuseNormalMapping) {
            half4 sampleNormalDiffuse = SAMPLE_TEXTURE2D_BIAS(normalMap, sampler_Normal, UV, diffuseBias);
        //  Do not manually unpack the normal map as it might use RGB.
            half3 diffuseNormalTS = UnpackNormal(sampleNormalDiffuse);
        //  Get diffuseNormalWS
            diffuseNormalWS = TransformTangentToWorld(diffuseNormalTS, ToW);
            diffuseNormalWS = NormalizeNormalPerPixel(diffuseNormalWS);
        }
        else {
            diffuseNormalWS = (useVertexNormal) ? normalWS : snormalWS;
        }
    //  Set specular normal
        normalWS = snormalWS;
    }
    else {
       normalWS = NormalizeNormalPerPixel(normalWS);
       diffuseNormalWS = normalWS;
    }

    viewDirectionWS = SafeNormalize(viewDirectionWS);

//  GI Lighting
    half3 bakedGI;
    #ifdef LIGHTMAP_ON
        lightMapUV = lightMapUV * unity_LightmapST.xy + unity_LightmapST.zw;
        bakedGI = SAMPLE_GI(lightMapUV, half3(0,0,0), diffuseNormalWS);
    #else
        bakedGI = SampleSH(diffuseNormalWS); 
    #endif

    BRDFData brdfData;
    InitializeBRDFData(albedo, metallic, specular, smoothness, alpha, brdfData);

    float4 clipPos = TransformWorldToHClip(positionWS);

//  Get Shadow Sampling Coords
    #if SHADOWS_SCREEN
        float4 shadowCoord = ComputeScreenPos(clipPos);
    #else
        float4 shadowCoord = TransformWorldToShadowCoord(positionWS);
    #endif

    Light mainLight = GetMainLight(shadowCoord);
    half3 mainLightColor = mainLight.color;

//  SSAO
    #if defined(_SCREEN_SPACE_OCCLUSION)
        float4 ndc = clipPos * 0.5f;
        float2 normalized = float2(ndc.x, ndc.y * _ProjectionParams.x) + ndc.w;
        normalized /= clipPos.w;
        normalized *= _ScreenParams.xy;
    //  We could also use IN.Screenpos(default) --> ( IN.Screenpos.xy * _ScreenParams.xy)
    //  HDRP 10.1
        normalized = GetNormalizedScreenSpaceUV(normalized);
        AmbientOcclusionFactor aoFactor = GetScreenSpaceAmbientOcclusion(normalized);
        mainLight.color *= aoFactor.directAmbientOcclusion;
        occlusion = min(occlusion, aoFactor.indirectAmbientOcclusion);
    #endif

    FinalLighting = GlobalIllumination_Lux(brdfData, bakedGI, occlusion, normalWS, viewDirectionWS,     AmbientReflection);

//  Backscattering
    if (enableBackScattering) {
        FinalLighting += backScattering * SampleSH(-diffuseNormalWS) * albedo * occlusion * translucency.x * subsurfaceColor * skinMask;
    }

    MixRealtimeAndBakedGI(mainLight, normalWS, bakedGI, half4(0, 0, 0, 0));

    half NdotLUnclamped = dot(diffuseNormalWS, mainLight.direction);
    half NdotL = saturate( dot(normalWS, mainLight.direction) );
    FinalLighting += LightingPhysicallyBasedSkin(brdfData, mainLight, normalWS, viewDirectionWS, NdotL, NdotLUnclamped, curvature, skinMask);

//  Subsurface Scattering
    half transPower = translucency.y;
    half3 transLightDir = mainLight.direction + normalWS * translucency.w;
    half transDot = dot( transLightDir, -viewDirectionWS );
    transDot = exp2(saturate(transDot) * transPower - transPower);
    FinalLighting += skinMask * subsurfaceColor * transDot * (1.0 - saturate(NdotLUnclamped)) * mainLightColor * lerp(1.0h, mainLight.shadowAttenuation, translucency.z) * translucency.x;

//  URP 10
    half4 shadowMask = half4(1, 1, 1, 1); 

    #ifdef _ADDITIONAL_LIGHTS
        int pixelLightCount = GetAdditionalLightsCount();
        for (int i = 0; i < pixelLightCount; ++i)
        {
            //Light light = GetAdditionalLight(i, inputData.positionWS);
        //  Get index upfront as we need it for GetAdditionalLightShadowParams();
            int index = GetPerObjectLightIndex(i);
            // Light light = GetAdditionalPerObjectLight(index, positionWS); // here; shadowAttenuation = 1.0;
        //  URP 10: We have to use the new GetAdditionalLight function
            Light light = GetAdditionalLight(i, positionWS, shadowMask);
            half3 lightColor = light.color;
            #if defined(_SCREEN_SPACE_OCCLUSION)
                light.color *= aoFactor.directAmbientOcclusion;
            #endif

            half NdotLUnclamped = dot(diffuseNormalWS, light.direction);
            NdotL = saturate( dot(normalWS, light.direction) );
            FinalLighting += LightingPhysicallyBasedSkin(brdfData, light, normalWS, viewDirectionWS, NdotL, NdotLUnclamped, curvature, skinMask);

        //  Transmission
            half4 shadowParams = GetAdditionalLightShadowParams(index);
            lightColor *= lerp(1, shadowParams.x, maskbyshadowstrength); // shadowParams.x == shadow strength, which is 0 for point lights
            
            transLightDir = light.direction + normalWS * translucency.w;
            transDot = dot( transLightDir, -viewDirectionWS );
            transDot = exp2(saturate(transDot) * transPower - transPower);
            FinalLighting += skinMask * subsurfaceColor * transDot * (1.0 - NdotL) * lightColor * lerp(1.0h, light.shadowAttenuation, translucency.z) * light.distanceAttenuation * translucency.x;
        }
    #endif
    #ifdef _ADDITIONAL_LIGHTS_VERTEX
//        FinalLighting += inputData.vertexLighting * brdfData.diffuse;
    #endif
    FinalLighting += emission;

//  Set Albedo for meta pass
    #if defined(LIGHTWEIGHT_META_PASS_INCLUDED) || defined(UNIVERSAL_META_PASS_INCLUDED)
        FinalLighting = half3(0,0,0);
        MetaAlbedo = albedo;
        MetaSpecular = specular;
    #else
        MetaAlbedo = half3(0,0,0);
        MetaSpecular = half3(0,0,0);
    #endif

#endif
}

// Unity 2019.1. needs a float version

void Lighting_float(

//  Base inputs
    half3 positionWS,
    half3 viewDirectionWS,

//  Normal inputs
    half3 normalWS,
    half3 tangentWS,
    half3 bitangentWS,
    bool enableNormalMapping,
    bool enableDiffuseNormalMapping,
    bool enableBackScattering,
    bool useVertexNormal,

//  Surface description
    half3 albedo,
    half metallic,
    half3 specular,
    half smoothness,
    half occlusion,
    half3 emission, 
    half alpha,

    half4 translucency,
    half AmbientReflection,

    half3 subsurfaceColor,
    half curvature,
    half skinMask,
    half maskbyshadowstrength,

    half backScattering,

    Texture2D normalMap,
    SamplerState sampler_Normal,
    float2 UV,
    float bumpScale,
    float diffuseBias,

//  Lightmapping
    float2 lightMapUV,

//  Final lit color
    out half3 MetaAlbedo,
    out half3 FinalLighting,
    out half3 MetaSpecular
)
{
    Lighting_half(
        positionWS, viewDirectionWS, normalWS, tangentWS, bitangentWS, enableNormalMapping, enableDiffuseNormalMapping, enableBackScattering, useVertexNormal,
        albedo, metallic, specular, smoothness, occlusion, emission, alpha,
        translucency, AmbientReflection, subsurfaceColor, curvature, skinMask, maskbyshadowstrength,
        backScattering,
        normalMap, sampler_Normal, UV, bumpScale, diffuseBias,
        lightMapUV,
        MetaAlbedo, FinalLighting, MetaSpecular
    );
}


#endif