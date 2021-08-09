Shader "XunShan/Render/Character/Body"
{
	Properties
	{
		_Gama("Gama",float) = 0.45
		[NoScaleOffset]_BaseMap("Albedo (RGB)", 2D) = "white" {}
		[NoScaleOffset]_MixMap("Mix (R:Metallic G:SSSMask B:Roughness)", 2D) = "white" {}
		[NoScaleOffset]_AnisotropicMap("Anisotropic Map", 2D) = "bump" {}
		[NoScaleOffset]_NormalMap("Normal Map", 2D) = "bump" {}
		[NoScaleOffset]_DiffuseCube("DiffuseCube",Cube) = "white"{}  
		_DiffuseCubeColor("DiffuseCube Color",color) = (1,1,1,1)
		
		[NoScaleOffset]_GlossyCube("Glossy Cube",Cube) = "white"{}  
		_GlossyCubeColor("Glossy Color",color) = (1,1,1,1)
		_NoiseIntensity("Noise Intensity", Float) = 1.0
		[Space(15)]
		_BaseBrightness("Base Brightness", Range(1,5)) = 2
		_Metallic("_Metallic", Range(0,1)) = 0.0
		_Roughness("_Roughness", Range(0,1)) = 0.0
		_SkinFactor("_SkinFactor", Range(0,2)) = 1.0
		_AoScale("_AoScale",Range(0,1)) = 0.5

		_Mip("Mip",Range(0,10)) = 5
		_ShadowColor("Shadow Factor(Vector3)", Color) = (0.667, 0.545, 0.761, 1)
		_LightDirIntensity("_LightDirIntensity",Range(0,2)) = 0.7
		_MainLightDir_Scale("MainLightDir_Scale", Float) = 0.8


		[Space(15)]
		[Header(Environment)]
		_EnvirFactor("Envir Factor", Range(0.5,1.5)) = 1
		_EnvirFresnel("Envir Fresnel", Range(0,3)) = 0.35

		[Space(15)]
		[Header(Rim)]
		[Toggle]_RimEnable("RimLighting Enable",int) = 0
		_RimColor("Rim Color", Color) = (0,0.3804,1,0)
		_RimFactor("Rim Factor", Range(0.1,10)) = 0.0
		_RimSize("Rim Size", Float) = 2.80
		_RimStart("Rim Start", Range(0,1)) = 0.0
		_RimEnd("Rim End", Range(0,5)) = 2.5

		[Space(15)]
		[Header(Emissive)]
		[Toggle]_EmissiveEnable("Emissive Enable",int) = 0
		_EmissiveFactor("Emissive Factor",Range(0,5)) = 0

	}
	SubShader
	{
		Tags{"RenderType" = "Opaque" "RenderPipeline" = "UniversalRenderPipeline" "IgnoreProjector" = "True"}

		Pass
		{
			Name "StandardLit"
			Tags{"LightMode" = "UniversalForward"}

			HLSLPROGRAM
			#pragma prefer_hlslcc gles
			#pragma exclude_renderers d3d11_9x
			#pragma target 2.0

			// -------------------------------------
			// Universal Pipeline keywords
			#pragma multi_compile _ _MAIN_LIGHT_SHADOWS
			#pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
			// 自定义变体
			#pragma shader_feature _ _EMISSIVEENABLE_ON _RIMENABLE_ON 
			#pragma multi_compile_fog
			
			#pragma vertex LitPassVertex
			#pragma fragment LitPassFragment

			#include "XunShan_Render_CharacterLighting.hlsl"

			struct Attributes
			{
				float4 positionOS   : POSITION;
				float3 normalOS     : NORMAL;
				float4 tangentOS	: TANGENT;
				float2 uv           : TEXCOORD0;

				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct Varyings
			{
				float4 positionCS               : SV_POSITION;
				float2 uv                       : TEXCOORD0;
				float4 positionWSAndFogFactor   : TEXCOORD1; // xyz: positionWS, w: vertex fog factor
				half3  normalWS                 : TEXCOORD2;
				float3 tangentWS				: TEXCOORD5;
				float3 bitangentWS				: TEXCOORD6;
				float4 shadowCoord				: TEXCOORD7;
			};

			TEXTURE2D(_BaseMap);           SAMPLER(sampler_BaseMap);
			TEXTURE2D(_MixMap);            SAMPLER(sampler_MixMap);
			TEXTURE2D(_NormalMap);         SAMPLER(sampler_NormalMap);
			// #if _ANISOTROPICENABLE_ON
			TEXTURE2D(_AnisotropicMap);    SAMPLER(sampler_AnisotropicMap);
			// #endif
			TEXTURECUBE(_DiffuseCube);         SAMPLER(sampler_DiffuseCube);
			TEXTURECUBE(_GlossyCube);      SAMPLER(sampler_GlossyCube);

			CBUFFER_START(UnityPerMaterial)
			#if _RIMENABLE_ON
				half3 _RimColor;
				half _RimSize;
				half _RimStart;
				half _RimEnd;
				half _RimFactor;
			#endif 

			#if _EMISSIVEENABLE_ON
				half _EmissiveFactor;
			#endif

			// #if _ANISOTROPICENABLE_ON
			half _NoiseIntensity;
			// #endif
			half4 _DiffuseCubeColor;
			half _SkinFactor;
			half _SkinColor;
			half _AoScale;
			half _Metallic;
			half _Roughness;
			half _BaseBrightness;
			half _MainLightDir_Scale;
			half4 _ShadowColor;
			half _EnvirFactor;
			half _EnvirFresnel;
			half _LightDirIntensity;
			half _Gama;
			half3 _GlossyCubeColor;
			half _Mip;
			CBUFFER_END



			Varyings LitPassVertex(Attributes v)
			{
				Varyings o;
				o.uv = v.uv;

				o.positionCS = TransformObjectToHClip(v.positionOS);
				half3 positionWS = TransformObjectToWorld(v.positionOS);
				
				o.normalWS  = TransformObjectToWorldNormal(v.normalOS);
				o.tangentWS = TransformObjectToWorldDir(v.tangentOS.xyz);
				real sign = v.tangentOS.w * unity_WorldTransformParams.w;
				o.bitangentWS = cross(v.normalOS, v.tangentOS)* sign;
				
				float fogFactor = ComputeFogFactor(o.positionCS.z);
				o.positionWSAndFogFactor = float4(positionWS, fogFactor);

				#ifdef _MAIN_LIGHT_SHADOWS
					o.shadowCoord = TransformWorldToShadowCoord(positionWS);
				#else
					o.shadowCoord = 0;
				#endif

				return o;
			}


			half3 GlossyEnvironmentReflection(half3 reflectVector, half perceptualRoughness )
			{
				#if !defined(_ENVIRONMENTREFLECTIONS_OFF)
					half mip = PerceptualRoughnessToMipmapLevel(perceptualRoughness);
					half4 encodedIrradiance = SAMPLE_TEXTURECUBE_LOD(_GlossyCube, sampler_GlossyCube, reflectVector, mip);

					#if !defined(UNITY_USE_NATIVE_HDR)
						half3 irradiance = DecodeHDREnvironment(encodedIrradiance, unity_SpecCube0_HDR);
					#else
						half3 irradiance = encodedIrradiance.rgb;
					#endif
					return irradiance;
				#endif // GLOSSY_REFLECTIONS

				return _GlossyEnvironmentColor.rgb ;
			}
			
			half4 LitPassFragment(Varyings i) : SV_Target
			{

				float3 positionWS = i.positionWSAndFogFactor.xyz;
				// 贴图采样
				half4 baseMap = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, i.uv.xy);
				half3 albedo = pow(baseMap.rgb,2)* _BaseBrightness;
				half3 mixMap = SAMPLE_TEXTURE2D(_MixMap, sampler_MixMap, i.uv.xy).rgb;
				half4 aniMap = SAMPLE_TEXTURE2D(_AnisotropicMap, sampler_AnisotropicMap, i.uv.xy);
				half normalMapScale = 1.0;
				half4 uv_normalMap = SAMPLE_TEXTURE2D(_NormalMap, sampler_NormalMap, i.uv.xy);
				// 将normal.z 赋值为 1，因为面部法线的z取1时正好可以去除面部的自投影。
				half3 normalMapTS = NormalRG_Custom(uv_normalMap.rg, 1.0);
				half3x3 tbn = half3x3(i.tangentWS.xyz, i.bitangentWS.xyz, i.normalWS.xyz);
				half3 normalMapWS = normalize(TransformTangentToWorld_Scale(normalMapTS, normalMapScale,  tbn));
				half3 normalVS = TransformWorldToViewDir(normalMapWS);
				half3 normalTexTS = NormalRG_Custom(uv_normalMap.rg, 1.0);

				Light mainLight = GetMainLight(i.shadowCoord);
				half3 lightColor = mainLight.color.rgb * _LightDirIntensity;
				half3 lightDirWS_scale = mainLight.direction * _MainLightDir_Scale;
				half3 viewDirWS = SafeNormalize(_WorldSpaceCameraPos - positionWS);
				half3 halfDirWS = SafeNormalize(float3(lightDirWS_scale) + float3(viewDirWS));
				half3 reflectWS = reflect(-viewDirWS, normalMapWS);
				half shadowAttenuation = mainLight.shadowAttenuation;
				half VDotH = saturate(dot(viewDirWS, halfDirWS));
				half NDotH = max(0, dot(normalMapWS, halfDirWS));
				half NDotV = saturate(dot(normalMapWS, viewDirWS));
				half NDotL = dot(normalMapWS,  lightDirWS_scale);
				half NDotL_Min = min(saturate(NDotL), shadowAttenuation);


				// 各向异性法线
				half3 aniNormalTS = NormalRG_Custom(aniMap.rg, 0);
				half3 NormalWS_ani = normalize(TransformTangentToWorld(aniNormalTS,tbn));
				// 计算各向异性
				// aniMap.b - 0.5 意思是从(0~1)remap到(-0.5 ~ 0.5)，因为后面有_Noise_Offset了，所以不用再乘2或其它
				half normalScale = aniMap.b * _NoiseIntensity;
				//反向
				// AnisTex.g < 0.25 = 1
				// AnisTex.g > 0.25 = 0
				half aniMask = step(mixMap.g, 0.25);
				// 头发法线合并到整体法线纹理
				NormalWS_ani = normalize((normalMapWS * normalScale) + NormalWS_ani);	
				// 发根偏黑，发尖偏白
				half aniNDotV = saturate(dot(NormalWS_ani, viewDirWS));
				// return aniNDotV;
				half aniso = max(0.0, sin(aniNDotV * PI));
				// 头发部分 = aniso
				// 非头发部分 = NDotH
				NDotH = lerp(NDotH, aniso, aniMask);


				//-------------------------------
				half sss = saturate((mixMap.g * 2) - 1); // remap -1到1 但去掉-1到0的值（即去掉原图0-0.5的值，取0.5-1）
				// 次表面散射近似实现-环绕散射
				float skinDiffuse = WrapDiffuse(NDotL, 0.45); 
				half SkinFactor = saturate(sss * _SkinFactor);
				SkinFactor = lerp(saturate(NDotL), skinDiffuse, SkinFactor) * shadowAttenuation;
				
				// RGB值小于0.35的恒定(baseMap.rgb - 0.1)，越大于0.35，得到值越暗
				// half3 SkinColor = baseMap.rgb;
				half3 SkinColor = saturate(baseMap.rgb - max(max(max(baseMap.r, baseMap.g), baseMap.b) - 0.39, 0.1)) ;
				// return half4(SkinColor,1);
				half sssNoSL = 1 - lerp(saturate(NDotL), saturate(-NDotL), 0.61);
				half sssNoSL_wrap = WrapDiffuse(sssNoSL, -0.47);

				half3 sssResult = (((sssNoSL_wrap  * SkinFactor * SkinColor) * 2.35) * 0.3);
				

				//----------------------------------
				//参数 BRDF
				//----------------------------------
				half ao = uv_normalMap.b;
				half metallic = saturate(mixMap.r * _Metallic);
				half roughness = saturate(mixMap.b * _Roughness);
				half roughnessRange = roughness;
				half roughnessRange2 = roughnessRange * roughnessRange;				
				half oneMinusReflectivity = 1 - metallic;        // 漫反射反射率
				half3 diffColor = albedo * oneMinusReflectivity; // 漫反射颜色
				half3 specColor = lerp(albedo, 0.04, oneMinusReflectivity);	// 高光颜色 

				half finalAO = GetSpecularOcclusion(NDotV, _AoScale, ao);	// 调整过的AO				
				half3 sssIndirect = NDotV * SkinColor * SkinFactor;
				// return half4(sssIndirect,1);

				//间接光的diffuse
				half4 IndirectDiffuseCube = SAMPLE_TEXTURECUBE_LOD(_DiffuseCube, sampler_DiffuseCube, normalMapWS,_Mip);
				half3 IndirectDiffuse = IndirectDiffuseCube.rgb * _EnvirFactor * _DiffuseCubeColor.rgb;  // 计算sh(间接Diffuse)

				float3 ShadowColor = lerp(_ShadowColor.xyz, 1.0, SkinFactor); // 控制暗部颜色	


				///////////////////////////////////////////////////////
				half3 indirectDiffuse = saturate(ShadowColor + sssIndirect);  
				///////////////////////////////////////////////////////

				half3 indirectDiffuseTerm = IndirectDiffuse * indirectDiffuse; 
				// return half4(indirectDiffuseTerm,1);

				
				//-------------------------------
				// 计算直接Diffuse
				half3 diffuse = SkinFactor + sssResult;
				half3 diffuseTerm = diffuse * lightColor;
				//-------------------------------
				// 计算Diffuse(直接+间接)
				half3 diffuseTotal = diffColor * (indirectDiffuseTerm + diffuseTerm);


				//-------------------------------
				// 计算直接Specular BRDF
				half3 F = My_F_Schlick(specColor, VDotH);
				half D = My_D_GGX(roughnessRange2, NDotH);
				// 使粗糙度增加(迪士尼法则)
				half visRoughnessRange = 0.5 * roughnessRange + 0.5;
				half Vis = My_Vis_Schlick(visRoughnessRange * visRoughnessRange, NDotV, NDotL);
				// Vis = G / (4*NoL*NDotV)
				// Microfacet specular = D*G*F / (4*NoL*NDotV) = D*Vis*F
				half3 specularTerm = D * Vis * F;
				
				// 直接高光应用NoL，因为每个部分的NoL可能不一样，单独应用
				specularTerm *= NDotL_Min;
				//-------------------------------
				// 计算间接Specular BRDF
				half3 indirectSpecular = GlossyEnvironmentReflection(reflectWS, roughness) *_GlossyCubeColor.rgb;
				half3 indirectSpecularColor = EnvironmentBRDFApprox(roughnessRange, NDotV, specColor,_EnvirFresnel);
				half3 indirectSpecularTerm = indirectSpecularColor * indirectSpecular;
				// 间接高光应用颜色
				indirectSpecularTerm *= ShadowColor;
				indirectSpecularTerm *= lerp(0.6, 1.0, NDotL);      // 间接高光应用NoL(减弱暗部亮度)
				half3 specularTotal = specularTerm + indirectSpecularTerm;
				half3 color = (diffuseTotal + specularTotal) * finalAO;

				half3 rimColor = 0;
				half3 emissiveColor = 0;
				#if _RIMENABLE_ON
					rimColor = CalcRim(NDotV, _RimStart, _RimEnd , _RimSize,  _RimColor.rgb, _RimFactor);
				#endif 
				#if _EMISSIVEENABLE_ON
					half emissiveMask = 0;
					// Alpha通道只取0.5-1之间的值映射为0-1的值
					emissiveMask = saturate(baseMap.a - 0.5) * 2.0;
					emissiveColor = (emissiveMask * _EmissiveFactor) * diffColor;
				#endif
				color += emissiveColor + rimColor;

				half alpha = (1.0 - NDotV) ;
				half3 colorA = sqrt(color) / 1.5;
				float specularLuminance = dot(specularTotal, float3(0.3, 0.59, 0.11));
				
				half3 colorB = (color / (color + 0.187)) * 1.035;
				float4 finalColor = half4(colorB, alpha);
				finalColor = pow(finalColor,_Gama);
				return finalColor;
			}
			ENDHLSL
		}
		UsePass "Universal Render Pipeline/Lit/ShadowCaster"

	}
}
