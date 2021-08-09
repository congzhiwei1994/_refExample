#ifndef __SCENE_OBJECT_CORE_HLSL__
#define __SCENE_OBJECT_CORE_HLSL__

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

// ����ɫ
uniform half3 g_FogColor = half3(1.00, 0.96078, 0.9098);

// ������ɫ
uniform half4 g_FogOfWarColor = half4(0.00, 0.168, 0.298, 0.619);

// ��Ļ����
uniform half g_SceneIllum = 1.0;

// ͸���ȱ���
uniform half g_AlphaMult = 1.0;

// ������ͼ
TEXTURE2D(_FOWMap);
SAMPLER(sampler_FOWMap);

struct Attributes
{
	float4 positionOS : POSITION;
	float2 uv : TEXCOORD0;

	UNITY_VERTEX_INPUT_INSTANCE_ID
};

// ����������Ϣ
// ����ֵ��xy��ʾ������ͼuv z��ʾ�����볡������Ը߶�
float3 CalcFogOfWarInfo(in float3 positionWS)
{
	// ս��������С��߶�
	float3 SceneParameter = float3(1280.0, 1280.0, 135.0);

	// �����볡�������������߶�
	float dx = 0.5 + (positionWS.x / SceneParameter.x);
	float dz = 0.5 + (positionWS.z / SceneParameter.y);
	float dy = 1.0 - clamp(positionWS.y / SceneParameter.z, 0.0, 1.0);
	return float3(dx, dz, dy);
}

// ��������
half3 MixFogOfWarColor(in half3 color, in half3 info)
{
	half4 FogOfWarColor = half4(0.00, 0.168, 0.298, 0.619);

	half4 mapColor = SAMPLE_TEXTURE2D(_FOWMap, sampler_FOWMap, info.xy);
	half mask = (1.0 - mapColor.r) + 0.5;
	mask = saturate(mask * mask - 0.5);
	mask *= FogOfWarColor.w;

	// ������ɫ
	half3 tempColor = lerp(color, FogOfWarColor.rgb, info.z * 0.82499999); // lerp(0.64999998, 1.0, 0.5) = 0.82499999

	// ��������mask�����������ɫ
	return lerp(color, tempColor, mask);
}

// ����ɫ
inline half3 MultFogColor(in half3 color)
{
	half3 FogColor = half3(1.00, 0.96078, 0.9098);
	return color * FogColor;
}

// ��Ļ����
inline half3 MultSceneIllum(in half3 color)
{
	return color; // * g_SceneIllum
}

inline half MultAlpha(in half alpha)
{
	return alpha; // * g_AlphaMult
}

#endif
