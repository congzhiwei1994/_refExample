sampler2D _MainTex, 
_OcclusionMap, 
_SpecGlossMap,
_CavityMap,
_TransmissionMap,
_ProfileTex,
_SubsurfaceAlbedo,
_BumpMap, 
_DetailNormalMap,
LightingTexBlurred, 
LightingTexBlurredR,
SSS_TransparencyTex,
SSS_TransparencyTexR,
SSS_TransparencyTexBlurred,
SSS_TransparencyTexBlurredR,
_TintTexture
;

half _Glossiness,
_AlbedoTile,
_ChromaticAberration,
//refractiveIndex,
//_IrisCaustics,
_OcclusionStrength,
_BumpTile,
_BumpScale,
_DetailNormalMapScale,
_DetailNormalMapTile,
SSS_shader,
_AlbedoOpacity,
_SubSurfaceParallax,
_SubsurfaceAlbedoOpacity,
_SubsurfaceAlbedoSaturation,
DynamicPassTransmission,
BasePassTransmission,
TransmissionShadows,
TransmissionOcc,
_CavityStrength,
TransmissionRange,
_FresnelIntensity,		
TransparencyAlphaTweak,
TransparencyDistortion;		
float4 _Color,_TransmissionColor, _OcclusionColor, _TintColor;
float4 //_SubsurfaceColor, 
_ProfileColor,
LightingTexBlurred_ST
;
int _DetailNormal;
#if defined (__INTELLISENSE__)
    #define ENABLE_DETAIL_NORMALMAP
	#define WRAPPED_LIGHTING

    #endif
float3 BumpMap(float2 uv)
{
    float4 BaseNormalSample = tex2D(_BumpMap, uv * _BumpTile);
    float3 BaseNormal = UnpackScaleNormal(BaseNormalSample, _BumpScale);
    #ifdef ENABLE_DETAIL_NORMALMAP
    float4 DetailNormalSample = tex2D(_DetailNormalMap, uv * _DetailNormalMapTile);
    float3 DetailNormal = UnpackScaleNormal(DetailNormalSample, _DetailNormalMapScale);
     

    return BlendNormals(BaseNormal, DetailNormal);
    #else
    return BaseNormal;
    #endif
}

float Pow2(half x)
{
    return x * x;
}

float3 Snell(float3 I, float3 N, float IOR)
{
    float c = max(0, dot(N, I));
    float k = 1.0 - Pow2(IOR) * (1.0 - Pow2(c));
	//
    return k < 0 ? 0 : IOR * I + (IOR * c) - sqrt(k) * N;
	/*
		float NdotI = dot(N, I);
		float k = 1.0 - IOR * IOR * (1.0 - Pow2(NdotI));
		k = abs(k);
		return IOR * I - N * (IOR * NdotI + sqrt(k));*/
}

float Jimenez_SpecularOcclusion(float NdotV, float AO)
{
	float sAO = saturate(-0.3f + NdotV * NdotV);
	return lerp(pow(AO, 8.00f), 1.0f, sAO);
}

float3 WrappedDiffuse(half NdotL, half _Wrap)
{
	return saturate((NdotL + _Wrap) / ((1 + _Wrap) * (1 + _Wrap)));
}

float3 TransmissionDynamic(float3 color, float3 L, float3 N, float3 E, float NdotL, fixed atten)
{    
    color = 1.0 - exp(-color);
    half blV = saturate (dot(-E, (L + N))) * 2;
    half bnL = saturate (dot(N, -L ) * TransmissionRange + TransmissionRange);
    //bnL = bnL * (NdotL/* * 0.5 + 0.5*/);
    
    half3 light = bnL + blV;
    half3 Subsurface = color * light * 10;
    Subsurface /= 1.0 -  color;
	Subsurface = 1.0 - exp(-Subsurface);						
	Subsurface = Subsurface * light * lerp(1.0, atten, TransmissionShadows) * 10 * color * DynamicPassTransmission;
    return Subsurface;

}

#define BASE_TRANSMISSION \
fixed3 t = tex2D(_TransmissionMap, uv).rgb * lerp(1.0, Occlusion, TransmissionOcc) * _TransmissionColor.rgb;\
o.Transmission = t;\
Emission += t * ShadeSH9(float4(WorldNormalVector (IN, -o.Normal), 1.0)) * BasePassTransmission;\

#define BASE_TRANSMISSION_SCENE \
fixed3 t = tex2D(_TransmissionMap, uv).rgb * lerp(1.0, Occlusion, TransmissionOcc) * _TransmissionColor.rgb;\
o.Transmission = t;\
Emission += Albedo * t * ShadeSH9(float4(WorldNormalVector (IN, -o.Normal), 1.0)) * BasePassTransmission;\

#define BASE_TRANSMISSION_DEFERRED \
fixed3 t = tex2D(_TransmissionMap, uv).rgb * lerp(1.0, Occlusion, TransmissionOcc) * _TransmissionColor.rgb;\
/*o.Transmission = t;*/\
Emission += t * ShadeSH9(float4(WorldNormalVector (IN, -o.Normal), 1.0)) * BasePassTransmission;\

#define ADDITIVE_PASS_TRANSMISSION TransmissionDynamic(s.Transmission, lightDir, s.Normal, viewDir, NdotL, atten) * _LightColor0.rgb;
#define ADDITIVE_PASS_TRANSMISSION_SCENE TransmissionDynamic(s.Transmission, lightDir, s.Normal, viewDir, NdotL, atten) * _LightColor0.rgb * s.Albedo;

#define SSS_OCCLUSION \
half3 Occlusion = tex2D(_OcclusionMap, uv).rgb;\
half3 OcclusionColored = lerp(_OcclusionColor.rgb, 1.0, Occlusion.r);\
o.Occlusion = OcclusionColored;\

#define ALPHA_TEST \
clip(Albedo.a - _Cutoff);\

half _Wrap;

float DiffuseLightingModel(float NdotL)
{
	float diffuse = NdotL;
	
	#ifdef WRAPPED_LIGHTING
	diffuse = WrappedDiffuse(NdotL, _Wrap);
	#endif
	
	return diffuse;
}

sampler2D _ScaleMask;
half _UVscale;
half _Dilation;

half2 UVscale(half2 uv, half scale)
{
    return (uv - 0.5) * scale + 0.5;
}

//#define COMPUTE_EYE_DILATION uv = lerp(uv, UVscale(uv, - _Dilation), tex2D(_ScaleMask, uv).r);
#define COMPUTE_EYE_DILATION \
half2 originalUV = uv;\
uv -= 0.5;\
float pupilRange = 1.0 - tex2D(_ScaleMask, originalUV).r;\
uv.xy *= saturate(lerp(1.0f, pupilRange, _Dilation));\
uv.xy += 0.5f;\

float _Depth, _DepthCenter, _DepthTile;
sampler2D _ParallaxMap;
#define uParallaxDepthOffset float2(- _Depth, _DepthCenter)
#define COMPUTE_PARALLAX uv = SurfaceParallaxMap(normalize(IN.viewDir), uv);

float SampleHeight(half2 c)
{
    return 1 - tex2Dlod(_ParallaxMap, float4(c * _DepthTile, 0, 0)).r;
}

half2 SurfaceParallaxMap(half3 viewDir, half2 uv)
{
		half3 dir = viewDir;
		half2 maxOffset = dir.xy * (uParallaxDepthOffset.x / (abs(dir.z) + 0.001));
	
		float minSamples = 16.0;
		float maxSamples = 128.0;
		float samples = saturate(3.0 * length(maxOffset));
		float incr = rcp(lerp(minSamples, maxSamples, samples));

		half2 tc0 = uv - uParallaxDepthOffset.y * maxOffset;
		float h0 = SampleHeight(tc0);
		float2 finalUV = 0;
		for (float i = incr; i <= 1.0; i += incr)
		{
			half2 tc = tc0 + maxOffset * i;
			float h1 = SampleHeight(tc);
			if (i >= h1)
			{
			//hit! now interpolate
				float r1 = i, r0 = i - incr;
				float t = (h0 - r0) / ((h0 - r0) + (-h1 + r1));
				float r = (r0 - t * r0) + t * r1;
				finalUV = tc0 + r * maxOffset;
				break;
			}
			else
			{
				finalUV = tc0 + maxOffset;
			}
			h0 = h1;
		}
		return finalUV;

	}