#ifndef CHARACTER_CORE_INCLUDED
#define CHARACTER_CORE_INCLUDED

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"



struct Attributes
{
	float4 positionOS   : POSITION;
	float2 uv           : TEXCOORD0;

	UNITY_VERTEX_INPUT_INSTANCE_ID
};

struct Varyings
{
	float4 positionCS               : SV_POSITION;
	float2 uv                       : TEXCOORD0;
};

TEXTURE2D(_BaseMap);
SAMPLER(sampler_BaseMap);


CBUFFER_START(UnityPerMaterial)
half _AlphaMtl;
half _Hero_Alpha_Random;
half _Support_Hero_Alpha;
half3 _Change_Color;
half _DiscardAmount;
half4 _PickColor;
CBUFFER_END


Varyings LitPassVertex(Attributes input)
{
	Varyings output;
	VertexPositionInputs vertexInput = GetVertexPositionInputs(input.positionOS.xyz);

	output.uv = input.uv;
	output.positionCS = vertexInput.positionCS;

	return output;
}


half4 LitPassFragment(Varyings input) : SV_Target
{
	// ÌùÍ¼²ÉÑù
	half4 baseCol = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, input.uv.xy);

	clip(baseCol.a - _DiscardAmount);

	half3 color = baseCol.rgb * _Change_Color.rgb;
	half alpha = baseCol.a * _AlphaMtl;
	alpha = lerp(alpha, _Hero_Alpha_Random, lerp(step(1.0, alpha), step(1.0, _AlphaMtl), _Support_Hero_Alpha));

	half4 finalColor = half4(color, alpha);
	finalColor *= _PickColor;
	return finalColor;
}

#endif