#define HalfMin 6.103515625e-5

SamplerComparisonState sampler_LinearClampCompare;
SamplerState shadowSampler_LinearClamp;

texture2D<half> KWS_DirLightShadowMap0;
float4 KWS_DirLightShadowMap0_TexelSize;

TextureCube<half> KWS_PointLightShadowMap0;
TextureCube<half> KWS_PointLightShadowMap1;
TextureCube<half> KWS_PointLightShadowMap2;
TextureCube<half> KWS_PointLightShadowMap3;

Texture2D<half> KWS_SpotLightShadowMap0;
Texture2D<half> KWS_SpotLightShadowMap1;
Texture2D<half> KWS_SpotLightShadowMap2;
Texture2D<half> KWS_SpotLightShadowMap3;

struct LightData
{
    float4 color;
    float range;

    float3 forward;
    float3 position;
    float4 attenuation; //KWS_VolumetricLightings_StandardPass -> GetPointLightAttenuation
};

struct ShadowLightData
{
    float4 color;
    float range;

    float3 forward;
    float3 position;
    float4 attenuation; //KWS_VolumetricLightings_StandardPass -> GetPointLightAttenuation

    int shadowIndex;
    float4x4 worldToShadow; //used only for spot lights
    float4 projectionParams;  // for point light projection: x = zfar / (znear - zfar), y = (znear * zfar) / (znear - zfar), z=shadow bias, w=shadow scale bias
    float shadowStrength;
};

struct DirLightShadowParams
{
    float4x4 worldToShadow[4];
    float4 shadowSplitSpheres[4];
    float4 shadowSplitSqRadii;
};

StructuredBuffer<LightData> KWS_PointLightsBuffer;
StructuredBuffer<LightData> KWS_SpotLightsBuffer;

StructuredBuffer<ShadowLightData> KWS_DirLightsBuffer;
StructuredBuffer<ShadowLightData> KWS_ShadowPointLightsBuffer;
StructuredBuffer<ShadowLightData> KWS_ShadowSpotLightsBuffer;

StructuredBuffer<DirLightShadowParams> KWS_DirLightShadowParams;

uint KWS_DirLightsCount;
uint KWS_PointLightsCount;
uint KWS_SpotLightsCount;
uint KWS_ShadowPointLightsCount;
uint KWS_ShadowSpotLightsCount;


inline float SamplePointShadowMap1(float3 coord, float dist)
{
    return KWS_PointLightShadowMap0.SampleCmpLevelZero(sampler_LinearClampCompare, coord, dist);
}

inline float SampleSpotShadowMap1(float3 coord)
{
    return KWS_SpotLightShadowMap0.SampleCmpLevelZero(sampler_LinearClampCompare, coord.xy, coord.z);
}

inline float SamplePointShadowMap4(uint shadowIdx, float3 coord, float dist)
{
    UNITY_BRANCH switch (shadowIdx)
    {
        case 0: return KWS_PointLightShadowMap0.SampleCmpLevelZero(sampler_LinearClampCompare, coord, dist);
        case 1: return KWS_PointLightShadowMap1.SampleCmpLevelZero(sampler_LinearClampCompare, coord, dist);
        case 2: return KWS_PointLightShadowMap2.SampleCmpLevelZero(sampler_LinearClampCompare, coord, dist);
        case 3: return KWS_PointLightShadowMap3.SampleCmpLevelZero(sampler_LinearClampCompare, coord, dist);
        default: return 0;
    }
}

inline float SampleSpotShadowMap4(uint shadowIdx, float3 coord)
{
    UNITY_BRANCH switch (shadowIdx)
    {
        case 0: return KWS_SpotLightShadowMap0.SampleCmpLevelZero(sampler_LinearClampCompare, coord.xy, coord.z);
        case 1: return KWS_SpotLightShadowMap1.SampleCmpLevelZero(sampler_LinearClampCompare, coord.xy, coord.z);
        case 2: return KWS_SpotLightShadowMap2.SampleCmpLevelZero(sampler_LinearClampCompare, coord.xy, coord.z);
        case 3: return KWS_SpotLightShadowMap3.SampleCmpLevelZero(sampler_LinearClampCompare, coord.xy, coord.z);
        default: return 0;
    }
}

#if defined (KWS_USE_DIR_LIGHT_SPLIT) || defined(KWS_USE_DIR_LIGHT_SINGLE_SPLIT)
#define GET_CASCADE_WEIGHTS(lightIndex, wpos)    GetCascadeWeights_SplitSpheres(lightIndex, wpos)
#else
#define GET_CASCADE_WEIGHTS(lightIndex, wpos)    getCascadeWeights(wpos)
#endif

#if defined(KWS_USE_DIR_LIGHT_SINGLE) || defined(KWS_USE_DIR_LIGHT_SINGLE_SPLIT)
#define GET_SHADOW_COORDINATES(lightIndex, wpos,cascadeWeights) getShadowCoord_SingleCascade(lightIndex, wpos)
#else
#define GET_SHADOW_COORDINATES(lightIndex, wpos,cascadeWeights) getShadowCoord(lightIndex, wpos, cascadeWeights)
#endif

#if defined(KWS_USE_SOFT_SHADOWS)
#define SampleDirShadowMap(coord)   SampleDirShadowMapPCF(coord)

#else
#define SampleDirShadowMap(coord)   SampleDirShadowMapSingle(coord)
#endif

float GetViewPosZ(float3 worldPos)
{
#if  defined (KWS_USE_DIR_LIGHT_SPLIT) || defined(KWS_USE_DIR_LIGHT_SINGLE_SPLIT)
    return 0;
#else 
    return mul(unity_WorldToCamera, float4(worldPos, 1)).z;
#endif
}

inline float4 GetCascadeWeights_SplitSpheres(uint lightIndex, float3 wpos)
{
    DirLightShadowParams shadowParams = KWS_DirLightShadowParams[lightIndex];
	float3 fromCenter0 = wpos.xyz - shadowParams.shadowSplitSpheres[0].xyz;
	float3 fromCenter1 = wpos.xyz - shadowParams.shadowSplitSpheres[1].xyz;
	float3 fromCenter2 = wpos.xyz - shadowParams.shadowSplitSpheres[2].xyz;
	float3 fromCenter3 = wpos.xyz - shadowParams.shadowSplitSpheres[3].xyz;
	float4 distances2 = float4(dot(fromCenter0, fromCenter0), dot(fromCenter1, fromCenter1), dot(fromCenter2, fromCenter2), dot(fromCenter3, fromCenter3));

	fixed4 weights = float4(distances2 < shadowParams.shadowSplitSqRadii);
	weights.yzw = saturate(weights.yzw - weights.xyz);

	return weights;
}

inline float4 getCascadeWeights(float3 wpos)
{
    float z = GetViewPosZ(wpos);
    half4 zNear = float4(z >= _LightSplitsNear);
    half4 zFar = float4(z < _LightSplitsFar);
    half4 weights = zNear * zFar;

	return weights;
}

inline float3 getShadowCoord_SingleCascade(uint lightIndex, float4 wpos)
{
    DirLightShadowParams shadowParams = KWS_DirLightShadowParams[0];
	return mul(shadowParams.worldToShadow[0], wpos).xyz;
}


inline float3 getShadowCoord(uint lightIndex, float4 wpos, half4 cascadeWeights) 
{
    DirLightShadowParams shadowParams = KWS_DirLightShadowParams[lightIndex];

	float3 sc0 = mul(shadowParams.worldToShadow[0], wpos).xyz;
	float3 sc1 = mul(shadowParams.worldToShadow[1], wpos).xyz;
	float3 sc2 = mul(shadowParams.worldToShadow[2], wpos).xyz;
	float3 sc3 = mul(shadowParams.worldToShadow[3], wpos).xyz;
	float4 shadowMapCoordinate = float4(sc0 * cascadeWeights[0] + sc1 * cascadeWeights[1] + sc2 * cascadeWeights[2] + sc3 * cascadeWeights[3], 1);
#if defined(UNITY_REVERSED_Z)
	float  noCascadeWeights = 1 - dot(cascadeWeights, float4(1, 1, 1, 1));
	shadowMapCoordinate.z += noCascadeWeights;
#endif
	return shadowMapCoordinate;
}

inline half SampleDirShadowMapSingle(float3 coord)
{
    return KWS_DirLightShadowMap0.SampleCmpLevelZero(sampler_LinearClampCompare, coord.xy, coord.z).x;
}

inline half SampleDirShadowMapPCF(float3 coord)
{
    half shadow1 = KWS_DirLightShadowMap0.SampleCmpLevelZero(sampler_LinearClampCompare, coord.xy + float2(-KWS_DirLightShadowMap0_TexelSize.x, 0), coord.z).x;
    half shadow2 = KWS_DirLightShadowMap0.SampleCmpLevelZero(sampler_LinearClampCompare, coord.xy + float2(KWS_DirLightShadowMap0_TexelSize.x, 0), coord.z).x;
    half shadow3 = KWS_DirLightShadowMap0.SampleCmpLevelZero(sampler_LinearClampCompare, coord.xy + float2(0, -KWS_DirLightShadowMap0_TexelSize.y), coord.z).x;
    half shadow4 = KWS_DirLightShadowMap0.SampleCmpLevelZero(sampler_LinearClampCompare, coord.xy + float2(0, KWS_DirLightShadowMap0_TexelSize.y), coord.z).x;
    return (shadow1 + shadow2 + shadow3 + shadow4) * 0.25;
}


inline half4 DirLightRealtimeShadow(uint lightIndex, float3 worldPos)
{
    ShadowLightData dirLight = KWS_DirLightsBuffer[lightIndex];

    float4 weights = GET_CASCADE_WEIGHTS(lightIndex, worldPos);
	float3 samplePos = GET_SHADOW_COORDINATES(lightIndex, float4(worldPos, 1), weights);

	half inside = dot(weights, float4(1, 1, 1, 1));
    half atten = inside > 0 ? SampleDirShadowMap(samplePos) : 1.0f;
    
	atten = (1 - dirLight.shadowStrength) + atten * dirLight.shadowStrength;
  
   // atten = SampleDirShadowMap(samplerState, samplePos);
    return atten;
}

inline float DistanceAttenuation(float distanceSqr, float range)
{
    //urp version
    /*float lightAtten = rcp(distanceSqr);
    * 
    //half factor = distanceSqr * attenuation.x;
    //half smoothFactor = saturate(1.0h - factor * factor);
    //smoothFactor = smoothFactor * smoothFactor;

    //return lightAtten * smoothFactor;*/

    float lightRange = rcp(range * range);
    float atten = distanceSqr * lightRange;
    atten = rcp(1.0 + 25.0 * atten) * saturate((1.0 - atten) * 2.0);
    return atten;
}



inline half AngleAttenuation(half3 spotDirection, half3 lightDirection, half2 spotAttenuation)
{
    // urp version
    // Spot Attenuation with a linear falloff can be defined as
    // (SdotL - cosOuterAngle) / (cosInnerAngle - cosOuterAngle)
    // This can be rewritten as
    // invAngleRange = 1.0 / (cosInnerAngle - cosOuterAngle)
    // SdotL * invAngleRange + (-cosOuterAngle * invAngleRange)
    // SdotL * spotAttenuation.x + spotAttenuation.y

    half SdotL = dot(spotDirection, lightDirection);
    half atten = saturate(SdotL * spotAttenuation.x + spotAttenuation.y);
    return atten * atten;
}

inline half SamplePointShadow(float3 vec, ShadowLightData light)
{
    float3 absVec = abs(vec);
    float dominantAxis = max(max(absVec.x, absVec.y), absVec.z); 
    dominantAxis = max(0.00001, dominantAxis - light.projectionParams.z); // shadow bias from point light is apllied here.
    dominantAxis *= light.projectionParams.w; // bias
    float mydist = -light.projectionParams.x + light.projectionParams.y / dominantAxis; // project to shadow map clip space [0; 1]
    
    #if defined(UNITY_REVERSED_Z)
    				mydist = 1.0 - mydist; // depth buffers are reversed! Additionally we can move this to CPP code!
    #endif

    half shadow = SamplePointShadowMap4(light.shadowIndex, vec, mydist);

    return lerp(1 - light.shadowStrength, 1.0, shadow);
}

inline half PointLightAttenuation(uint lightIndex, float3 worldPos)
{
    LightData light = KWS_PointLightsBuffer[lightIndex];

    float3 lightVector = worldPos - light.position.xyz;
    float distanceSqr = max(dot(lightVector, lightVector), HalfMin);
    half attenuation = DistanceAttenuation(distanceSqr, light.range);
   
    return attenuation;
}

inline half PointLightAttenuationShadow(uint lightIndex, float3 worldPos)
{
    ShadowLightData light = KWS_ShadowPointLightsBuffer[lightIndex];

    float3 lightVector = worldPos - light.position.xyz;
    float distanceSqr = max(dot(lightVector, lightVector), HalfMin);

    half attenuation = DistanceAttenuation(distanceSqr, light.range);

#if !defined(KWS_DISABLE_POINT_SPOT_SHADOWS)
    attenuation *= SamplePointShadow(lightVector, light);
#endif

    return attenuation;
}

inline half SpotLightAttenuation(uint lightIndex, float3 worldPos)
{
    LightData light = KWS_SpotLightsBuffer[lightIndex];

    float3 lightVector = worldPos - light.position.xyz;
    float distanceSqr = max(dot(lightVector, lightVector), HalfMin);
    half3 lightDirection = half3(lightVector * rsqrt(distanceSqr));
 	half3 lightDir = normalize(lightVector);
 
    half attenuation = DistanceAttenuation(distanceSqr, light.range) * AngleAttenuation(-light.forward.xyz, lightDirection, light.attenuation.zw);
    return attenuation;
}

inline half SpotLightAttenuationShadow(uint lightIndex, float3 worldPos)
{
    ShadowLightData light = KWS_ShadowSpotLightsBuffer[lightIndex];

    float4 lightPos = mul(light.worldToShadow, float4(worldPos, 1));
    float3 lightVector = worldPos - light.position.xyz;
    float distanceSqr = max(dot(lightVector, lightVector), HalfMin);
    half3 lightDirection = half3(lightVector * rsqrt(distanceSqr));
    half3 lightDir = normalize(lightVector);

    half attenuation = DistanceAttenuation(distanceSqr, light.range) * AngleAttenuation(-light.forward.xyz, lightDirection, light.attenuation.zw);

#if !defined(KWS_DISABLE_POINT_SPOT_SHADOWS)
    attenuation *= SampleSpotShadowMap4(light.shadowIndex, lightPos.xyz / lightPos.w);
#endif

    return attenuation;
}

