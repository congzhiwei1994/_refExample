RWTexture2D<float4> ColorRT;
RWStructuredBuffer<uint> HashRT;

half ComputeUVFade(float2 screenUV)
{
	if ((screenUV.x <= 0 || screenUV.y > 1.0)) return 0;
	float fringeY = 1 - screenUV.y;
	float fringeX = fringeY * (0.5 - abs(screenUV.x - 0.5)) * 300;
	fringeY = fringeY * 7;
	return saturate(fringeY) * saturate(fringeX);
}

///////////////////////////////////////////////////////////////////////////////// kernels ////////////////////////////////////////////////////////////////////////////////////////


[numthreads(NUMTHREAD_X, NUMTHREAD_Y, 1)]
void Clear_kernel(uint3 id : SV_DispatchThreadID)
{
	HashRT[id.y * _RTSize.x + id.x] = MaxUint;
	ColorRT[uint2(id.xy)] = half4(0, 0, 0, 0);
}

[numthreads(NUMTHREAD_X, NUMTHREAD_Y, 1)]
void RenderHash_kernel(uint3 id : SV_DispatchThreadID)
{
	float3 posWS = ScreenToWorldPos(id.xy);

	if (posWS.y <= _HorizontalPlaneHeightWS)
		return;

	float3 reflectPosWS = posWS;

	reflectPosWS.y = -reflectPosWS.y + 2 * _HorizontalPlaneHeightWS;
	float2 reflectUV = WorldToScreenPos(reflectPosWS);

	if (reflectUV.x > 0.999 || reflectUV.x > 0.999 || reflectUV.x < 0.001 || reflectUV.y < 0.001) return;
	uint2 reflectedScreenID = reflectUV * _RTSize.xy;//from screen uv[0,1] to [0,RTSize-1]
	float2 screenUV = id.xy * _RTSize.zw;
	uint hash = id.y << 20 | id.x << 8;

	InterlockedMin(HashRT[reflectedScreenID.y * _RTSize.x + reflectedScreenID.x], hash);
}

[numthreads(NUMTHREAD_X, NUMTHREAD_Y, 1)]
void RenderColorFromHash_kernel(uint3 id : SV_DispatchThreadID)
{
	uint hashIdx = id.y * _RTSize.x + id.x;
	
	uint left = HashRT[hashIdx + 1 + _DepthHolesFillDistance * 0.1].x;
	uint right = HashRT[hashIdx - 1 - _DepthHolesFillDistance * 0.1].x;
	uint down = HashRT[(id.y + 1) * _RTSize.x + id.x].x;
	uint up = HashRT[(id.y - 1 - _DepthHolesFillDistance) * _RTSize.x + id.x].x;

	uint hashData = min(left, min(right, min(up, down)));

	if (hashData == MaxUint)
	{
		ColorRT[id.xy] = 0;
		return;
	}

	uint2 sampleID = uint2((hashData >> 8) & 0xFFF, hashData >> 20);

	float2 sampleUV = sampleID.xy * _RTSize.zw;
	half3 sampledColor = GetCameraColor(sampleUV);

	float fade = ComputeUVFade(sampleUV);
	half4 finalColor = half4(sampledColor, fade);
	ColorRT[id.xy] = finalColor;
}
