struct v2fDepth
{
	float4 pos : SV_POSITION;
	float3 normal : NORMAL;
	float4 worldPos_LocalHeight : TEXCOORD0;
	float2 surfaceMask : COLOR0;
};

struct v2fWater
{
	float4 pos : SV_POSITION;
	float3 normal : NORMAL;
	float2 surfaceMask : COLOR0;

	float3 worldPos : TEXCOORD0;
	float3 worldPosRefracted : TEXCOORD1;
	float4 screenPos : TEXCOORD2;
	#if USE_SHORELINE
		float4 shorelineUVAnim1 : TEXCOORD3;
		float4 shorelineUVAnim2 : TEXCOORD4;
		float4 shorelineWaveData1 : TEXCOORD5;
		float4 shorelineWaveData2 : TEXCOORD6;
	#endif
};


float3 ComputeWaterOffset(float3 worldPos)
{
	float2 uv = worldPos.xz / KW_FFTDomainSize;
	float3 offset = 0;
	#if defined(USE_FILTERING) || defined(USE_CAUSTIC_FILTERING)
		float3 disp = Texture2DSampleLevelBicubic(KW_DispTex, sampler_linear_repeat, uv, KW_DispTex_TexelSize, 0).xyz;
	#else
		float3 disp = KW_DispTex.SampleLevel(sampler_linear_repeat, uv, 0).xyz;
	#endif

	#if defined(KW_FLOW_MAP) || defined(KW_FLOW_MAP_EDIT_MODE)
		float2 flowMapUV = (worldPos.xz - KW_FlowMapOffset.xz) / KW_FlowMapSize + 0.5;
		float2 flowmap = KW_FlowMapTex.SampleLevel(sampler_linear_clamp, flowMapUV, 0) * 2 - 1;
		disp = ComputeDisplaceUsingFlowMap(KW_DispTex, sampler_linear_repeat, flowmap, disp, uv, KW_Time * KW_FlowMapSpeed);
	#endif

	#if KW_DYNAMIC_WAVES
		float2 dynamicWavesUV = (worldPos.xz - KW_DynamicWavesWorldPos.xz) / KW_DynamicWavesAreaSize + 0.5;
		float dynamicWave = KW_DynamicWaves.SampleLevel(sampler_linear_clamp, dynamicWavesUV, 0).x;
		disp.y -= dynamicWave * 0.15;
	#endif

	#if defined(KW_FLOW_MAP_FLUIDS) && !defined(KW_FLOW_MAP_EDIT_MODE)
		float2 fluidsUV_lod0 = (worldPos.xz - KW_FluidsMapWorldPosition_lod0.xz) / KW_FluidsMapAreaSize_lod0 + 0.5;
		float2 fluids_lod0 = KW_Fluids_Lod0.SampleLevel(sampler_linear_clamp,  fluidsUV_lod0, 0).xy;

		float2 fluidsUV_lod1 = (worldPos.xz - KW_FluidsMapWorldPosition_lod1.xz) / KW_FluidsMapAreaSize_lod1 + 0.5;
		float2 fluids_lod1 = KW_Fluids_Lod1.SampleLevel(sampler_linear_clamp, fluidsUV_lod1, 0).xy;

		float2 maskUV_lod0 = 1 - saturate(abs(fluidsUV_lod0 * 2 - 1));
		float lodLevelFluidMask_lod0 = saturate((maskUV_lod0.x * maskUV_lod0.y - 0.01) * 3);
		float2 maskUV_lod1 = 1 - saturate(abs(fluidsUV_lod0 * 2 - 1));
		float lodLevelFluidMask_lod1 = saturate((maskUV_lod1.x * maskUV_lod1.y - 0.01) * 3);

		float2 fluids = lerp(fluids_lod1, fluids_lod0, lodLevelFluidMask_lod0);
		fluids *= lodLevelFluidMask_lod1;
		disp = ComputeDisplaceUsingFlowMap(KW_DispTex, sampler_linear_repeat, fluids * KW_FluidsVelocityAreaScale * 0.75, disp, uv, KW_Time * KW_FlowMapSpeed).xyz;
	#endif

	#ifdef USE_MULTIPLE_SIMULATIONS
		disp += KW_DispTex_LOD1.SampleLevel(sampler_linear_repeat, worldPos.xz / KW_FFTDomainSize_LOD1, 0).xyz;
		disp += KW_DispTex_LOD2.SampleLevel(sampler_linear_repeat, worldPos.xz / KW_FFTDomainSize_LOD2, 0).xyz;
	#endif
	offset += disp;

	return offset;
}

v2fDepth vertDepth(float4 vertex : POSITION, float3 normal : NORMAL, float2 surfaceMask : COLOR0)
{
	v2fDepth o = (v2fDepth)0;
	o.worldPos_LocalHeight.xyz = LocalToWorldPos(vertex.xyz);
	
	o.normal = normal;
	o.surfaceMask = surfaceMask;
	
	if (surfaceMask.y > 0.001)
	{
		float3 waterOffset = ComputeWaterOffset(o.worldPos_LocalHeight.xyz);
		if(surfaceMask.y < 0.51) waterOffset.xz *= 0;

		#if USE_SHORELINE
			ComputeShorelineOffset(o.worldPos_LocalHeight.xyz, waterOffset, vertex);
		#else
			vertex.xyz += WorldToLocalPosWithoutTranslation(waterOffset);
		#endif
	}
	o.worldPos_LocalHeight.w = vertex.y + 1.0;
	o.pos = ObjectToClipPos(vertex);
	return o;
}

v2fWater ComputeVertexInterpolators(v2fWater o, float3 worldPos, float4 vertex : POSITION)
{
	o.pos = ObjectToClipPos(vertex);
	o.screenPos = ComputeScreenPos(o.pos);

	return o;
}

v2fWater vert(float4 vertex : POSITION, float3 normal : NORMAL, float2 surfaceMask : COLOR0)
{
	v2fWater o = (v2fWater)0;
	o.worldPos = LocalToWorldPos(vertex.xyz);

	o.normal = normal;
	o.surfaceMask = surfaceMask;

	if (surfaceMask.y > 0.001)
	{
		float3 waterOffset = ComputeWaterOffset(o.worldPos);
		if(surfaceMask.y < 0.51) waterOffset.xz *= 0;

		#if USE_SHORELINE
			ShorelineData shorelineData = ComputeShorelineOffset(o.worldPos, waterOffset, vertex);
			o.shorelineUVAnim1 = shorelineData.uv1;
			o.shorelineUVAnim2 = shorelineData.uv2;
			o.shorelineWaveData1 = shorelineData.data1;
			o.shorelineWaveData2 = shorelineData.data2;
		#else
			vertex.xyz += WorldToLocalPosWithoutTranslation(waterOffset);
		#endif
	}

	o.worldPosRefracted = LocalToWorldPos(vertex.xyz);
	o = ComputeVertexInterpolators(o, o.worldPos.xyz, vertex);
	
	return o;
}