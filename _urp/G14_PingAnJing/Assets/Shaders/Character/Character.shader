Shader "JZPAJ/Character"
{
    Properties
    {
		[NoScaleOffset]_BaseMap("Albedo (RGB)", 2D) = "white" {}
		[NoScaleOffset]_MixMap("Mix (R:金属度 G:混合(SSS+各向异性) B:粗糙度)", 2D) = "white" {}
		[NoScaleOffset]_NormalMap("混合Normal Map", 2D) = "bump" {}
		[NoScaleOffset]_EnvTex("Env Texture", 2D) = "black" {}

		_Min_GGX_Roughness("_Min_GGX_Roughness", Range(0,1)) = 0.04
		_Max_GGX_Roughness("_Max_GGX_Roughness", Range(0,1)) = 1.0
		_Metal_Multi("_Metal_Multi", Float) = 0.0
		_Rough_Multi("_Rough_Multi", Float) = 0.0
		_Diffuse_Intensity("_Diffuse_Intensity", Float) = 1.0
		_U_Light_Scale("_U_Light_Scale", Float) = 1.0
		_Shadow_Bias_Factor("_Shadow_Bias_Factor(Vector2)", Vector) = (0.004, 0.001, 1, 1)
		_Env_Shadow_Factor("_Env_Shadow_Factor", Color) = (0.667, 0.545, 0.761, 1)
		_Envir_Brightness("_Envir_Brightness", Float) = 1.0
		_Max_Brightness("_Max_Brightness", Float) = 130.0
		_Envir_Fresnel_Brightness("_Envir_Fresnel_Brightness", Float) = 0.35
		_Rim_Power("_Rim_Power", Float) = 2.80
		_U_Rim_Start("_U_Rim_Start", Float) = 0.0
		_U_Rim_End("_U_Rim_End", Float) = 1.0
		_Rim_Color("_Rim_Color", Color) = (0,0.3804,1,0)
		_Rim_Multi("_Rim_Multi", Float) = 0.0
		_Force_Pixel_Color("_Force_Pixel_Color(Vector3)", Color) = (0.0, 0.0, 0.0, 0.0)
		_Adjust_Inner("_Adjust_Inner(Vector3)", Color) = (1.0, 1.0, 1.0, 1.0)
		_Inner_Alpha("_Inner_Alpha", Float) = 1.0
		_AlphaMtl("_AlphaMtl", Float) = 1.0
		_U_Tonemapping_Factor("_U_Tonemapping_Factor", Float) = 0.0
		_Bloom_Range("_Bloom_Range", Float) = 0.4
		_Illum_Multi("_Illum_Multi", Float) = 1.0
		_Emissive_Bloom("_Emissive_Bloom", Float) = 1.0
    }
    SubShader
    {
		Tags{"RenderType" = "Opaque" "RenderPipeline" = "UniversalRenderPipeline" "IgnoreProjector" = "True"}
        LOD 100

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

			// -------------------------------------
			// Unity defined keywords
			#pragma multi_compile_fog

			// -------------------------------------
			// 自定义 keywords


			#pragma vertex LitPassVertex
			#pragma fragment LitPassFragment


			#include "CharacterCore.hlsl"

//			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
//			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
//
//			struct Attributes
//			{
//				float4 positionOS   : POSITION;
//				float3 normalOS     : NORMAL;
//				float4 tangentOS	: TANGENT;
//				float2 uv           : TEXCOORD0;
//
//				UNITY_VERTEX_INPUT_INSTANCE_ID
//			};
//
//			struct Varyings
//			{
//				float4 positionCS               : SV_POSITION;
//				float2 uv                       : TEXCOORD0;
//				float4 positionWSAndFogFactor   : TEXCOORD1; // xyz: positionWS, w: vertex fog factor
//				half3  normalWS                 : TEXCOORD2;
//				float3 tangentWS				: TEXCOORD5;
//				float3 bitangentWS				: TEXCOORD6;
//				float4 shadowCoord				: TEXCOORD7;
//			};
//
//			TEXTURE2D(_BaseMap);
//			SAMPLER(sampler_BaseMap);
//
//			TEXTURE2D(_MixMap);
//			SAMPLER(sampler_MixMap);
//
//			TEXTURE2D(_NormalMap);
//			SAMPLER(sampler_NormalMap);
//
//			TEXTURE2D(_EnvTex);
//			SAMPLER(sampler_EnvTex);
//
//			CBUFFER_START(UnityPerMaterial)
//			half _Min_GGX_Roughness;
//			half _Max_GGX_Roughness;
//			half _Metal_Multi;
//			half _Rough_Multi;
//			half _Diffuse_Intensity;
//			half _U_Light_Scale;
//			half2 _Shadow_Bias_Factor;
//			half4 _Env_Shadow_Factor;
//			half _Envir_Brightness;
//			half _Max_Brightness;
//			half _Envir_Fresnel_Brightness;
//			half _Rim_Power;
//			half _U_Rim_Start;
//			half _U_Rim_End;
//			half3 _Rim_Color;
//			half _Rim_Multi;
//			half3 _Force_Pixel_Color;
//			half3 _Adjust_Inner;
//			half _Inner_Alpha;
//			half _AlphaMtl;
//			half _U_Tonemapping_Factor;
//			half _Bloom_Range;
//			half _Illum_Multi;
//			half _Emissive_Bloom;
//			CBUFFER_END
//
//			float4x4 _EnvSHR;
//			float4x4 _EnvSHG;
//			float4x4 _EnvSHB;
//
//			// 全局输入
//			uniform	half4 _G_VirtualLitColor;
//
//			real3 UnpackNormalRG_Optimize(real2 packedNormal, real scaleXY, real z)
//			{
//				real3 normal;
//				normal.xy = packedNormal.rg * 2.0 - 1.0;
//
//				normal.xy *= scaleXY;
//				normal.z = z;
//				return normal;
//			}
//
//			half GetShadow(Light mainLight, half3 normalWS)
//			{
//				// 原代码由顶点中计算，但Unity已占用shadowCoord全部数据，所以只能在片元计算
//				half RNoL = saturate(dot(-normalWS, mainLight.direction));
//				half NoL = 1 - RNoL;
//
//				float shadowTerm = saturate(NoL * _Shadow_Bias_Factor.x + _Shadow_Bias_Factor.y);
//			}
//
//			// Tuned to match behavior of Vis_Smith
//			// [Schlick 1994, "An Inexpensive BRDF Model for Physically-Based Rendering"]
//			float My_Vis_Schlick(float a2, float NoV, float NoL)
//			{
//				//float k = sqrt(a2) * 0.5;
//				float x = 0.5 * a2 + 0.5;
//				float k = x * x;
//
//				float Vis_SchlickV = NoV * (1 - k) + k;
//				float Vis_SchlickL = NoL * (1 - k) + k;
//				return 0.25 / (Vis_SchlickV * Vis_SchlickL);
//			}
//
//			// GGX / Trowbridge-Reitz
//			// [Walter et al. 2007, "Microfacet models for refraction through rough surfaces"]
//			float My_D_GGX(float a2, float NoH)
//			{
//				float d = (NoH * a2 - NoH) * NoH + 1;	// 2 mad
//				return min(a2 / (d*d), 10000.0);					// 4 mul, 1 rcp
//			}
//
//
//			// [Schlick 1994, "An Inexpensive BRDF Model for Physically-Based Rendering"]
//			real3 My_F_Schlick(real3 f0, real f90, real u)
//			{
//				real x = 1.0 - u;
//				real x2 = x * x;
//				real x5 = x * x2 * x2;
//
//				return f0 * (1.0 - x5) + (f90 * x5);        // sub mul mul mul sub mul mad*3
//			}
//			real3 My_F_Schlick(real3 f0, real u)
//			{
//				return My_F_Schlick(f0, 1.0, u);               // sub mul mul mul sub mad*3
//			}
//
//			// [ Lazarov 2013, "Getting More Physical in Call of Duty: Black Ops II" ]
//			float3 EnvironmentBRDFApprox(float roughness, float NoV, float3 f0)
//			{
//				const float4 c0 = float4(-1.0, -0.0275, -0.572, 0.022);
//				const float4 c1 = float4(1.0, 0.0425, 1.04, -0.04);
//
//				float4 r = roughness * c0 + c1;
//				float a004 = min(r.x * r.x, exp2(-9.28 * NoV)) * r.x + r.y;
//				float2 AB = float2(-1.04, 1.04) * a004 + r.zw;
//
//				return f0 * AB.x + AB.y * _Envir_Fresnel_Brightness;
//			}
//			
//			half3 GlossyEnvironmentReflection(half3 reflectVector, half perceptualRoughness)
//			{
//				// 0-7
//				half mip = (perceptualRoughness) / 0.14;
//				float local_945 = ((atan2(reflectVector.z, reflectVector.x) + 3.141593) * 0.15915491);
//				float local_947 = (acos(reflectVector.y) * 0.3183099);
//				float2 local_948 = float2(local_945, local_947);
//				half4 local_949 = SAMPLE_TEXTURE2D_X_LOD(_EnvTex, sampler_EnvTex, local_948, mip);
//				half3 local_952 = (local_949.xyz * local_949.w);
//				half3 local_953 = (local_952 * _Max_Brightness);
//				return local_953;
//			}
//
//			Varyings LitPassVertex(Attributes input)
//			{
//				Varyings output;
//				VertexPositionInputs vertexInput = GetVertexPositionInputs(input.positionOS.xyz);
//				VertexNormalInputs vertexNormalInput = GetVertexNormalInputs(input.normalOS, input.tangentOS);
//
//				output.uv = input.uv;
//
//				float fogFactor = ComputeFogFactor(vertexInput.positionCS.z);
//				output.positionWSAndFogFactor = float4(vertexInput.positionWS, fogFactor);
//				output.normalWS = vertexNormalInput.normalWS;
//				output.positionCS = vertexInput.positionCS;
//				output.tangentWS = vertexNormalInput.tangentWS;
//				output.bitangentWS = vertexNormalInput.bitangentWS;
//#ifdef _MAIN_LIGHT_SHADOWS
//				output.shadowCoord = GetShadowCoord(vertexInput);
//#else
//				output.shadowCoord = 0;
//#endif
//				return output;
//			}
//
//			half4 LitPassFragment(Varyings input) : SV_Target
//			{
//				half4 baseCol = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, input.uv);
//				half4 mixCol = SAMPLE_TEXTURE2D(_MixMap, sampler_MixMap, input.uv);
//				half4 normalCol = SAMPLE_TEXTURE2D(_NormalMap, sampler_NormalMap, input.uv.xy);
//				half3 normalTS = UnpackNormalRG_Optimize(normalCol.rg, 0.7, 1.0);
//				half3 normalWS = normalize(TransformTangentToWorld(normalTS, half3x3(input.tangentWS.xyz, input.bitangentWS.xyz, input.normalWS.xyz)));
//				half3 revNormalTS = UnpackNormalRG_Optimize(normalCol.rg, 1.0, 1.0);
//				revNormalTS.xy = -revNormalTS.xy;
//				half3 revNormalWS = normalize(TransformTangentToWorld(revNormalTS, half3x3(input.tangentWS.xyz, input.bitangentWS.xyz, input.normalWS.xyz)));
//
//				float3 positionWS = input.positionWSAndFogFactor.xyz;
//				Light mainLight = GetMainLight(input.shadowCoord);
//				//mainLight.color.rgb = half3(1.0, 0.9098, 0.8314);
//				half3 lightDirectionWS = mainLight.direction;
//				//half3 lightDirectionWS = normalize(half3(0.30802, -0.44072, -0.84314));
//				half3 scaleLightDirectionWS = lightDirectionWS * _U_Light_Scale;
//				half3 viewDirectionWS = SafeNormalize(GetCameraPositionWS() - positionWS);
//				half3 halfDirectionWS = SafeNormalize(float3(lightDirectionWS)+float3(viewDirectionWS));
//				half shadowAttenuation = mainLight.shadowAttenuation;
//
//				half VoH = saturate(dot(viewDirectionWS, halfDirectionWS));
//				half NoH = max(0, dot(normalWS, halfDirectionWS));
//				half NoV = saturate(dot(normalWS, viewDirectionWS));
//				half NoSL = saturate(dot(normalWS, scaleLightDirectionWS));
//				half RNoL = saturate(dot(revNormalWS, lightDirectionWS));
//				half finalNoL = min(NoSL, shadowAttenuation);
//				half finalRNoL = min(RNoL, lerp(1.0, shadowAttenuation, 0.5));
//
//
//				half metallic = mixCol.r;
//				//half sss = mixCol.g;
//				half roughness = mixCol.b;
//				metallic = saturate(metallic + _Metal_Multi);
//				roughness = saturate(roughness + _Rough_Multi);
//
//				half oneMinusReflectivity = 1 - metallic;
//				half3 albedo = baseCol.rgb * baseCol.rgb * _Diffuse_Intensity;
//				half3 diffuseCol = albedo * oneMinusReflectivity;
//
//				// Final AO
//				half3 local_713 = 1;
//
//				half3 sh;
//				{
//					half3 normalVS = TransformWorldToViewDir(normalWS);
//					half4 normalFlipVS = half4(normalVS.xy, -normalVS.z, 1.0);
//					half r = dot(normalFlipVS, mul(_EnvSHR, normalFlipVS));
//					half g = dot(normalFlipVS, mul(_EnvSHG, normalFlipVS));
//					half b = dot(normalFlipVS, mul(_EnvSHB, normalFlipVS));
//					sh = half3(r, g, b);
//				}
//
//				// 阴影颜色
//				float3 local_781 = lerp(_Env_Shadow_Factor.xyz, 1.0, finalRNoL);
//				float3 local_784 = mainLight.color.rgb * finalRNoL;
//				float3 local_788 = local_781 * sh * _Envir_Brightness;
//				float3 local_789 = (local_784 + local_788);
//				float3 local_790 = diffuseCol * local_789;
//
//				// 高光颜色 == f0 == SpecularColor
//				float3 specColor = lerp(albedo, 0.04, oneMinusReflectivity);
//
//				float3 local_797 = My_F_Schlick(specColor, VoH);
//				// F_Schlick
//
//				float roughnessRange = lerp(_Min_GGX_Roughness, _Max_GGX_Roughness, roughness);
//				float roughnessRange4 = Pow4(roughnessRange);
//				float local_817 = My_D_GGX(roughnessRange4, NoH);
//				// D_GGX
//
//				half local_831 = My_Vis_Schlick(roughnessRange, NoV, finalNoL);
//				// Vis_Schlick
//
//				// D * G * F
//				// Microfacet specular = D*G*F / (4*NoL*NoV) = D*Vis*F
//				// Vis = G / (4*NoL*NoV)
//				float3 local_852 = (local_817 * local_797 * local_831) * finalNoL;
//				float3 local_853 = local_852;
//
//				float3 reflectVector = reflect(-viewDirectionWS, normalWS);
//				half3 local_931 = GlossyEnvironmentReflection(reflectVector, roughness);
//				float3 local_955 = EnvironmentBRDFApprox(roughnessRange, NoV, specColor);
//
//				float3 local_930 = _Envir_Brightness * local_955 * local_931 * local_781;
//
//				float3 local_1120 = (local_930 * lerp(0.6, 1.0, finalNoL));
//				float3 local_1121 = local_853 + local_1120;
//				// 环境光屏蔽
//				float3 local_1123 = (local_790 + local_1121) * local_713;
//				float3 local_1124 = (local_1123 + 0);
//
//				// 边缘光
//				float local_1125 = (1.0 - NoV);
//				float local_1129 = (_Rim_Power * 1.442695);
//				float local_1131 = (local_1129 + 1.0892349);
//				float local_1132 = (local_1131 * local_1125);
//				float local_1133 = (local_1132 - local_1131);
//				float local_1134 = exp2(local_1133);
//				float local_1126 = local_1134;
//
//				float local_1136 = smoothstep(_U_Rim_Start, _U_Rim_End, local_1126);
//				float3 local_1137 = _Rim_Color.xyz;
//				float3 local_1139 = (local_1136 * local_1137);
//				float3 local_1140 = (local_1139 * _Rim_Multi);
//				float3 local_1141 = _Adjust_Inner.xyz;
//				float3 local_1143 = (local_1124 * local_1141);
//				float3 local_1144 = (local_1143 + local_1140);
//				float local_1145 = (local_1125 + _Inner_Alpha);
//				float3 local_1146 = (local_1144 + _Force_Pixel_Color);
//				float3 local_1147 = local_1146;
//
//				float3 local_1154 = (local_1147 / (local_1147 + 0.187)) * 1.035;
//				float local_1155 = (local_1145 * 1.0);
//				float local_1156 = (local_1155 * _AlphaMtl);
//				float4 local_1157 = float4(local_1154.x, local_1154.y, local_1154.z, local_1156);
//
//				// 置灰
//				float3 local_1163 = float3(0.3, 0.59, 0.11);
//				float local_1164 = dot(local_1121, local_1163);
//				float local_1158 = local_1164;
//
//				float3 local_1166 = sqrt(local_1147);
//				float3 local_1168 = float3(1.5, 1.5, 1.5);
//				float3 local_1169 = (local_1166 / local_1168);
//				float local_1170 = (metallic + _Bloom_Range);
//				float local_1171 = clamp(local_1170, 0.0, 1.0);
//				float local_1172 = (local_1158 * local_1171);
//				float local_1173 = (local_1172 * _Illum_Multi);
//				float local_1174 = (0 * _Emissive_Bloom);
//				float local_1175 = (local_1173 + local_1174);
//				float4 local_1176 = float4(local_1169.x, local_1169.y, local_1169.z, local_1175);
//				float4 local_1177 = float4(_U_Tonemapping_Factor, _U_Tonemapping_Factor, _U_Tonemapping_Factor, _U_Tonemapping_Factor);
//				float4 local_1178 = lerp(local_1176, local_1157, local_1177);
//				float4 local_1179 = local_1178;
//				float4 local_1182 = local_1179;
//				float4 local_1185 = local_1182;
//
//				return local_1185;
//			}
			ENDHLSL

		}

		// Used for rendering shadowmaps
		UsePass "Universal Render Pipeline/Lit/ShadowCaster"

    }
}
