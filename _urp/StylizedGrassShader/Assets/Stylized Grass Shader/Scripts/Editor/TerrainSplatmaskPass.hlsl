//Stylized Grass Shader
//Staggart Creations (http://staggart.xyz)
//Copyright protected under Unity Asset Store EULA

SamplerState sampler_LinearClamp;

//Set through script
TEXTURE2D(_SplatmapRGB);
float4 _SplatmapRGB_TexelSize;
float4 _SplatMask;
float _SplatChannelStrength;

struct FullscreenAttributes
{
	float4 positionOS : POSITION;
	float2 uv         : TEXCOORD0;
};

struct FullscreenVaryings
{
	float4 positionCS : SV_POSITION;
	float2 uv         : TEXCOORD0;
};

FullscreenVaryings FullscreenVert(FullscreenAttributes input)
{
	FullscreenVaryings output;

	output.positionCS = TransformObjectToHClip(input.positionOS.xyz);
	output.uv = input.uv;

	return output;
}

TEXTURE2D_X(_InputColormap);
TEXTURE2D_X(_InputAlphamap);
TEXTURE2D_X(_InputHeightmap);

half4 SplatmapMaskFragment(Varyings IN) : SV_TARGET
{
	float2 splatUV = (IN.uvMainAndLM.xy * (_Control_TexelSize.zw - 1.0f) + 0.5f) * _Control_TexelSize.xy;

	//_Control tex is set by material property block
	float4 splatmap = SAMPLE_TEXTURE2D(_Control, sampler_LinearClamp, splatUV);

	float output = 0;

	if (_SplatMask.r == 1) output = splatmap.r;
	if (_SplatMask.g == 1) output = splatmap.g;
	if (_SplatMask.b == 1) output = splatmap.b;
	if (_SplatMask.a == 1) output = splatmap.a;

	output *= _SplatChannelStrength;
	return half4(float3(output, output, output), 1.0);
}

half4 FragMaxBlend(FullscreenVaryings input) : SV_Target
{
	float alpha = SAMPLE_TEXTURE2D_X(_InputAlphamap, sampler_LinearClamp, input.uv).r;
	float height = SAMPLE_TEXTURE2D_X(_InputHeightmap, sampler_LinearClamp, input.uv).r;

	float result = max(alpha, height);

	return float4(result, result, result, 1);
}

half4 FragFillBlack(FullscreenVaryings input) : SV_Target
{
	float height = SAMPLE_TEXTURE2D_X(_InputHeightmap, sampler_LinearClamp, input.uv).r;

	float mask = height > 0 ? height : 1;
	float result = lerp(height, 1, mask);

	return float4(result, result, result, 1);
}

half4 FragMergeAlpha(FullscreenVaryings input) : SV_Target
{
	half3 color = SAMPLE_TEXTURE2D_X(_InputColormap, sampler_LinearClamp, input.uv).rgb;
	float height = SAMPLE_TEXTURE2D_X(_InputHeightmap, sampler_LinearClamp, input.uv).r;

	return float4(color, height);
}