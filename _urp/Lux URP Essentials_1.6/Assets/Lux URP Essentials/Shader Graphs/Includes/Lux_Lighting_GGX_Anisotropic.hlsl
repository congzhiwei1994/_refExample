#if !defined(SHADERGRAPH_PREVIEW) || defined(LIGHTWEIGHT_LIGHTING_INCLUDED)

//  As we do not have access to the vertex lights we will make the shader always sample add lights per pixel
    #if defined(_ADDITIONAL_LIGHTS_VERTEX)
        #undef _ADDITIONAL_LIGHTS_VERTEX
        #define _ADDITIONAL_LIGHTS
    #endif

    #if defined(LIGHTWEIGHT_LIGHTING_INCLUDED) || defined(UNIVERSAL_LIGHTING_INCLUDED)

        struct AdditionalData {
            half3   tangentWS;
            half3   bitangentWS;
            float   partLambdaV;
            half    roughnessT;
            half    roughnessB;
            half3   anisoReflectionNormal;
        };

        half3 DirectBDRF_LuxGGXAniso(BRDFData brdfData, AdditionalData addData, half3 normalWS, half3 lightDirectionWS, half3 viewDirectionWS, half NdotL)
        {
        #ifndef _SPECULARHIGHLIGHTS_OFF
            float3 halfDir = SafeNormalize(lightDirectionWS + viewDirectionWS);
            float NoH = saturate(dot(normalWS, halfDir));
            half LoH = saturate(dot(lightDirectionWS, halfDir));
            half NdotV = saturate(dot(normalWS, viewDirectionWS ));

        //  GGX Aniso
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
        #else
            return brdfData.diffuse;
        #endif
        }

        half3 LightingPhysicallyBased_LuxGGXAniso(BRDFData brdfData, AdditionalData addData, half3 lightColor, half3 lightDirectionWS, half lightAttenuation, half3 normalWS, half3 viewDirectionWS, half NdotL)
        {
            half3 radiance = lightColor * (lightAttenuation * NdotL);
            return DirectBDRF_LuxGGXAniso(brdfData, addData, normalWS, lightDirectionWS, viewDirectionWS, NdotL) * radiance;
        }

        half3 LightingPhysicallyBased_LuxGGXAniso(BRDFData brdfData, AdditionalData addData, Light light, half3 normalWS, half3 viewDirectionWS, half NdotL)
        {
            return LightingPhysicallyBased_LuxGGXAniso(brdfData, addData, light.color, light.direction, light.distanceAttenuation * light.shadowAttenuation, normalWS, viewDirectionWS, NdotL);
        }

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

//  Lighting specific inputs

    half anisotropy,

    bool enableTransmission,
    half transmissionStrength,
    half transmissionPower,
    half transmissionDistortion,
    half transmissionShadowstrength,

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

//  Do not apply energy conservation
    brdfData.diffuse = albedo;
    brdfData.specular = specular;

    AdditionalData addData;
//  The missing bits - checked with per vertex bitangent and tangent    
    addData.bitangentWS = normalize( -cross(normalWS, tangentWS) ); //bitangentWS;
//  We can get away with a single normalize here
    addData.tangentWS = cross(normalWS, addData.bitangentWS); // tangentWS;

//  GGX Aniso
    addData.roughnessT = brdfData.roughness * (1 + anisotropy);
    addData.roughnessB = brdfData.roughness * (1 - anisotropy);

    float TdotV = dot(addData.tangentWS, viewDirectionWS);
    float BdotV = dot(addData.bitangentWS, viewDirectionWS);
    float NdotV = dot(normalWS, viewDirectionWS);
    addData.partLambdaV = GetSmithJointGGXAnisoPartLambdaV(TdotV, BdotV, NdotV, addData.roughnessT, addData.roughnessB);

//  Set reflection normal and roughness – derived from GetGGXAnisotropicModifiedNormalAndRoughness
    half3 grainDirWS = (anisotropy >= 0.0) ? bitangentWS : tangentWS;
    half stretch = abs(anisotropy) * saturate(1.5h * sqrt(brdfData.perceptualRoughness));
    addData.anisoReflectionNormal = GetAnisotropicModifiedNormal(grainDirWS, normalWS, viewDirectionWS, stretch);
    half iblPerceptualRoughness = brdfData.perceptualRoughness * saturate(1.2 - abs(anisotropy));

//  Overwrite perceptual roughness for ambient specular reflections
    brdfData.perceptualRoughness = iblPerceptualRoughness;

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
    
    MixRealtimeAndBakedGI(mainLight, normalWS, bakedGI, half4(0, 0, 0, 0));

//  GI
    FinalLighting = GlobalIllumination(brdfData, bakedGI, occlusion, addData.anisoReflectionNormal, viewDirectionWS);

//  Main Light
    half NdotL = saturate(dot(normalWS, mainLight.direction));
    FinalLighting += LightingPhysicallyBased_LuxGGXAniso(brdfData, addData, mainLight, normalWS, viewDirectionWS, NdotL);
//  transmission
    if(enableTransmission) {
        half3 transLightDir = mainLight.direction + normalWS * transmissionDistortion;
        half transDot = dot( transLightDir, -viewDirectionWS );
        transDot = exp2(saturate(transDot) * transmissionPower - transmissionPower);
        FinalLighting += brdfData.diffuse * transDot * (1.0 - NdotL) * mainLightColor * lerp(1.0h, mainLight.shadowAttenuation, transmissionShadowstrength) * transmissionStrength * 4;
    }
//  Handle additional lights
    #ifdef _ADDITIONAL_LIGHTS
        int pixelLightCount = GetAdditionalLightsCount();
        for (int i = 0; i < pixelLightCount; ++i) {
            // Light light = GetAdditionalPerObjectLight(index, positionWS); // here; shadowAttenuation = 1.0;
        //  URP 10: We have to use the new GetAdditionalLight function
            Light light = GetAdditionalLight(i, positionWS, shadowMask);
            half3 lightColor = light.color;
            #if defined(_SCREEN_SPACE_OCCLUSION)
                light.color *= aoFactor.directAmbientOcclusion;
            #endif
            NdotL = saturate(dot(normalWS, light.direction ));
            FinalLighting += LightingPhysicallyBased_LuxGGXAniso(brdfData, addData, light, normalWS, viewDirectionWS, NdotL);
        //  transmission
            if(enableTransmission) {
                half3 transLightDir = light.direction + normalWS * transmissionDistortion;
                half transDot = dot( transLightDir, -viewDirectionWS );
                transDot = exp2(saturate(transDot) * transmissionPower - transmissionPower);
                NdotL = saturate(dot(normalWS, light.direction));
                FinalLighting += brdfData.diffuse * transDot * (1.0 - NdotL) * lightColor * lerp(1.0h, light.shadowAttenuation, transmissionShadowstrength) * light.distanceAttenuation * transmissionStrength * 4;
            }
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

//  Lighting specific inputs

    half anisotropy,

    bool enableTransmission,
    half transmissionStrength,
    half transmissionPower,
    half transmissionDistortion,
    half transmissionShadowstrength,

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
        anisotropy, enableTransmission, transmissionStrength, transmissionPower, transmissionDistortion, transmissionShadowstrength,
        lightMapUV, MetaAlbedo, FinalLighting, MetaSpecular);
}