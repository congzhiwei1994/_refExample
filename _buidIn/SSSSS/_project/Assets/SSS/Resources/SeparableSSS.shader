

Shader "Hidden/SeparableSSS" {
	Properties { _MainTex ("", any) = "" {} }
	CGINCLUDE
	#include "UnityCG.cginc"
    #include "SeparableSSS_Common.cginc"
	
	struct v2f 
	{
		float4 pos : SV_POSITION;
		half2 uv : TEXCOORD0;		
	};
	int SSS_StereoEyeIndex = 0;//Because UNITY_SINGLE_PASS_STEREO doesn't work
	fixed EdgeOffset;
	#define EDGE_TEST                          1
	//#define OFFSET_EDGE_TEST                   1
	#define DEBUG_EDGE_TEST                    0
    int _SSS_NUM_SAMPLES = 1;
	int ForceWhiteTransparencyProfile;
	sampler2D _MainTex, _CameraDepthNormalsTexture, _CameraDepthTexture;
	sampler2D SSS_ProfileTex;
	sampler2D SSS_ProfileTexR;
	//half BlurRadius;
    float4 _TexelOffsetScale;
	float4 _MainTex_TexelSize, sssColor, _MainTex_ST;
	float4x4 _InvProjMatrix;
	int maxDistance = 100;
	half CloseupCompensation = 1;

	v2f vert( appdata_img v )
	{
		v2f o; 
		o.pos = UnityObjectToClipPos(v.vertex);		
		o.uv = v.texcoord;
		
		return o;
	}

half4 frag(v2f i) : SV_Target 
{
    #if defined (__INTELLISENSE__)
    #define RANDOMIZED_ROTATION
    #endif

	half2 uv = i.uv;
	//half2 uv = UnityStereoScreenSpaceUVAdjust(i.uv, _MainTex_ST);//1.7
	//
   /*#if UNITY_SINGLE_PASS_STEREO
		float4 scaleOffset = unity_StereoScaleOffset[SSS_StereoEyeIndex];
		uv = (uv - scaleOffset.zw) / scaleOffset.xy;
		
    #endif*/
	
	//seems like this is not used anymore
	/*#if UNITY_SINGLE_PASS_STEREO
	return float4(.5, 1, .5, 1);
	#else
	return float4(1, 0, 0, 1);
	#endif*/
	
	//Stereo test zone
	/*#if SSS_STEREO_ON
	if(SSS_StereoEyeIndex ==0)
		//return float4(.5, 1, .5, 1);
		return tex2D(SSS_ProfileTex, uv).a;
	else
		//return float4(1, 0, 0, 1);
		return tex2D(SSS_ProfileTexR, uv).a;
	#endif*/

    float2 scale = _TexelOffsetScale.xy * _MainTex_TexelSize.xy /** BlurRadius.xx*/;
   // scale *=float2(0,1);
    float4 colorBlurred = 0;
    float4 Profile = 0;
	
	#ifdef SSS_PROFILES
		
		if (SSS_StereoEyeIndex == 0)
			Profile = tex2D(SSS_ProfileTex, uv);
		else
			Profile = tex2D(SSS_ProfileTexR, uv);
		
		sssColor.rgb = Profile.rgb;
		
		scale *= Profile.a;
	#endif

	
	#ifdef TRANSPARENCY
		[branch]
		if(ForceWhiteTransparencyProfile ==1)
			sssColor.rgb = 1;
	#endif

    float4 n  = tex2D(_CameraDepthNormalsTexture, uv);
   
	scale *= 20;
	float4 CenterColor = tex2Dlod(_MainTex, float4(uv, 0, 0));
	float  centerDepth = tex2D(_CameraDepthTexture, uv).r;
	
    float3 weightSum = 0.0f;
    float3 weightSum1 = 0.0f;
    float3 weightSum2 = 0.0f;
	float4 nn = tex2D(_CameraDepthNormalsTexture, uv+float2(0, .01));
	float EdgeTest = 1, EdgeSum;
	float  d = LinearEyeDepth(centerDepth);                               				
        
	
	
	#ifdef TRANSPARENCY
		float LightingPassDepth = 0, TransparencyDepth = 0, DepthDifference = 0;

		if (SSS_StereoEyeIndex == 0)
		{
			LightingPassDepth = LinearEyeDepth(tex2D(LightingTex, uv).a);
			TransparencyDepth = LinearEyeDepth(tex2D(SSS_TransparencyTex, uv).a);
			//return float4(0, 1, 0, 1);
		}
		else
		{
			LightingPassDepth = LinearEyeDepth(tex2D(LightingTexR, uv).a);
			TransparencyDepth = LinearEyeDepth(tex2D(SSS_TransparencyTexR, uv).a);
			//return float4(1, 0, 0, 1);
		}
		
		DepthDifference = TransparencyDepth - LightingPassDepth;
	
		if(DepthDifference == 0)
		{
			return 0;
		}
		//return DepthDifference;

		d = LightingPassDepth;

	#endif
	//return max(0.5, d);

	//scale *= 1/d;
	//scale *= 1.0 / max(1, d);//Don't increment radius v1.7
	scale *= lerp(1.0 / max(1, d), 1.0/d, CloseupCompensation);//Optional v1.8

	half radiusCheck = scale.x + scale.y;
	#ifdef DEBUG_DISTANCE
	return d<maxDistance ? float4(0,12.5,0,1) * radiusCheck : float4(12.3,.0,.0,1) * radiusCheck;
	#endif
	//float dp = (tex2D(SSS_ProfileTex, uv+float2(0, .01)));
//	return ProfileEdge(Profile , dp);
    if(_SSS_NUM_SAMPLES == 0) _SSS_NUM_SAMPLES = 2;//así evito que se vea negro al comienzo
	float invEdgeOffset = 1.0 / EdgeOffset;

	if(radiusCheck > 0.001 && d < maxDistance /*&& d >.05*/)
	{
		for (int k = 0; k < _SSS_NUM_SAMPLES; k++)
		{   
		
			//conditional breaks
			#ifdef TRANSPARENCY
				if(DepthDifference < .00001) break;
			#endif

			#ifdef SSS_PROFILES
			if(Profile.a < .00001) break;
			#endif
			
			//if(CenterColor.r < .1) break;
			//float step = Pow2(2.0 * ((float)k / _SSS_NUM_SAMPLES));
			float step = (float)k / _SSS_NUM_SAMPLES;
			float2 offset = (float2)step * (float2)scale;
			

			#if defined (RANDOMIZED_ROTATION)
			half edges = 1;
					
					#if defined(DITHER_EDGE_TEST)				
					float4 ditherN1 = tex2Dlod(_CameraDepthNormalsTexture, float4(uv + offset, 0, 0));
					float4 ditherN2 = tex2Dlod(_CameraDepthNormalsTexture, float4(uv - offset, 0, 0));
					half ditherdd1 = tex2Dlod(_CameraDepthTexture, float4(uv + offset , 0, 0)).r;
					half ditherdd2 = tex2Dlod(_CameraDepthTexture, float4(uv - offset , 0, 0)).r;
					edges *= Edges(d, LinearEyeDepth(ditherdd1), n, ditherN1);
					edges *= Edges(d, LinearEyeDepth(ditherdd2), n, ditherN2);
						
						#if defined(SSS_PROFILES) && defined (PROFILE_TEST)
							half4 ditherdp1;
							if (SSS_StereoEyeIndex == 0)
							ditherdp1 = tex2Dlod(SSS_ProfileTex, float4(uv + offset , 0, 0));
							else
							ditherdp1 = tex2Dlod(SSS_ProfileTexR, float4(uv + offset , 0, 0));

							edges *= ProfileEdge(Profile , ditherdp1);
							half4 ditherdp2;
							if (SSS_StereoEyeIndex == 0)
							ditherdp2 = tex2Dlod(SSS_ProfileTex, float4(uv- offset , 0, 0));
							else
							ditherdp2 = tex2Dlod(SSS_ProfileTexR, float4(uv - offset , 0, 0));
				
							edges *= ProfileEdge(Profile , ditherdp2);				
						#endif

					#endif

				float2 random = RandN2(1, tex2Dlod(NoiseTexture, float4(uv + /*DitherSpeed**/ DitherScale.xx * _Time.xx, 0, 0)).xy);
				float2 blueNoise = tex2Dlod(NoiseTexture, float4(uv * DitherScale -/* DitherSpeed  **/ random,0,0)).xy * 2.0 - 1.0; // works better with [-1, 1] range
				DitherIntensity *= edges;
				blueNoise *= edges;
				float2x2 RotationMatrix = float2x2(blueNoise.x, blueNoise.y, -blueNoise.y, blueNoise.x);
				float2x2 identityMatrix = float2x2(1.0, 0.0, 0.0, 1.0);				
				float2x2 tapMatrix = identityMatrix;
           
				tapMatrix = RotationMatrix;
				
				offset = mul(offset, tapMatrix);
								
				offset = lerp(step * scale, offset, DitherIntensity);
				
			#endif 
      
		//Blur radius by depth difference
		#ifdef TRANSPARENCY
			if (SSS_StereoEyeIndex == 0)
			{
					float LightingPassDepthD1 = LinearEyeDepth(tex2Dlod(LightingTex, float4(uv + offset, 0, 0)).a);
					float TransparencyDepthD1 = LinearEyeDepth(tex2Dlod(SSS_TransparencyTex, float4(uv + offset, 0, 0)).a);
					float DepthDifferenceD1 = TransparencyDepthD1 - LightingPassDepthD1;

					float LightingPassDepthD2 = LinearEyeDepth(tex2Dlod(LightingTex, float4(uv - offset, 0, 0)).a);
					float TransparencyDepthD2 = LinearEyeDepth(tex2Dlod(SSS_TransparencyTex, float4(uv - offset, 0, 0)).a);
					float DepthDifferenceD2 = TransparencyDepthD2 - LightingPassDepthD2;

					offset *= sqrt(DepthDifferenceD1);
					offset *= sqrt(DepthDifferenceD2);
					//offset *= (DepthDifferenceD1);
					//offset *= (DepthDifferenceD2);
			}	
			else
			{
					float LightingPassDepthD1 = LinearEyeDepth(tex2Dlod(LightingTexR, float4(uv + offset, 0, 0)).a);
					float TransparencyDepthD1 = LinearEyeDepth(tex2Dlod(SSS_TransparencyTexR, float4(uv + offset, 0, 0)).a);
					float DepthDifferenceD1 = TransparencyDepthD1 - LightingPassDepthD1;

					float LightingPassDepthD2 = LinearEyeDepth(tex2Dlod(LightingTexR, float4(uv - offset, 0, 0)).a);
					float TransparencyDepthD2 = LinearEyeDepth(tex2Dlod(SSS_TransparencyTexR, float4(uv - offset, 0, 0)).a);
					float DepthDifferenceD2 = TransparencyDepthD2 - LightingPassDepthD2;

					offset *= sqrt(DepthDifferenceD1);
					offset *= sqrt(DepthDifferenceD2);
					//offset *= (DepthDifferenceD1);
					//offset *= (DepthDifferenceD2);
			}	
		#endif
        
   		
			float3 SampleColor1 = max(1e-10, sssColor.rgb);
			float3 weight1 = exp(-Pow2(step / SampleColor1));
        
			float3 SampleColor2 = max(1e-10, sssColor.rgb);
			float3 weight2 = exp(-Pow2(step / SampleColor2));
			//weight1 = step * diff1;
			//weight2 = step * diff2;
			#if EDGE_TEST

				#ifndef TRANSPARENCY
					half4 nn1 = tex2Dlod(_CameraDepthNormalsTexture, float4(uv + offset , 0, 0));
					half dd1 = tex2Dlod(_CameraDepthTexture, float4(uv + offset , 0, 0)).r;
					half4 nn2 = tex2Dlod(_CameraDepthNormalsTexture, float4(uv - offset , 0, 0));
					half dd2 = tex2Dlod(_CameraDepthTexture, float4(uv - offset , 0, 0)).r;
		 
					half diff1 = Edges(d, LinearEyeDepth(dd1), n, nn1);
				#else //Switch to previous depth texture
					half dd1 = 0;
					
					if (SSS_StereoEyeIndex == 0)
						dd1 = tex2Dlod(LightingTex, float4(uv + offset , 0, 0)).a;
					else
						dd1 = tex2Dlod(LightingTexR, float4(uv + offset , 0, 0)).a;

					half diff1 = TransparencyEdges(LightingPassDepth, LinearEyeDepth(dd1));
			
				#endif			
				
				#if defined(SSS_PROFILES) && defined (PROFILE_TEST)
					half4 dp1;
					
					if (SSS_StereoEyeIndex == 0)
						dp1 = tex2Dlod(SSS_ProfileTex, float4(uv + offset , 0, 0));
					else
						dp1 = tex2Dlod(SSS_ProfileTexR, float4(uv + offset , 0, 0));

					diff1 *= ProfileEdge(Profile , dp1);
				#endif
				weight1 *= diff1;

					#ifndef TRANSPARENCY
						half diff2 = Edges(d, LinearEyeDepth(dd2), n, nn2);	
					#else //Switch to previous depth texture
						half dd2 = 0;
						
						if (SSS_StereoEyeIndex == 0)
							dd2 = tex2Dlod(LightingTex, float4(uv - offset , 0, 0)).a;
						else
							dd2 = tex2Dlod(LightingTexR, float4(uv - offset , 0, 0)).a;

						half diff2 = TransparencyEdges(LightingPassDepth, LinearEyeDepth(dd2));	

					#endif
				
				#if defined(SSS_PROFILES) && defined (PROFILE_TEST)
					half4 dp2;

					if (SSS_StereoEyeIndex == 0)
						dp2 = tex2Dlod(SSS_ProfileTex, float4(uv - offset , 0, 0));
					else
						dp2 = tex2Dlod(SSS_ProfileTexR, float4(uv - offset , 0, 0));

					diff2 *= ProfileEdge(Profile , dp2);
				#endif
				EdgeTest = min(EdgeTest,diff1 * diff2);
				weight2 *= diff2;
			#endif

			offset *= EdgeOffset;
			#if OFFSET_EDGE_TEST
			//if(EdgeTest==1)
				{
				nn1o = tex2Dlod(_CameraDepthNormalsTexture, float4(uv + offset , 0, 0));
				dd1o = tex2Dlod(_CameraDepthTexture, float4(uv + offset , 0, 0)).r;
				nn2o = tex2Dlod(_CameraDepthNormalsTexture, float4(uv - offset , 0, 0));
				dd2o = tex2Dlod(_CameraDepthTexture, float4(uv - offset , 0, 0)).r;
		 
				diff1o = Edges(d, LinearEyeDepth(dd1o), n, nn1o);
				#if defined(SSS_PROFILES) && defined (PROFILE_TEST)
					
					if (SSS_StereoEyeIndex == 0)
						dp1o = tex2Dlod(SSS_ProfileTex, float4(uv + offset , 0, 0));
					else
						dp1o = tex2Dlod(SSS_ProfileTexR, float4(uv + offset , 0, 0));

					diff1o *= ProfileEdge(Profile , dp1o);
				#endif
				weight1 *= diff1o;

				diff2o = Edges(d, LinearEyeDepth(dd2o), n, nn2o);	
					
				#if defined(SSS_PROFILES) && defined (PROFILE_TEST)
					
					if (SSS_StereoEyeIndex == 0)
						dp2o = tex2Dlod(SSS_ProfileTex, float4(uv - offset , 0, 0));
					else
						dp2o = tex2Dlod(SSS_ProfileTexR, float4(uv - offset , 0, 0));

					diff2o *= ProfileEdge(Profile , dp2o);
				#endif
				EdgeTest = min(EdgeTest,diff1o * diff2o);
				weight2 *= diff2o;
				}
			#endif

			weightSum1 += weight1;
			weightSum2 += weight2;
			weightSum += (weight1 + weight2) * .5;
         
			//offset = clamp(offset, 0, EdgeTest);
			offset *= invEdgeOffset;
			colorBlurred.rgb += tex2Dlod(_MainTex, float4(uv + offset, 0, 0)).rgb * weight1 * 0.5;
			colorBlurred.rgb += tex2Dlod(_MainTex, float4(uv - offset, 0, 0)).rgb * weight2 * 0.5;
			EdgeSum += EdgeTest;
      
		}			
		colorBlurred.rgb = max(1e-6, colorBlurred.rgb / weightSum);
	}
	else
    	colorBlurred.rgb =	CenterColor.rgb;				
   						
    //colorBlurred.rgb *= float3(1, 0,0);
   #if DEBUG_EDGE_TEST
	EdgeSum = EdgeSum / _SSS_NUM_SAMPLES;
	return EdgeSum;
   #else
	return colorBlurred;
	#endif
}		
	
	ENDCG
	SubShader
	{
		 Pass
		 {
			  ZTest Always
			  Cull Off
			  ZWrite Off
			  CGPROGRAM
			  #pragma multi_compile _ RANDOMIZED_ROTATION
			  #pragma multi_compile _ SSS_PROFILES
			  //#pragma multi_compile _ EDGE_TEST
			  #pragma multi_compile _ PROFILE_TEST
			  #pragma multi_compile _ DEBUG_DISTANCE
			  #pragma multi_compile _ OFFSET_EDGE_TEST
			  #pragma multi_compile _ DITHER_EDGE_TEST
			  #pragma multi_compile _ TRANSPARENCY
			  //because UNITY_SINGLE_PASS_STEREO is not called here I had to do it manually
			  //#pragma multi_compile _ SSS_STEREO_ON
			  #pragma vertex vert
			  #pragma fragment frag
              #pragma target 3.0



			  ENDCG
		  }
	}
	Fallback off
}
