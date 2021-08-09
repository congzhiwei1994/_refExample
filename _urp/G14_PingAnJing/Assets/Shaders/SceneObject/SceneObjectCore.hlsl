#ifndef __SCENE_OBJECT_CORE_HLSL__
#define __SCENE_OBJECT_CORE_HLSL__

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

// 雾颜色
uniform half3 g_FogColor = half3(1.00, 0.96078, 0.9098);

// 迷雾颜色
uniform half4 g_FogOfWarColor = half4(0.00, 0.168, 0.298, 0.619);

// 屏幕亮度
uniform half g_SceneIllum = 1.0;

// 透明度倍数
uniform half g_AlphaMult = 1.0;

// 迷雾贴图
TEXTURE2D(_FOWMap);
SAMPLER(sampler_FOWMap);

struct Attributes
{
	float4 positionOS : POSITION;
	float2 uv : TEXCOORD0;

	UNITY_VERTEX_INPUT_INSTANCE_ID
};

// 计算迷雾信息
// 返回值：xy表示迷雾贴图uv z表示顶点与场景的相对高度
float3 CalcFogOfWarInfo(in float3 positionWS)
{
	// 战斗场景大小与高度
	float3 SceneParameter = float3(1280.0, 1280.0, 135.0);

	// 顶点与场景的相对坐标与高度
	float dx = 0.5 + (positionWS.x / SceneParameter.x);
	float dz = 0.5 + (positionWS.z / SceneParameter.y);
	float dy = 1.0 - clamp(positionWS.y / SceneParameter.z, 0.0, 1.0);
	return float3(dx, dz, dy);
}

// 处理迷雾
half3 MixFogOfWarColor(in half3 color, in half3 info)
{
	half4 FogOfWarColor = half4(0.00, 0.168, 0.298, 0.619);

	half4 mapColor = SAMPLE_TEXTURE2D(_FOWMap, sampler_FOWMap, info.xy);
	half mask = (1.0 - mapColor.r) + 0.5;
	mask = saturate(mask * mask - 0.5);
	mask *= FogOfWarColor.w;

	// 迷雾颜色
	half3 tempColor = lerp(color, FogOfWarColor.rgb, info.z * 0.82499999); // lerp(0.64999998, 1.0, 0.5) = 0.82499999

	// 根据迷雾mask计算出像素颜色
	return lerp(color, tempColor, mask);
}

// 雾颜色
inline half3 MultFogColor(in half3 color)
{
	half3 FogColor = half3(1.00, 0.96078, 0.9098);
	return color * FogColor;
}

// 屏幕亮度
inline half3 MultSceneIllum(in half3 color)
{
	return color; // * g_SceneIllum
}

inline half MultAlpha(in half alpha)
{
	return alpha; // * g_AlphaMult
}

#endif
