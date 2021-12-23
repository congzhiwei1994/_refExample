#if !defined(SHADERGRAPH_PREVIEW) || defined(LIGHTWEIGHT_LIGHTING_INCLUDED)

//  As we do not have access to the vertex lights we will make the shader always sample add lights per pixel
    #if defined(_ADDITIONAL_LIGHTS_VERTEX)
        #undef _ADDITIONAL_LIGHTS_VERTEX
        #define _ADDITIONAL_LIGHTS
    #endif

    #if defined(LIGHTWEIGHT_LIGHTING_INCLUDED) || defined(UNIVERSAL_LIGHTING_INCLUDED)

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

            bool enableSecondaryLobe;
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
            LoH2 = max(0.1h, LoH2); // as we can reuse it
            half specularTerm = brdfData.roughness2 / ((d * d) * LoH2 /* max(0.1h, LoH2) */ * brdfData.normalizationTerm);
        #if defined (SHADER_API_MOBILE) || defined (SHADER_API_SWITCH)
            specularTerm = specularTerm - HALF_MIN;
            specularTerm = clamp(specularTerm, 0.0, 100.0); // Prevent FP16 overflow on mobiles
        #endif

            half3 spec = specularTerm * brdfData.specular * NdotL;

        //  Coat Lobe

        //  From HDRP: Scale base specular

            //#if defined (_MASKMAP) && defined(_STANDARDLIGHTING)
            //    [branch]
            //    if (addData.coatThickness > 0.0h) {
            //#endif
                    half coatF = F_Schlick(addData.reflectivity /*addData.coatSpecular*/ /*CLEAR_COAT_F0*/, LoH) * addData.coatThickness;
                    spec *= Sq(1.0h - coatF);
                    //spec *= (1.0h - coatF); // as used by filament, na, not really
                    NoH = saturate(dot(addData.normalWS, halfDir));
                    d = NoH * NoH * addData.roughness2MinusOne + 1.00001f;
                    //LoH2 = LoH * LoH; no need to recalculate LoH2!
                    specularTerm = addData.roughness2 / ((d * d) * LoH2 /* max(0.1h, LoH2) */ * addData.normalizationTerm);
                #if defined (SHADER_API_MOBILE) || defined (SHADER_API_SWITCH)
                    specularTerm = specularTerm - HALF_MIN;
                    specularTerm = clamp(specularTerm, 0.0, 100.0); // Prevent FP16 overflow on mobiles
                #endif
                    spec += specularTerm * addData.coatSpecular * saturate(dot(addData.normalWS, lightDirectionWS));
            //#if defined (_MASKMAP) && defined(_STANDARDLIGHTING)
            //    }
            //#endif

            half3 color = spec + brdfData.diffuse * NdotL; // * lerp(1.0h, 1.0h - coatF, addData.coatThickness);
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
            half3 res = EnvironmentBRDF_LuxClearCoat(brdfData, addData, indirectDiffuse, indirectSpecular, fresnelTerm);

            //#if defined(_SECONDARYLOBE)
            if (addData.enableSecondaryLobe) {
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
            //#endif
            }
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
    half3 albedo,           // albedo is baseColor
    half metallic,
    half3 specular,
    half smoothness,
    half occlusion,
    half alpha,

//  Lighting specific inputs
    half clearcoatSmoothness,
    half clearcoatThickness,
    half3 clearcoatSpecular,
    
    half3 secondaryColor,

    bool enableSecondaryColor,
    bool enableSecondaryLobe,

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

//  Cache the geometry normal used by the coat
    half3 vertexNormalWS = NormalizeNormalPerPixel(normalWS);

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

//  Clear Coat Lighting
    
    half NdotV = saturate( dot(vertexNormalWS, viewDirectionWS) );
    #if !defined(LIGHTWEIGHT_META_PASS_INCLUDED) && !defined(UNIVERSAL_META_PASS_INCLUDED)
        if(enableSecondaryColor) {
            albedo = lerp(secondaryColor, albedo, NdotV);
        }
    #endif

    BRDFData brdfData;
    InitializeBRDFData(albedo, metallic, specular, smoothness, alpha, brdfData);

//  Adjust specular as we have a transition from coat to material and not air to material
    brdfData.specular = lerp(brdfData.specular, f0ClearCoatToSurface_Lux(brdfData.specular), clearcoatThickness);


    AdditionalData addData;
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

    addData.enableSecondaryLobe = enableSecondaryLobe;

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

//  Approximation of refraction on BRDF
    half refractionScale = ((NdotV * 0.5 + 0.5) * NdotV - 1.0) * saturate(1.25 - 1.25 * (1.0 - clearcoatSmoothness)) + 1;
    brdfData.diffuse = lerp(brdfData.diffuse, brdfData.diffuse * refractionScale, clearcoatThickness);

//  GI
    FinalLighting = GlobalIllumination_LuxClearCoat(brdfData, addData, bakedGI, occlusion, addData.normalWS, normalWS, viewDirectionWS, NdotV);

//  Main Light
    FinalLighting += LightingPhysicallyBased_LuxClearCoat(brdfData, addData, mainLight, normalWS, viewDirectionWS);

//  Handle additional lights
    #ifdef _ADDITIONAL_LIGHTS
        int pixelLightCount = GetAdditionalLightsCount();
        for (int i = 0; i < pixelLightCount; ++i) {
            // Light light = GetAdditionalPerObjectLight(index, positionWS); // here; shadowAttenuation = 1.0;
        //  URP 10: We have to use the new GetAdditionalLight function
            Light light = GetAdditionalLight(i, positionWS, shadowMask);
            #if defined(_SCREEN_SPACE_OCCLUSION)
                light.color *= aoFactor.directAmbientOcclusion;
            #endif
            FinalLighting += LightingPhysicallyBased_LuxClearCoat(brdfData, addData, light, normalWS, viewDirectionWS);
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
    half clearcoatSmoothness,
    half clearcoatThickness,
    half3 clearcoatSpecular,

    half3 secondaryColor,

    bool enableSecondaryColor,
    bool enableSecondaryLobe,

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
        clearcoatSmoothness, clearcoatThickness, clearcoatSpecular, secondaryColor, enableSecondaryColor, enableSecondaryLobe,
        lightMapUV, MetaAlbedo, FinalLighting, MetaSpecular);
}