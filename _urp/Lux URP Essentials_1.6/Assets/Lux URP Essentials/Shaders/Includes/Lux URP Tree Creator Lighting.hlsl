#ifndef LIGHTWEIGHT_TREE_INCLUDED
#define LIGHTWEIGHT_TREE_INCLUDED


// Bark lighting

inline half3 LightingTreeBark (Light light, half3 albedo, half3 specular, half gloss, half squashAmount, half3 normal, half3 viewDir)
{
    float3 halfDir = SafeNormalize(light.direction + viewDir);
    half NoL = saturate( dot (normal, light.direction) );
    float NoH = saturate( dot (normal, halfDir) );
    float spec = pow (NoH, specular.r * 128.0f) * gloss;
    
    half3 c;
    half3 lighting = light.color * light.distanceAttenuation * light.shadowAttenuation * squashAmount;
    // c = albedo * lighting * NoL + lighting * specular * spec;
    c = (albedo + specular * spec) * NoL * lighting;
    return c;
}

half4 LuxLWRPTreeBarkFragment (InputData inputData, half3 albedo, half3 specular,
    half smoothness, half occlusion, half alpha, half squashAmount
)
{

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
        AmbientOcclusionFactor aoFactor = GetScreenSpaceAmbientOcclusion(inputData.normalizedScreenSpaceUV);
        mainLight.color *= aoFactor.directAmbientOcclusion;
        occlusion = min(occlusion, aoFactor.indirectAmbientOcclusion);
    #endif

    //MixRealtimeAndBakedGI(mainLight, inputData.normalWS, inputData.bakedGI, half4(0, 0, 0, 0));

    half3 color = albedo * inputData.bakedGI * occlusion;
    color += LightingTreeBark(mainLight, albedo, specular, smoothness, 1.0h, inputData.normalWS, inputData.viewDirectionWS);

    #ifdef _ADDITIONAL_LIGHTS
        int pixelLightCount = GetAdditionalLightsCount();
        for (int i = 0; i < pixelLightCount; ++i)
        {
            // Light light = GetAdditionalLight(i, inputData.positionWS);
        //  URP 10: We have to use the new GetAdditionalLight function
            Light light = GetAdditionalLight(i, inputData.positionWS, shadowMask);
            #if defined(_SCREEN_SPACE_OCCLUSION)
                light.color *= aoFactor.directAmbientOcclusion;
            #endif
            color += LightingTreeBark(light, albedo, specular, smoothness, squashAmount, inputData.normalWS, inputData.viewDirectionWS);
        }
    #endif

    #ifdef _ADDITIONAL_LIGHTS_VERTEX
        color += inputData.vertexLighting * albedo;
    #endif
    
    return half4(color, alpha);
}



// Leaf lighting

inline half3 LightingTreeLeaf(Light light, half3 albedo, half3 specular, half gloss, half2 translucency, half3 translucencyColor, half squashAmount, half3 normal, half3 viewDir)
{
    float3 halfDir = SafeNormalize(light.direction + viewDir);
    half NoL = dot(normal, light.direction);
    float NoH = saturate( dot (normal, halfDir) );
    float spec = pow(NoH, specular.r * 128.0f) * gloss;
    
    // view dependent back contribution for translucency
    half backContrib = saturate(dot(viewDir, -light.direction));
    // normally translucency is more like -nl, but looks better when it's view dependent
    backContrib = lerp(saturate(-NoL), backContrib, translucency.y);
    translucencyColor *= backContrib * translucency.x;
    // wrap-around diffuse
    NoL = saturate (NoL * 0.6h + 0.4h);
    
    half3 c;
    /////@TODO: what is is this multiply 2x here???
    c = albedo * (translucencyColor * 2 + NoL);
//  No lighting on spec?!
    // c = c * light.color * light.distanceAttenuation * light.shadowAttenuation * squashAmount + spec;
    half3 lighting = light.color * light.distanceAttenuation * light.shadowAttenuation * squashAmount;
    c = (c + spec) * lighting;
    
    return c;
}


half4 LuxLWRPTreeLeafFragmentPBR(InputData inputData, half3 albedo, half3 specular,
    half smoothness, half occlusion, half alpha, half2 translucency, half3 translucencyColor, half squashAmount, half shadowStrength
)
{
    

//  ShadowMask: To ensure backward compatibility we have to avoid using shadowMask input, as it is not present in older shaders
    #if defined(SHADOWS_SHADOWMASK) && defined(LIGHTMAP_ON)
        half4 shadowMask = inputData.shadowMask;
    #elif !defined (LIGHTMAP_ON)
        half4 shadowMask = unity_ProbesOcclusion;
    #else
        half4 shadowMask = half4(1, 1, 1, 1);
    #endif

    //Light mainLight = GetMainLight(inputData.shadowCoord);
    //MixRealtimeAndBakedGI(mainLight, inputData.normalWS, inputData.bakedGI, half4(0, 0, 0, 0));
    Light mainLight = GetMainLight(inputData.shadowCoord, inputData.positionWS, shadowMask);

//  SSAO
    #if defined(_SCREEN_SPACE_OCCLUSION)
        AmbientOcclusionFactor aoFactor = GetScreenSpaceAmbientOcclusion(inputData.normalizedScreenSpaceUV);
        mainLight.color *= aoFactor.directAmbientOcclusion;
        occlusion = min(occlusion, aoFactor.indirectAmbientOcclusion);
    #endif

    mainLight.shadowAttenuation = lerp(1.0h, mainLight.shadowAttenuation, shadowStrength * squashAmount /* fade out */);

    half3 color = albedo * inputData.bakedGI * occlusion;
    color += LightingTreeLeaf(mainLight, albedo, specular, smoothness, translucency, translucencyColor, 1, inputData.normalWS, inputData.viewDirectionWS);

    #ifdef _ADDITIONAL_LIGHTS
        int pixelLightCount = GetAdditionalLightsCount();
        for (int i = 0; i < pixelLightCount; ++i)
        {
            Light light = GetAdditionalLight(i, inputData.positionWS);
            color += LightingTreeLeaf(light, albedo, specular, smoothness, translucency, translucencyColor, squashAmount, inputData.normalWS, inputData.viewDirectionWS);
        }
    #endif

    #ifdef _ADDITIONAL_LIGHTS_VERTEX
        color += inputData.vertexLighting * albedo;
    #endif
    
    return half4(color, alpha);
}

#endif