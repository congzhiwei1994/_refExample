//阴影采样相关库
#ifndef CUSTOM_SHADOWS_INCLUDED
#define CUSTOM_SHADOWS_INCLUDED

#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Shadow/ShadowSamplingTent.hlsl"
//如果使用的是PCF 3X3
#if defined(_DIRECTIONAL_PCF3)
//需要4个过滤器样本
#define DIRECTIONAL_FILTER_SAMPLES 4
#define DIRECTIONAL_FILTER_SETUP SampleShadow_ComputeSamples_Tent_3x3
#elif defined(_DIRECTIONAL_PCF5)
#define DIRECTIONAL_FILTER_SAMPLES 9
#define DIRECTIONAL_FILTER_SETUP SampleShadow_ComputeSamples_Tent_5x5
#elif defined(_DIRECTIONAL_PCF7)
#define DIRECTIONAL_FILTER_SAMPLES 16
#define DIRECTIONAL_FILTER_SETUP SampleShadow_ComputeSamples_Tent_7x7
#endif

#define MAX_SHADOWED_DIRECTIONAL_LIGHT_COUNT 4
#define MAX_CASCADE_COUNT 4
//阴影图集
TEXTURE2D_SHADOW(_DirectionalShadowAtlas);

#define SHADOW_SAMPLER sampler_linear_clamp_compare
SAMPLER_CMP(SHADOW_SAMPLER);

CBUFFER_START(_CustomShadows)
//级联数量和包围球数据
int _CascadeCount;
float4 _CascadeCullingSpheres[MAX_CASCADE_COUNT];
//级联数据
float4 _CascadeData[MAX_CASCADE_COUNT];
//阴影转换矩阵
float4x4 _DirectionalShadowMatrices[MAX_SHADOWED_DIRECTIONAL_LIGHT_COUNT * MAX_CASCADE_COUNT];
//阴影过渡距离
float4 _ShadowDistanceFade;
//图集大小
float4 _ShadowAtlasSize;
CBUFFER_END
//定向光阴影的数据信息
struct DirectionalShadowData {
	float strength;
	int tileIndex;
	//法线偏差
	float normalBias;
};
//阴影数据
struct ShadowData {
	int cascadeIndex;
	//是否采样阴影的标识
	float strength;
	//混合级联
	float cascadeBlend;
};
//采样阴影图集
float SampleDirectionalShadowAtlas(float3 positionSTS) {
	return SAMPLE_TEXTURE2D_SHADOW(_DirectionalShadowAtlas, SHADOW_SAMPLER, positionSTS);
}
//PCF滤波采样定向光阴影
float FilterDirectionalShadow(float3 positionSTS) {
#if defined(DIRECTIONAL_FILTER_SETUP)
	//样本权重
	float weights[DIRECTIONAL_FILTER_SAMPLES];
	//样本位置
	float2 positions[DIRECTIONAL_FILTER_SAMPLES];
	float4 size = _ShadowAtlasSize.yyxx;
	DIRECTIONAL_FILTER_SETUP(size, positionSTS.xy, weights, positions);
	float shadow = 0;
	for (int i = 0; i < DIRECTIONAL_FILTER_SAMPLES; i++) {
		//遍历所有样本滤波得到权重和
		shadow += weights[i] * SampleDirectionalShadowAtlas(
			float3(positions[i].xy, positionSTS.z)
		);
	}
	return shadow;
#else
	return SampleDirectionalShadowAtlas(positionSTS);
#endif
}
//得到级联阴影强度
float GetDirectionalShadowAttenuation(DirectionalShadowData directional, ShadowData global, Surface surfaceWS) {
	//如果材质没有定义接受阴影的宏
#if !defined(_RECEIVE_SHADOWS)
	return 1.0;
#endif
	if (directional.strength <= 0.0) {
		return 1.0;
	}
	//计算法线偏移
	float3 normalBias = surfaceWS.normal * (directional.normalBias * _CascadeData[global.cascadeIndex].y);
	//通过阴影转换矩阵和表面位置得到在阴影纹理(图块)空间的位置，然后对图集进行采样 
	float3 positionSTS = mul(_DirectionalShadowMatrices[directional.tileIndex], float4(surfaceWS.position + normalBias, 1.0)).xyz;
	float shadow = FilterDirectionalShadow(positionSTS);
	//如果级联混合小于1代表在级联层级过渡区域中，必须从下一个级联中采样并在两个值之间进行插值
	if (global.cascadeBlend < 1.0) {
		normalBias = surfaceWS.normal *(directional.normalBias * _CascadeData[global.cascadeIndex + 1].y);
		positionSTS = mul(_DirectionalShadowMatrices[directional.tileIndex + 1],float4(surfaceWS.position + normalBias, 1.0)).xyz;
		shadow = lerp(FilterDirectionalShadow(positionSTS), shadow, global.cascadeBlend);
	}

	//最终衰减结果是阴影强度和采样衰减的线性差值
	return lerp(1.0, shadow, directional.strength);
}
//公式计算阴影过渡时的强度
float FadedShadowStrength (float distance, float scale, float fade) {
	return saturate((1.0 - distance * scale) * fade);
}

//得到世界空间的表面阴影数据
ShadowData GetShadowData (Surface surfaceWS) {
	ShadowData data;
	data.cascadeBlend = 1.0;
	data.strength =FadedShadowStrength(surfaceWS.depth, _ShadowDistanceFade.x, _ShadowDistanceFade.y);
	int i;
	//如果物体表面到球心的平方距离小于球体半径的平方，就说明该物体在这层级联包围球中，得到合适的级联层级索引
	for (i = 0; i < _CascadeCount; i++) {
		float4 sphere = _CascadeCullingSpheres[i];
		float distanceSqr = DistanceSquared(surfaceWS.position, sphere.xyz);
		if (distanceSqr < sphere.w) {
			//计算级联阴影的过渡强度，叠加到阴影强度上作为最终阴影强度
			float fade = FadedShadowStrength(distanceSqr, _CascadeData[i].x, _ShadowDistanceFade.z);
			//如果物体在最后一层级联中
			if (i == _CascadeCount - 1) {
				data.strength *= fade;
			}
			else {
				data.cascadeBlend = fade;
			}
			break;
		
		}
	}
	//如果超出级联层数，不进行阴影采样
	if (i == _CascadeCount) {
		data.strength = 0.0;
	}
#if defined(_CASCADE_BLEND_DITHER)
	else if (data.cascadeBlend < surfaceWS.dither) {
		i += 1;
	}
#endif
#if !defined(_CASCADE_BLEND_SOFT)
	data.cascadeBlend = 1.0;
#endif
	data.cascadeIndex = i;
	return data;
}


#endif