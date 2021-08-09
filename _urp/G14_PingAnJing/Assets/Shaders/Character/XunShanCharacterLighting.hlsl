#ifndef XUNSHAN_CHARACTER_LIGHTING_INCLUDED
    #define XUNSHAN_CHARACTER_LIGHTING_INCLUDED
    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"  

    // struct HairInputData
    // {
        //     half4 aniMap
        //     half3 aniNormalWS;
    // };


    real3 UnpackNormalRG_Custom(real2 packedNormal, real z)
    {
        real3 normal;
        // （-1，1）
        normal.xy = packedNormal.rg * 2.0 - 1.0;
        normal.z = z;
        return normal;
    }

    real3 TransformTangentToWorld_Scale(real3 dirTS, real scale, real3x3 tangentToWorld)
    {
        // Note matrix is in row major convention with left multiplication as it is build on the fly
        dirTS.xy *= scale;
        return TransformTangentToWorld(dirTS, tangentToWorld);
    }


    // GPU Gems1 - 16 次表面散射的实时近似（Real-Time Approximations to Subsurface Scattering）
    half WrapDiffuse(half NoL, half wrap)
    {
        // 原实现:
        return max(0.0, (NoL + wrap) / (1 + wrap));
        //return max(0.0, NoL + wrap) / (1 + wrap);
    }

    // Tuned to match behavior of Vis_Smith
    // [Schlick 1994, "An Inexpensive BRDF Model for Physically-Based Rendering"]
    float My_Vis_Schlick(float a, float NDotV, float NoL)
    {
        //float k = sqrt(a2) * 0.5;
        float k = a;

        float Vis_SchlickV = NDotV * (1 - k) + k;
        float Vis_SchlickL = NoL * (1 - k) + k;
        return 0.25 / (Vis_SchlickV * Vis_SchlickL);
    }

    
    //---------------------------------------------------------------------------------
    //---------------------------------------------------------------------------------
    
    inline void InitializeBRDFData1(half3 albedo, half metallic, half3 specular, half smoothness, half alpha, out BRDFData outBRDFData)
    {

        half oneMinusReflectivity = OneMinusReflectivityMetallic(metallic);
        half reflectivity = 1.0 - oneMinusReflectivity;
        outBRDFData.diffuse = albedo * oneMinusReflectivity;
        outBRDFData.specular = lerp(kDieletricSpec.rgb, albedo, metallic);
        outBRDFData.grazingTerm = saturate(smoothness + reflectivity);
        outBRDFData.perceptualRoughness = PerceptualSmoothnessToPerceptualRoughness(smoothness);
        outBRDFData.roughness = max(PerceptualRoughnessToRoughness(outBRDFData.perceptualRoughness), HALF_MIN);
        outBRDFData.roughness2 = outBRDFData.roughness * outBRDFData.roughness;
        outBRDFData.normalizationTerm = outBRDFData.roughness * 4.0h + 2.0h;
        outBRDFData.roughness2MinusOne = outBRDFData.roughness2 - 1.0h;
        #ifdef _ALPHAPREMULTIPLY_ON
            outBRDFData.diffuse *= alpha;
            alpha = alpha * oneMinusReflectivity + reflectivity;
        #endif
    }


    struct SubsurfaceInputDate
    {
        half sssMask;
        half sssFactor;
        half3 sssColor;
        half3 shadowColor;
        half environmentBrightness;
    };


    //-----------------------------------------------------------------


    float3 EnvironmentBRDFApprox(float roughness, float NDotV, float3 f0)
    {
        float4 c0 = float4(-1.0, -0.0275, -0.572, 0.022);
        float4 c1 = float4(1.0, 0.0425, 1.04, -0.04);

        float4 r = roughness * c0 + c1;
        float a004 = min(r.x * r.x, exp2(-9.28 * NDotV)) * r.x + r.y;
        float2 AB = float2(-1.04, 1.04) * a004 + r.zw;

        return f0 * AB.x + AB.y ;
    }


    //---------------------------------------------------------------------------------
    //---------------------------------------------------------------
    half3 GlobalIllumination1(InputData inputData,SubsurfaceInputDate subsurfaceInput, BRDFData brdfData, Light mainLight, half3 bakedGI, half occlusion, half3 normalWS, half3 viewDirectionWS)
    {
        half factor =  subsurfaceInput.sssFactor;
        half3 ShadowColor = subsurfaceInput.shadowColor;
        half Brightness = subsurfaceInput.environmentBrightness;
        half3 V = inputData.viewDirectionWS;
        half shadowAttenuation = mainLight.shadowAttenuation;
        half3 L = mainLight.direction;
        half NDotV = dot(normalWS,V);
        half NDotL = dot(normalWS,L);
        half3 reflectVector = reflect(-viewDirectionWS, normalWS);
        

        float sssDiffuse = WrapDiffuse(NDotL, 0.45); 
        half Factor = lerp(saturate(NDotL), sssDiffuse, subsurfaceInput.sssFactor) * shadowAttenuation;
        half sssNDotL = 1 - lerp(saturate(NDotL), saturate(-NDotL), 0.61);
        half sssNoSL_wrap = WrapDiffuse(sssNDotL, -0.47);
        half3 sssResult = (((sssNoSL_wrap  * Factor *  subsurfaceInput.sssColor) * 2.35) * 0.3);
        half3 sssIndirect = NDotV *  subsurfaceInput.sssColor * Factor;
        half3 indirect = saturate(ShadowColor + sssIndirect);

        half3 diffuse = factor + sssResult;
        half3 diffuseTerm = diffuse * mainLight.color;

        half3 indirectDiffuse = bakedGI * indirect;        // half3 indirectDiffuse = bakedGI * occlusion;
        // 计算Diffuse(直接+间接)
        half3 diffuseTotal =  brdfData.diffuse * (indirectDiffuse + diffuseTerm);


        // 计算间接光的高光
        half3 indirectSpecular = GlossyEnvironmentReflection(reflectVector, brdfData.perceptualRoughness, occlusion);
        half3 indirectSpecularColor = EnvironmentBRDFApprox( brdfData.perceptualRoughness, NDotV,brdfData.specular);
        half3 indirectSpecularTerm = indirectSpecularColor * indirectSpecular * Brightness;
        // 间接高光应用颜色
        indirectSpecularTerm *= ShadowColor;
        indirectSpecularTerm *= lerp(0.6, 1.0, NDotL);      // 间接高光应用NoL(减弱暗部亮度)

        half3 color = indirectSpecularTerm +diffuseTotal;
        return color;
    }


    //---------------------------------------------------------------

    //---------------------------------------------------------------
    half3 XunShanRenderCharacterLighting(BRDFData brdfData, Light light, half3 normalWS, half3 viewDirectionWS)
    {
        half3 lightDirectionWS = light.direction;
        half lightAttenuation = light.distanceAttenuation * light.shadowAttenuation;
        half NDotL = saturate(dot(normalWS, lightDirectionWS));
        // half3 radiance = light.lightColor * (lightAttenuation * NdotL);

        float3 halfDir = SafeNormalize(float3(lightDirectionWS) + float3(viewDirectionWS));
        half VDotH = saturate(dot(viewDirectionWS, halfDir));
        half NDotH = saturate(dot(normalWS, halfDir));
        half NDotV = saturate(dot(normalWS, viewDirectionWS));
        half NDotL_Min = min(saturate(NDotL), light.shadowAttenuation);

        half3 F = F_Schlick(brdfData.specular, VDotH);
        half D = D_GGX(brdfData.roughness2, NDotH);
        half Vis = My_Vis_Schlick( brdfData.normalizationTerm, NDotV, NDotL);

        half3 specularTerm = D * Vis * F;
        specularTerm *= NDotL_Min;

        return specularTerm;

    }
    //---------------------------------------------------------------------------------

    half4 UniversalFragmentPBR1(
    SubsurfaceInputDate subsurfaceInput,
    InputData inputData,
    half3 albedo, 
    half metallic, 
    half3 specular,
    half smoothness, 
    half occlusion, 
    half3 emission,
    half alpha)
    {
        BRDFData brdfData;
        InitializeBRDFData1(albedo, metallic, specular, smoothness, alpha, brdfData);
        
        Light mainLight = GetMainLight(inputData.shadowCoord);
        MixRealtimeAndBakedGI(mainLight, inputData.normalWS, inputData.bakedGI, half4(0, 0, 0, 0));

    
        half3 color = GlobalIllumination1(inputData,subsurfaceInput, brdfData, mainLight, inputData.bakedGI, occlusion, inputData.normalWS, inputData.viewDirectionWS);
        color += XunShanRenderCharacterLighting(brdfData, mainLight, inputData.normalWS, inputData.viewDirectionWS);

        #ifdef _ADDITIONAL_LIGHTS
            uint pixelLightCount = GetAdditionalLightsCount();
            for (uint lightIndex = 0u; lightIndex < pixelLightCount; ++lightIndex)
            {
                Light light = GetAdditionalLight(lightIndex, inputData.positionWS);
                color += LightingPhysicallyBased(brdfData, light, inputData.normalWS, inputData.viewDirectionWS);
            }
        #endif

        #ifdef _ADDITIONAL_LIGHTS_VERTEX
            color += inputData.vertexLighting * brdfData.diffuse;
        #endif

        color += emission;
        return half4(color, alpha);
    }

#endif 