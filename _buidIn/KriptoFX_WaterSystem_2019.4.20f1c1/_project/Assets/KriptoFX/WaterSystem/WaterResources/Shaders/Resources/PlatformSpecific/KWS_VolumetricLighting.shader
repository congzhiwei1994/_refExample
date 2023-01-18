Shader "Hidden/KriptoFX/KWS/VolumetricLighting"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" { }
	}
	SubShader
	{
		Cull Off
		ZWrite Off
		ZTest Always

		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma target 4.6

			#pragma multi_compile _ KWS_USE_DIR_LIGHT KWS_USE_DIR_LIGHT_SINGLE KWS_USE_DIR_LIGHT_SPLIT KWS_USE_DIR_LIGHT_SINGLE_SPLIT //It looks terrible, but it is necessary to optimize shaders variants.

			#pragma multi_compile _ KWS_USE_POINT_LIGHTS
			#pragma multi_compile _ KWS_USE_SHADOW_POINT_LIGHTS
			#pragma multi_compile _ KWS_USE_SPOT_LIGHTS
			#pragma multi_compile _ KWS_USE_SHADOW_SPOT_LIGHTS

			#pragma multi_compile _ USE_CAUSTIC
			#pragma multi_compile _ USE_LOD1 USE_LOD2 USE_LOD3

			//#include "UnityCG.cginc"
			#include "../Common/KWS_WaterVariables.cginc"
			#include "../Common/KWS_WaterPassHelpers.cginc"
			#include "KWS_Lighting.cginc"
			#include "KWS_PlatformSpecificHelpers.cginc"

			sampler2D KW_PointLightAttenuation;
			sampler2D _LightVolume;

			sampler2D _MainTex;

			sampler2D KW_SpotLightTex;


			
			//sampler2D _CameraDepthTextureBeforeWaterZWrite;;
			sampler2D KW_WaterScreenPosTex;

			float4 KWS_NearPlaneWorldPos[3];

			float4 KWS_VolumeTexSceenSize;
			
			float4x4 KW_SpotWorldToShadow;
			float4x4 KW_InverseProjectionMatrix;

			half KWS_Transparent;
			half MaxDistance;
			half KWS_RayMarchSteps;
			half _FogDensity;
			half _Extinction;
			half4 KWS_LightAnisotropy;
			half _MieScattering;
			half _RayleighScattering;



			texture2D KW_CausticLod0;
			texture2D KW_CausticLod1;
			texture2D KW_CausticLod2;
			texture2D KW_CausticLod3;

			float4 KW_CausticLodSettings;
			float3 KW_CausticLodOffset;

			sampler2D KW_CausticTex;
			half KW_CausticDomainSize;
			float2 KW_CausticTex_TexelSize;
			float KWS_VolumeLightMaxDistance;
			float _MyTest;
			float KWS_VolumeLightBlurRadius;

			float KWS_VolumeDepthFade;

			
			inline half MieScattering(float cosAngle)
			{
				//return KWS_LightAnisotropy.w * (KWS_LightAnisotropy.x / (pow(KWS_LightAnisotropy.y - KWS_LightAnisotropy.z * cosAngle, 1.5)));
				return KWS_LightAnisotropy.w * (KWS_LightAnisotropy.x / (KWS_LightAnisotropy.y - KWS_LightAnisotropy.z * cosAngle));
			}

			inline float3 ScreenToWorld(float2 UV, float depth)
			{
				float2 uvClip = UV * 2.0 - 1.0;
				float4 clipPos = float4(uvClip, depth, 1.0);
				float4 viewPos = mul(KW_ProjToView, clipPos);
				viewPos /= viewPos.w;
				float3 worldPos = mul(KW_ViewToWorld, viewPos).xyz;
				return worldPos;
			}


			float3 KW_CausticLodPosition;
			float KW_DecalScale;

			half GetCausticLod(float3 lightForward, float3 currentPos, float offsetLength, float lodDist, texture2D tex, half lastLodCausticColor)
			{
				float2 uv = ((currentPos.xz - KW_CausticLodPosition.xz) - offsetLength * lightForward.xz) / lodDist + 0.5 - KW_CausticLodOffset.xz;
				half caustic = tex.SampleLevel(sampler_linear_repeat, uv, 4.0).r;
				uv = 1 - min(1, abs(uv * 2 - 1));
				float lerpLod = uv.x * uv.y;
				lerpLod = min(1, lerpLod * 3);
				return lerp(lastLodCausticColor, caustic, lerpLod);
			}

			half ComputeCaustic(float3 rayStart, float3 currentPos, float3 lightForward)
			{
				float angle = dot(float3(0, -0.999, 0), lightForward);
				float offsetLength = (rayStart.y - currentPos.y) / angle;

				half caustic = 0.1;
				#if defined(USE_LOD3)
					caustic = GetCausticLod(lightForward, currentPos, offsetLength, KW_CausticLodSettings.w, KW_CausticLod3, caustic);
				#endif
				#if defined(USE_LOD2) || defined(USE_LOD3)
					caustic = GetCausticLod(lightForward, currentPos, offsetLength, KW_CausticLodSettings.z, KW_CausticLod2, caustic);
				#endif
				#if defined(USE_LOD1) || defined(USE_LOD2) || defined(USE_LOD3)
					caustic = GetCausticLod(lightForward, currentPos, offsetLength, KW_CausticLodSettings.y, KW_CausticLod1, caustic);
				#endif
				caustic = GetCausticLod(lightForward, currentPos, offsetLength, KW_CausticLodSettings.x, KW_CausticLod0, caustic);

				float distToCamera = length(currentPos - _WorldSpaceCameraPos);
				float distFade = saturate(distToCamera / KW_DecalScale * 2);
				caustic = lerp(caustic, 0, distFade);
				return caustic * 10 - 1;
			}

			/*static const float ditherPattern[4][4] = { { 0.1f, 0.5f, 0.125f, 0.625f},
			{ 0.75f, 0.22f, 0.875f, 0.375f},
			{ 0.1875f, 0.6875f, 0.0625f, 0.5625},
			{ 0.9375f, 0.4375f, 0.8125f, 0.3125} };*/

			static const float ditherPattern[8][8] =
			{

				{
					0.012f, 0.753f, 0.200f, 0.937f, 0.059f, 0.800f, 0.243f, 0.984f
				},
				{
					0.506f, 0.259f, 0.690f, 0.443f, 0.553f, 0.306f, 0.737f, 0.490f
				},
				{
					0.137f, 0.875f, 0.075f, 0.812f, 0.184f, 0.922f, 0.122f, 0.859f
				},
				{
					0.627f, 0.384f, 0.569f, 0.322f, 0.675f, 0.427f, 0.612f, 0.369f
				},
				{
					0.043f, 0.784f, 0.227f, 0.969f, 0.027f, 0.769f, 0.212f, 0.953f
				},
				{
					0.537f, 0.290f, 0.722f, 0.475f, 0.522f, 0.275f, 0.706f, 0.459f
				},
				{
					0.169f, 0.906f, 0.106f, 0.843f, 0.153f, 0.890f, 0.090f, 0.827f
				},
				{
					0.659f, 0.412f, 0.600f, 0.353f, 0.643f, 0.400f, 0.584f, 0.337f
				},
			};

			inline float4 RayMarch(float2 uv, float3 rayStart, float3 rayDir, float rayLength, half isUnderwater)
			{
				//float offset = tex2D(KW_DitherTexture, ditherScreenPos/8).w;
				float2 ditherScreenPos = uv * KWS_VolumeTexSceenSize;
				ditherScreenPos = ditherScreenPos % 8;
				float offset = ditherPattern[ditherScreenPos.y][ditherScreenPos.x];

				float stepSize = rayLength / KWS_RayMarchSteps;
				float3 step = rayDir * stepSize;
				float3 currentPos = rayStart + step * offset;
				
				float4 result = 0;
				float cosAngle = 0;
				float scattering = 0;
				float shadowDistance = saturate(distance(rayStart, _WorldSpaceCameraPos) - KWS_Transparent);
				float addLightTransparentFix = lerp(1, 15, KWS_Transparent / 50.0);

				float extinction = 0;
				//float depthFade = 1-exp(-((_WorldSpaceCameraPos.y - KW_WaterPosition.y) + KWS_Transparent));
				
				#if defined(KWS_USE_DIR_LIGHT) || defined(KWS_USE_DIR_LIGHT_SINGLE) || defined(KWS_USE_DIR_LIGHT_SPLIT) || defined(KWS_USE_DIR_LIGHT_SINGLE_SPLIT)
					ShadowLightData light = KWS_DirLightsBuffer[0];

					UNITY_LOOP
					for (int i = 0; i < KWS_RayMarchSteps; ++i)
					{
						float3 atten = DirLightRealtimeShadow(0, currentPos);
						
						float3 scattering = stepSize;
						#if defined(USE_CAUSTIC)
							float underwaterStrength = lerp(saturate((KWS_Transparent - 1) / 5) * 0.5, 1, isUnderwater);
							scattering += scattering * ComputeCaustic(rayStart, currentPos, light.forward) * underwaterStrength;
						#endif

						float3 lightResult = atten * scattering * light.color;
						result.rgb += lightResult;
						currentPos += step;
					}
					cosAngle = dot(light.forward.xyz, -rayDir);
					result.rgb *= MieScattering(cosAngle);
					result.a = DirLightRealtimeShadow(0, rayStart);
				#endif

				#if KWS_USE_POINT_LIGHTS
					UNITY_LOOP
					for (uint pointIdx = 0; pointIdx < KWS_PointLightsCount; pointIdx++)
					{
						LightData light = KWS_PointLightsBuffer[pointIdx];

						currentPos = rayStart + step * offset;
						UNITY_LOOP
						for (int i = 0; i < KWS_RayMarchSteps; ++i)
						{
							float atten = PointLightAttenuation(pointIdx, currentPos);
							//[branch]if (atten < 0.00001) continue;
							float3 scattering = stepSize * light.color.rgb * addLightTransparentFix;
							float3 lightResult = atten * scattering;

							cosAngle = dot(-rayDir, normalize(currentPos - light.position.xyz));
							lightResult *= MieScattering(cosAngle);

							result.rgb += lightResult;
							currentPos += step;
						}
					}
				#endif

				#if KWS_USE_SHADOW_POINT_LIGHTS
					
					UNITY_LOOP
					for (uint shadowPointIdx = 0; shadowPointIdx < KWS_ShadowPointLightsCount; shadowPointIdx++)
					{
						ShadowLightData light = KWS_ShadowPointLightsBuffer[shadowPointIdx];

						currentPos = rayStart + step * offset;
						UNITY_LOOP
						for (int i = 0; i < KWS_RayMarchSteps; ++i)
						{
							float atten = PointLightAttenuationShadow(shadowPointIdx, currentPos);
							//[branch] if (atten < 0.00001) continue;

							float3 scattering = stepSize * light.color.rgb * addLightTransparentFix;
							float3 lightResult = atten * scattering;

							cosAngle = dot(-rayDir, normalize(currentPos - light.position.xyz));
							lightResult *= MieScattering(cosAngle);

							result.rgb += lightResult;
							currentPos += step;
						}
					}
					
				#endif

				#if KWS_USE_SPOT_LIGHTS
					UNITY_LOOP
					for (uint spotIdx = 0; spotIdx < KWS_SpotLightsCount; spotIdx++)
					{
						LightData light = KWS_SpotLightsBuffer[spotIdx];

						currentPos = rayStart + step * offset;
						UNITY_LOOP
						for (int i = 0; i < KWS_RayMarchSteps; ++i)
						{
							float atten = SpotLightAttenuation(spotIdx, currentPos);
							//[branch] if (atten < 0.00001) continue;
							float3 scattering = stepSize * light.color.rgb * addLightTransparentFix;
							float3 lightResult = atten * scattering;

							cosAngle = dot(-rayDir, normalize(currentPos - light.position.xyz));
							lightResult *= MieScattering(cosAngle);

							result.rgb += lightResult;
							currentPos += step;
						}
					}
				#endif

				#if KWS_USE_SHADOW_SPOT_LIGHTS

					UNITY_LOOP
					for (uint shadowSpotIdx = 0; shadowSpotIdx < KWS_ShadowSpotLightsCount; shadowSpotIdx++)
					{
						ShadowLightData light = KWS_ShadowSpotLightsBuffer[shadowSpotIdx];

						currentPos = rayStart + step * offset;
						UNITY_LOOP
						for (int i = 0; i < KWS_RayMarchSteps; ++i)
						{
							float atten = SpotLightAttenuationShadow(shadowSpotIdx, currentPos);
							//[branch] if (atten < 0.00001) continue;
							float3 scattering = stepSize * light.color.rgb * addLightTransparentFix;
							float3 lightResult = atten * scattering;

							cosAngle = dot(-rayDir, normalize(currentPos - light.position.xyz));
							lightResult *= MieScattering(cosAngle);

							result.rgb += lightResult;
							currentPos += step;
						}
					}
				#endif

				result.rgb /= KWS_Transparent;
				result.rgb *= KWS_VolumeDepthFade;
				result.rgb *= 4;
				
				return max(0, result);
			}


			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
			};

			struct v2f
			{
				float4 vertex : SV_POSITION;
				float2 uv : TEXCOORD0;
				float3 nearWorldPos : TEXCOORD1;
			};

			
			v2f vert(uint vertexID : SV_VertexID)
			{
				v2f o;
				o.vertex = GetTriangleVertexPosition(vertexID);
				o.uv = GetTriangleUV(vertexID);
				o.nearWorldPos = KWS_NearPlaneWorldPos[vertexID].xyz;
				return o;
			}

			float3 FrustumRay(float2 uv, float4 frustumRays[4])
			{
				float3 ray0 = lerp(frustumRays[0].xyz, frustumRays[1].xyz, uv.x);
				float3 ray1 = lerp(frustumRays[2].xyz, frustumRays[3].xyz, uv.x);
				return lerp(ray0, ray1, uv.y);
			}

			
			half4 frag(v2f i) : SV_Target
			{
				half mask = GetWaterMaskScatterNormalsBlured(i.uv).x;
				
				UNITY_BRANCH
				if (mask < 0.01) return 0;

				//float4 prevVolumeColor = tex2D(_MainTex, i.uv);
				float depthTop = GetWaterDepth(i.uv);
				float depthBot = GetSceneDepth(i.uv);

				bool isUnderwater = mask > 0.72;
				
				UNITY_BRANCH
				if (depthBot > depthTop && !(mask > 0.01)) return 0;
				
				float3 topPos = ScreenToWorld(i.uv, depthTop);
				float3 botPos = ScreenToWorld(i.uv, depthBot);

				float3 rayDir = botPos - topPos;
				rayDir = normalize(rayDir);
				float rayLength = KWS_VolumeLightMaxDistance ;

				half4 finalColor = 1;
				float3 rayStart;
				
				
				UNITY_BRANCH
				if (isUnderwater)
				{
					rayStart = i.nearWorldPos;
					rayDir = normalize(botPos - _WorldSpaceCameraPos);
					rayLength = min(length(_WorldSpaceCameraPos - botPos), rayLength);
					rayLength = min(length(_WorldSpaceCameraPos - topPos), rayLength);
				}
				else
				{
					rayLength = min(length(topPos - botPos), rayLength);
					rayStart = topPos;
				}

				
				finalColor = RayMarch(i.uv, rayStart, rayDir, rayLength, isUnderwater);
				finalColor.rgb += MIN_THRESHOLD * 2;
				
				return finalColor;
			}
			ENDCG
		}
	}
}