// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

#ifndef SeparableSSS_Common

#define SeparableSSS_Common
half dd1o, dd2o, diff1o, diff2o;
half4 nn1o, nn2o, dp1o, dp2o;
float NormalTest, DepthTest, ProfileRadiusTest, ProfileColorTest, DitherIntensity, DitherSpeed, DitherScale;
sampler2D NoiseTexture, LightingTex, LightingTexR, SSS_TransparencyTex, SSS_TransparencyTexR;
float3 Pow2(float3 x)
{ 
return x * x; 
}

float2 SamplePoints(int r, int d)
{
    return float2(cos(r), sin(d));
}


float2 RandN2(float2 pos, float2 random)
{
	return frac(sin(dot(pos.xy + random, float2(12.9898, 78.233))) * float2(43758.5453, 28001.8384));
}
//didn't compile glsl
//inline half CheckSame (half4 n, half4 nn)
//{
//	// difference in normals
//	half2 diff = abs(n.xy - nn.xy);
//	half sn = (diff.x + diff.y) < NormalTest;
//	// difference in depth
//	float z = DecodeFloatRG (n.zw);
//	float zz = DecodeFloatRG (nn.zw);
//	float zdiff = abs(z-zz) ;
//	half sz = zdiff < DepthTest;
//	//return sn;
//	return sn * sz;
//}
float CheckSame (half4 n, half4 nn)
{
	// difference in normals
	float2 diff = abs(n.xy - nn.xy);
    NormalTest = max(.00001, NormalTest);//so that the screen won't turn black
	float sn = (diff.x + diff.y) < NormalTest;
	// difference in depth
	float z = DecodeFloatRG (n.zw);
	float zz = DecodeFloatRG (nn.zw);
	float zdiff = abs(z-zz) ;
    DepthTest = max(.00001, DepthTest);//so that the screen won't turn black
    
	float sz = zdiff < DepthTest;
	//return sn;
	return sn * sz;
}

float ProfileEdge(float4 p, float4 pp)
{
    ProfileColorTest = max(.00001, ProfileColorTest);//so that the screen won't turn black
    ProfileRadiusTest = max(.00001, ProfileRadiusTest);//so that the screen won't turn black

    float colorDiff = saturate(abs(Luminance(pp.rgb) - Luminance(p.rgb))<ProfileColorTest);
    float RadiusDiff =saturate(abs(pp.a - p.a)<ProfileRadiusTest);
    return RadiusDiff * colorDiff;
}

float Edges(float d, float dd, float2 n, float2 nn)
{
    NormalTest = max(.00001, NormalTest);//so that the screen won't turn black
    DepthTest = max(.00001, DepthTest);//so that the screen won't turn black
    
    float zdiff = abs(dd-d)<DepthTest;
    float nyDiff = abs(nn.y-n.y)<NormalTest;
    float nxDiff = abs(nn.x-n.x)<NormalTest;
	return   nxDiff * nyDiff * zdiff;
}

float TransparencyEdges(float d, float dd)
{
    DepthTest = max(.00001, DepthTest);//so that the screen won't turn black
    
    float zdiff = abs(dd-d)<DepthTest;
    
	return zdiff;
}

float Edges2(float d, float dd, float2 n, float2 nn)
{
    NormalTest = max(.00001, NormalTest);//so that the screen won't turn black
    DepthTest = max(.00001, DepthTest);//so that the screen won't turn black
    
    float zdiff = distance(dd,d)<DepthTest-d;
    float nyDiff = distance(nn.y,n.y)<NormalTest;
    float nxDiff = distance(nn.x,n.x)<NormalTest;
	return   nxDiff * nyDiff * zdiff;
}


	float DepthNormalOffsetCorrection(float4 depthSample)
	{
		//_CameraDepthNormalsTexture
		//SSSSS_DepthBuffer
		float3 viewNorm;
		float depth;
		DecodeDepthNormal(depthSample, depth, viewNorm);
		float DistanceCorrection = depth * (_ProjectionParams.z * 0.1f);
		return 1.0f/DistanceCorrection;
	}

	inline half CheckSameDepthNormal(half4 n, half4 nn)
	{
		// difference in normals
		half2 diff = abs(n.xy - nn.xy);
		half sn = (diff.x + diff.y) < NormalTest;
		// difference in depth
		float z = DecodeFloatRG(n.zw);
		float zz = DecodeFloatRG(nn.zw);
		float zdiff = abs(z - zz) * _ProjectionParams.z * 0.001;
		//float zdiff = abs(z - zz) * 0.1;
		half sz = zdiff < DepthTest;
		//return sn;
		return sn * sz;
	}
/*
	float4 SeparableSSS(v2f i, float strength, int kernelIndex)
	{
		float2 o = _TexelOffsetScale.xy;

		o *= strength;

#ifdef DEPTH_TEST_ON
		//_CameraDepthNormalsTexture
		//SSSSS_DepthBuffer
		float4 InputBuffer = tex2D(SSSSS_DepthBuffer, i.uv2);
		float3 viewNorm;
		float depth;
		DecodeDepthNormal(InputBuffer, depth, viewNorm);
		float DistanceCorrection = depth * 100;
		o /= DistanceCorrection;
#endif

		// Accumulate the center sample:
		float4 colorBlurred = tex2D(_MainTex, i.uv2);
		colorBlurred.rgb *= kernel[kernelOffset].rgb;

		// Accumulate the other samples:

		half diff = 1, accumulatedDiff = 0;

		for (int s = 1; s < SSSS_N_SAMPLES; s++)
		{
			int kernelIndex = kernelOffset + s;
			float2 nuv = i.uv2 + kernel[kernelIndex].a * o;

			half4 OffsetBuffer = tex2D(SSSSS_DepthBuffer, nuv);

#ifdef DEPTH_TEST_ON    
			diff = CheckSame(InputBuffer, OffsetBuffer);
#endif
			float2 offset = i.uv2 + kernel[kernelIndex].a * o * diff;

			colorBlurred.rgb += tex2D(_MainTex, offset).rgb * kernel[kernelIndex].rgb;
		}

		return colorBlurred;
	}
*/
#endif