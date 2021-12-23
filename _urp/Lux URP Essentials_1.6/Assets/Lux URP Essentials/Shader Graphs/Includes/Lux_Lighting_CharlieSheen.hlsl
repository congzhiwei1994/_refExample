#if !defined(SHADERGRAPH_PREVIEW) || defined(LIGHTWEIGHT_LIGHTING_INCLUDED)

//  As we do not have access to the vertex lights we will make the shader always sample add lights per pixel
    #if defined(_ADDITIONAL_LIGHTS_VERTEX)
        #undef _ADDITIONAL_LIGHTS_VERTEX
        #define _ADDITIONAL_LIGHTS
    #endif

    #if defined(LIGHTWEIGHT_LIGHTING_INCLUDED) || defined(UNIVERSAL_LIGHTING_INCLUDED)

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

        struct AdditionalData {
            half3   sheenColor;
        };

        half3 DirectBDRF_LuxCharlieSheen(BRDFData brdfData, AdditionalData addData, half3 normalWS, half3 lightDirectionWS, half3 viewDirectionWS, half NdotL)
        {
        #ifndef _SPECULARHIGHLIGHTS_OFF
            float3 halfDir = SafeNormalize(lightDirectionWS + viewDirectionWS);
            float NoH = saturate(dot(normalWS, halfDir));
            half LoH = saturate(dot(lightDirectionWS, halfDir));
            half NdotV = saturate(dot(normalWS, viewDirectionWS ));

        //  Charlie Sheen

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
            return brdfData.diffuse;
        #endif
        }

        half3 LightingPhysicallyBased_LuxCharlieSheen(BRDFData brdfData, AdditionalData addData, half3 lightColor, half3 lightDirectionWS, half lightAttenuation, half3 normalWS, half3 viewDirectionWS, half NdotL)
        {
            //half NdotL = saturate(dot(normalWS, lightDirectionWS));
            half3 radiance = lightColor * (lightAttenuation * NdotL);
            return DirectBDRF_LuxCharlieSheen(brdfData, addData, normalWS, lightDirectionWS, viewDirectionWS, NdotL) * radiance;
        }

        half3 LightingPhysicallyBased_LuxCharlieSheen(BRDFData brdfData, AdditionalData addData, Light light, half3 normalWS, half3 viewDirectionWS, half NdotL)
        {
            return LightingPhysicallyBased_LuxCharlieSheen(brdfData, addData, light.color, light.direction, light.distanceAttenuation * light.shadowAttenuation, normalWS, viewDirectionWS, NdotL);
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

    half3 sheenColor,

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
#if defined(SHADERGRAPH_PREVIEW) || ( !defined(LIGHTWEIGHT_LIGHTING_INCLUDED) && !defined(UNIVERSAL_LIGHTING_INCLUDED) )
    FinalLighting = albedo;
    MetaAlbedo = half3(0,0,0);
    MetaSpecular = half3(0,0,0);
#else


//  Real Lighting ----------

//  Charlie Sheen specific:
    smoothness = lerp(0.0h, 0.6h, smoothness);

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
    //addData.tangentWS = tangentWS;
    //addData.bitangentWS = bitangentWS;

//  Charlie Sheen
    //addData.partLambdaV = 0.0h;
    //addData.anisoReflectionNormal = normalWS;
    float NdotV = dot(normalWS, viewDirectionWS);
    addData.sheenColor = sheenColor;

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
    FinalLighting = GlobalIllumination(brdfData, bakedGI, occlusion, normalWS, viewDirectionWS);

//  Main Light
    half NdotL = saturate(dot(normalWS, mainLight.direction));
    FinalLighting += LightingPhysicallyBased_LuxCharlieSheen(brdfData, addData, mainLight, normalWS, viewDirectionWS, NdotL);
//  transmission
    if (enableTransmission) {
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
            FinalLighting += LightingPhysicallyBased_LuxCharlieSheen(brdfData, addData, light, normalWS, viewDirectionWS, NdotL);
        //  transmission
            if (enableTransmission) {
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

    half3 sheenColor,

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
        sheenColor, enableTransmission, transmissionStrength, transmissionPower, transmissionDistortion, transmissionShadowstrength,
        lightMapUV, MetaAlbedo, FinalLighting, MetaSpecular);
}