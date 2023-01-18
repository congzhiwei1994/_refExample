float _TesselationMaxDistance;
float _TesselationMaxDisplace;

struct TessellationFactors
{
	float edge[3]    : SV_TessFactor;
	float inside : SV_InsideTessFactor;
};

struct TessellationControlPoint {
	float4 vertex : INTERNALTESSPOS;
	float2 surfaceMask : COLOR0;
	float3 normal : NORMAL;
};

TessellationControlPoint vertHull(float4 vertex : POSITION, float2 surfaceMask : COLOR0, float3 normal : NORMAL)
{
	TessellationControlPoint o;
	o.vertex = vertex;
	o.surfaceMask = surfaceMask;
	o.normal = normal;
	return o;
}


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
float CalcDistanceTessFactor(float4 vertex, float minDist, float maxDist, float tess)
{
	float3 wpos = LocalToWorldPos(vertex.xyz).xyz;
	float dist = distance(wpos, _WorldSpaceCameraPos);
	float f = clamp(1.0 - (dist - minDist) / (maxDist - minDist), 0.01, 1.0) * tess;
	return f;
}

float4 CalcTriEdgeTessFactors(float3 triVertexFactors)
{
	float4 tess;
	tess.x = 0.5 * (triVertexFactors.y + triVertexFactors.z);
	tess.y = 0.5 * (triVertexFactors.x + triVertexFactors.z);
	tess.z = 0.5 * (triVertexFactors.x + triVertexFactors.y);
	tess.w = (triVertexFactors.x + triVertexFactors.y + triVertexFactors.z) / 3.0f;
	return tess;
}


float DistanceToPlane(float3 pos, float4 plane)
{
	float d = dot(float4(pos, 1.0f), plane);
	return d;
}

bool IsTriangleVisible(float3 wpos0, float3 wpos1, float3 wpos2, float cullEps)
{
	float4 planeTest;

	// left
	planeTest.x = ((DistanceToPlane(wpos0, _FrustumCameraPlanes[0]) > -cullEps) ? 1.0f : 0.0f) +
		((DistanceToPlane(wpos1, _FrustumCameraPlanes[0]) > -cullEps) ? 1.0f : 0.0f) +
		((DistanceToPlane(wpos2, _FrustumCameraPlanes[0]) > -cullEps) ? 1.0f : 0.0f);
	// right
	planeTest.y = ((DistanceToPlane(wpos0, _FrustumCameraPlanes[1]) > -cullEps) ? 1.0f : 0.0f) +
		((DistanceToPlane(wpos1, _FrustumCameraPlanes[1]) > -cullEps) ? 1.0f : 0.0f) +
		((DistanceToPlane(wpos2, _FrustumCameraPlanes[1]) > -cullEps) ? 1.0f : 0.0f);
	// top
	planeTest.z = ((DistanceToPlane(wpos0, _FrustumCameraPlanes[2]) > -cullEps) ? 1.0f : 0.0f) +
		((DistanceToPlane(wpos1, _FrustumCameraPlanes[2]) > -cullEps) ? 1.0f : 0.0f) +
		((DistanceToPlane(wpos2, _FrustumCameraPlanes[2]) > -cullEps) ? 1.0f : 0.0f);
	// bottom
	planeTest.w = ((DistanceToPlane(wpos0, _FrustumCameraPlanes[3]) > -cullEps) ? 1.0f : 0.0f) +
		((DistanceToPlane(wpos1, _FrustumCameraPlanes[3]) > -cullEps) ? 1.0f : 0.0f) +
		((DistanceToPlane(wpos2, _FrustumCameraPlanes[3]) > -cullEps) ? 1.0f : 0.0f);

	// has to pass all 4 plane tests to be visible
	return !all(planeTest);
}


float4 DistanceBasedTessCull(float4 v0, float4 v1, float4 v2, float minDist, float maxDist, float tessFactor, float maxDisplace)
{
	float3 pos0 = mul(UNITY_MATRIX_M, v0).xyz;
	float3 pos1 = mul(UNITY_MATRIX_M, v1).xyz;
	float3 pos2 = mul(UNITY_MATRIX_M, v2).xyz;
	float4 tess;


	if (IsTriangleVisible(pos0, pos1, pos2, maxDisplace))
	{
		tess = 0.0f;
	}
	else
	{
		float3 f;
		f.x = CalcDistanceTessFactor(v0, minDist, maxDist, tessFactor);
		f.y = CalcDistanceTessFactor(v1, minDist, maxDist, tessFactor);
		f.z = CalcDistanceTessFactor(v2, minDist, maxDist, tessFactor);
		tess = CalcTriEdgeTessFactors(f);
	}
	return tess;
}

TessellationFactors HSConstant(InputPatch<TessellationControlPoint, 3> patch)
{
	TessellationFactors f;
	half4 factor = DistanceBasedTessCull(patch[0].vertex, patch[1].vertex, patch[2].vertex, 1, _TesselationMaxDistance, _TesselationFactor, _TesselationMaxDisplace);

	f.edge[0] = factor.x;
	f.edge[1] = factor.y;
	f.edge[2] = factor.z;
	f.inside = factor.w;
	return f;
}

[domain("tri")]
[partitioning("pow2")]
[outputtopology("triangle_cw")]
[patchconstantfunc("HSConstant")]
[outputcontrolpoints(3)]
TessellationControlPoint HS(InputPatch<TessellationControlPoint, 3> Input, uint id : SV_OutputControlPointID)
{
	return Input[id];
}

[domain("tri")]
v2fWater DS(TessellationFactors HSConstantData, const OutputPatch<TessellationControlPoint, 3> Input, float3 BarycentricCoords : SV_DomainLocation)
{
	float fU = BarycentricCoords.x;
	float fV = BarycentricCoords.y;
	float fW = BarycentricCoords.z;

	float3 vertex = Input[0].vertex.xyz * fU + Input[1].vertex.xyz * fV + Input[2].vertex.xyz * fW;

#if SHADER_API_METAL
	return vert(float4(vertex, 1), float3(0, 1, 0), float2(1, 1));
#else
	float2 surfaceMask = Input[0].surfaceMask * fU + Input[1].surfaceMask * fV + Input[2].surfaceMask * fW;
	float3 normal = Input[0].normal.xyz * fU + Input[1].normal.xyz * fV + Input[2].normal.xyz * fW;
	return vert(float4(vertex, 1), normal, surfaceMask);
#endif
}

[domain("tri")]
v2fDepth DS_Depth(TessellationFactors HSConstantData, const OutputPatch<TessellationControlPoint, 3> Input, float3 BarycentricCoords : SV_DomainLocation)
{
	float fU = BarycentricCoords.x;
	float fV = BarycentricCoords.y;
	float fW = BarycentricCoords.z;

	float3 vertex = Input[0].vertex.xyz * fU + Input[1].vertex.xyz * fV + Input[2].vertex.xyz * fW;

#if SHADER_API_METAL
	return vertDepth(float4(vertex.xyz, 1), float3(0, 1, 0), float2(1, 1));
#else
	float2 surfaceMask = Input[0].surfaceMask * fU + Input[1].surfaceMask * fV + Input[2].surfaceMask * fW;
	float3 normal = Input[0].normal.xyz * fU + Input[1].normal.xyz * fV + Input[2].normal.xyz * fW;
	return vertDepth(float4(vertex.xyz, 1), normal, surfaceMask);
#endif

}
