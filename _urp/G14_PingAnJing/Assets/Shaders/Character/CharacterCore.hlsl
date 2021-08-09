#ifndef CHARACTER_CORE_INCLUDED
	#define CHARACTER_CORE_INCLUDED

	#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
	#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"


	/*
	USE_TONE
	USE_SSS
	USE_ANISOTROPIC
	USE_NEW_ANISOTROPIC
	USE_CARTOON
	USE_AO
	USE_EMISSIVE
	USE_ALPHAMAP
	USE_CHANGE_AMOUNT_RIM_AND_ADJUST_INNER
	USE_BURN
	USE_CHANGE_COLOR
	USE_NO_TONEMAPPING_FACTOR
	USE_CLIP_LERP
	USE_FNOL
	USE_SCALE_NORMAL_07
	*/



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

	TEXTURE2D(_BaseMap);
	SAMPLER(sampler_BaseMap);

	TEXTURE2D(_MixMap);
	SAMPLER(sampler_MixMap);

	TEXTURE2D(_NormalMap);
	SAMPLER(sampler_NormalMap);

	TEXTURE2D(_EnvTex);
	SAMPLER(sampler_EnvTex);

	#ifdef USE_ANISOTROPIC
		TEXTURE2D(_AnisotropicMap);
		SAMPLER(sampler_AnisotropicMap);
	#endif

	#ifdef USE_ALPHAMAP
		TEXTURE2D(_AlphaMap);
		SAMPLER(sampler_AlphaMap);
	#endif

	#ifdef USE_BURN
		TEXTURE2D(_BurnMap);
		SAMPLER(sampler_BurnMap);

		TEXTURE2D(_BurnNoiseMap);
		SAMPLER(sampler_BurnNoiseMap);
	#endif

	#ifdef USE_CHANGE_COLOR
		TEXTURE2D(_ChangeColorMap);
		SAMPLER(sampler_ChangeColorMap);
	#endif

	CBUFFER_START(UnityPerMaterial)
	#ifdef USE_CLIP_LERP
		half _Cull_Lerp;
	#endif
	#ifdef USE_TONE
		half3 _Dir_Tone;
		half _Dir_Light_Intensity;
		half3 _Env_Tone;
		half _ChangeAmount;
	#endif
	#ifdef USE_CHANGE_AMOUNT_RIM_AND_ADJUST_INNER
		half _ChangeAmount;
	#endif
	#ifdef USE_ANISOTROPIC
		half _Noise_Offset;
		half _Normal_Offset;
	#endif
	#ifdef USE_SSS
		half _SSS_Factor;
	#endif
	#ifdef USE_AO
		half _AO_Slider;
	#endif
	#ifdef USE_EMISSIVE
		half _Emissive_Intensity;
		half _Emissive_Bloom;
	#endif
	#ifdef USE_NEW_ANISOTROPIC
		half4 _NewAnisoFactor;
	#endif
	#ifdef USE_CARTOON
		half4 _CartoonFactor;
	#endif
	#ifdef USE_CHANGE_COLOR
		half3 _Changecolor1;
		half3 _Changecolor2;
		half3 _Changecolor3;
		half3 _Changecolor4;
		half3 _Changecolor5;
		half3 _Changecolor6;
		half4 _Change_adj1;
		half4 _Change_adj2;
		half4 _Change_adj3;
	#endif
	#ifdef USE_BURN
		half2 _Noise_Speed01;
		half2 _Noise_Speed02;
		half _Noise_Density01;
		half _Noise_Density02;
		half _Tortuosity_Intensity01;
		half _Tortuosity_Intensity02;
		half _Mask_Intensity;
		half _Noise_Intensity02;
		half _Burn_Amount;
		half _Burn_Line_Width;
		half3 _Burn_Color01;
		half3 _Burn_Color02;
		half3 _Burn_Color03;
		half _AlphaAmount;
		half _Black_Height;
		half _ColorUPAmount;
	#endif
	half _Min_GGX_Roughness;
	half _Max_GGX_Roughness;
	half _Metal_Multi;
	half _Rough_Multi;
	half _Diffuse_Intensity;
	half _U_Light_Scale;
	half2 _Shadow_Bias_Factor;
	half4 _Env_Shadow_Factor;
	half _Envir_Brightness;
	half _Max_Brightness;
	half _Envir_Fresnel_Brightness;
	half _Rim_Power;
	half _U_Rim_Start;
	half _U_Rim_End;
	half3 _Rim_Color;
	half _Rim_Multi;
	half3 _Force_Pixel_Color;
	half3 _Adjust_Inner;
	half _Inner_Alpha;
	half _AlphaMtl;
	#ifndef USE_NO_TONEMAPPING_FACTOR
		half _U_Tonemapping_Factor;
	#endif
	half _Bloom_Range;
	half _Illum_Multi;
	CBUFFER_END

	float4x4 _EnvSHR;
	float4x4 _EnvSHG;
	float4x4 _EnvSHB;




	real3 UnpackNormalRG_Optimize(real2 packedNormal, real z)
	{
		real3 normal;
		normal.xy = packedNormal.rg * 2.0 - 1.0;
		normal.z = z;
		return normal;
	}

	real3 TransformTangentToWorld_Scale(real3 dirTS, real scale, real3x3 tangentToWorld)
	{
		// Note matrix is in row major convention with left multiplication as it is build on the fly
		dirTS.xy *= scale;
		return TransformTangentToWorld(dirTS, tangentToWorld);
	}

	// GGX / Trowbridge-Reitz
	// [Walter et al. 2007, "Microfacet models for refraction through rough surfaces"]
	float My_D_GGX(float a, float NoH)
	{
		float a2 = a * a;
		float d = (NoH * a2 - NoH) * NoH + 1;	// 2 mad
		return min(a2 / (d*d), 10000.0);					// 4 mul, 1 rcp
	}

	// Tuned to match behavior of Vis_Smith
	// [Schlick 1994, "An Inexpensive BRDF Model for Physically-Based Rendering"]
	float My_Vis_Schlick(float a, float NoV, float NoL)
	{
		//float k = sqrt(a2) * 0.5;
		float k = a;

		float Vis_SchlickV = NoV * (1 - k) + k;
		float Vis_SchlickL = NoL * (1 - k) + k;
		return 0.25 / (Vis_SchlickV * Vis_SchlickL);
	}



	// [Schlick 1994, "An Inexpensive BRDF Model for Physically-Based Rendering"]
	real3 My_F_Schlick(real3 f0, real f90, real u)
	{
		real x = 1.0 - u;
		real x2 = x * x;
		real x5 = x * x2 * x2;

		return f0 * (1.0 - x5) + (f90 * x5);        // sub mul mul mul sub mul mad*3
	}
	real3 My_F_Schlick(real3 f0, real u)
	{
		return My_F_Schlick(f0, 1.0, u);               // sub mul mul mul sub mad*3
	}

	// [ Lazarov 2013, "Getting More Physical in Call of Duty: Black Ops II" ]
	float3 EnvironmentBRDFApprox(float roughness, float NoV, float3 f0)
	{
		const float4 c0 = float4(-1.0, -0.0275, -0.572, 0.022);
		const float4 c1 = float4(1.0, 0.0425, 1.04, -0.04);

		float4 r = roughness * c0 + c1;
		float a004 = min(r.x * r.x, exp2(-9.28 * NoV)) * r.x + r.y;
		float2 AB = float2(-1.04, 1.04) * a004 + r.zw;

		return f0 * AB.x + AB.y * _Envir_Fresnel_Brightness;
	}

	float GetSpecularOcclusion(float NoV, float ao_slider, float ao)
	{
		// 非正对视线的地方AO越不明显
		half a = lerp(1.0, ao, NoV);

		// (2 * saturate(0.5 - AO)) * AO_slider
		// 分段函数：
		// AO(0.5到1) 永远为0
		// AO(0到0.5) AO_slider到0线性变化
		float k = (2 * saturate(0.5 - ao)) * ao_slider;

		// 越黑的地方就用回原来的黑度，较浅的地方，会根据视线减弱AO，越是grazing角度越浅
		return lerp(a, ao, k);
	}

	half3 GlossyEnvironmentReflection(half3 reflectVector, half perceptualRoughness)
	{
		// 0-7
		half mip = (perceptualRoughness) / 0.14;
		float u = ((atan2(reflectVector.z, reflectVector.x) + 3.141593) * 0.15915491);
		float v = (acos(reflectVector.y) * 0.3183099);
		float2 uv = float2(u, v);
		half4 envColor = SAMPLE_TEXTURE2D_X_LOD(_EnvTex, sampler_EnvTex, uv, mip);
		half3 finalEnvColor = envColor.xyz * envColor.w;
		return finalEnvColor * _Max_Brightness;
	}


	half3 ShaderSH(half3 normalVS)
	{
		half4 normalFlipVS = half4(normalVS.xy, -normalVS.z, 1.0);
		half r = dot(normalFlipVS, mul(_EnvSHR, normalFlipVS));
		half g = dot(normalFlipVS, mul(_EnvSHG, normalFlipVS));
		half b = dot(normalFlipVS, mul(_EnvSHB, normalFlipVS));
		return half3(r, g, b);
	}

	// GPU Gems1 - 16 次表面散射的实时近似（Real-Time Approximations to Subsurface Scattering）
	half WrapDiffuse(half NoL, half wrap)
	{
		// 原实现:
		return max(0.0, (NoL + wrap) / (1 + wrap));
		//return max(0.0, NoL + wrap) / (1 + wrap);
	}

	half3 CalcRim(half NoV)
	{
		half rim = smoothstep(_U_Rim_Start, _U_Rim_End, pow(1 - NoV, _Rim_Power));
		#ifdef USE_CHANGE_AMOUNT_RIM_AND_ADJUST_INNER
			half rimMulti = lerp(0.0, _Rim_Multi, _ChangeAmount);
		#else
			half rimMulti = _Rim_Multi;
		#endif
		return rim * _Rim_Color.rgb * rimMulti;
	}

	Varyings LitPassVertex(Attributes input)
	{
		Varyings output;
		VertexPositionInputs vertexInput = GetVertexPositionInputs(input.positionOS.xyz);
		VertexNormalInputs vertexNormalInput = GetVertexNormalInputs(input.normalOS, input.tangentOS);

		output.uv = input.uv;

		float fogFactor = ComputeFogFactor(vertexInput.positionCS.z);
		output.positionWSAndFogFactor = float4(vertexInput.positionWS, fogFactor);
		output.normalWS = vertexNormalInput.normalWS;
		output.positionCS = vertexInput.positionCS;
		output.tangentWS = vertexNormalInput.tangentWS;
		output.bitangentWS = vertexNormalInput.bitangentWS;
		#ifdef _MAIN_LIGHT_SHADOWS
			output.shadowCoord = GetShadowCoord(vertexInput);
		#else
			output.shadowCoord = 0;
		#endif
		return output;
	}


	half4 LitPassFragment(Varyings input) : SV_Target
	{
		// 贴图采样
		half4 baseCol = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, input.uv.xy);
		#ifdef USE_ALPHAMAP
			baseCol.a = SAMPLE_TEXTURE2D_X_LOD(_AlphaMap, sampler_AlphaMap, input.uv, 0).a;
		#endif

		half3 mixCol = SAMPLE_TEXTURE2D(_MixMap, sampler_MixMap, input.uv.xy).rgb;
		half4 normalCol = SAMPLE_TEXTURE2D(_NormalMap, sampler_NormalMap, input.uv.xy);
		#ifdef USE_ANISOTROPIC
			half4 anisotropicCol = SAMPLE_TEXTURE2D(_AnisotropicMap, sampler_AnisotropicMap, input.uv.xy);
		#endif
		#ifdef USE_CHANGE_COLOR
			half3 changeColorCol = SAMPLE_TEXTURE2D(_ChangeColorMap, sampler_ChangeColorMap, input.uv.xy).rgb;
			// 0 - 0.25
			half3 changeChannel_Low = saturate(changeColorCol * 4.0);
			// 0.25 - 1
			half3 changeChannel_high = saturate((changeColorCol - 0.25) / 0.75);

			baseCol.rgb = lerp(baseCol.rgb, _Changecolor1.rgb, changeChannel_Low.r);
			baseCol.rgb = lerp(baseCol.rgb, _Changecolor2.rgb, changeChannel_high.r);
			baseCol.rgb = lerp(baseCol.rgb, _Changecolor3.rgb, changeChannel_Low.g);
			baseCol.rgb = lerp(baseCol.rgb, _Changecolor4.rgb, changeChannel_high.g);
			baseCol.rgb = lerp(baseCol.rgb, _Changecolor5.rgb, changeChannel_Low.b);
			baseCol.rgb = lerp(baseCol.rgb, _Changecolor6.rgb, changeChannel_high.b);

			// 粗糙
			half mixChannelB_adj1 = lerp(_Change_adj1.y, _Change_adj1.w, changeChannel_high.r) * changeChannel_Low.r;
			half mixChannelB_adj2 = lerp(_Change_adj2.y, _Change_adj2.w, changeChannel_high.g) * changeChannel_Low.g;
			half mixChannelB_adj3 = lerp(_Change_adj3.y, _Change_adj3.w, changeChannel_high.b) * changeChannel_Low.b;
			half mixChannelB = mixCol.b + mixChannelB_adj1 + mixChannelB_adj2 + mixChannelB_adj3;

			// 金属
			float mixChannelR_adj1 = lerp(_Change_adj1.x, _Change_adj1.z, changeChannel_high.r) * changeChannel_Low.r;
			float mixChannelR_adj2 = lerp(_Change_adj2.x, _Change_adj2.z, changeChannel_high.g) * changeChannel_Low.g;
			float mixChannelR_adj3 = lerp(_Change_adj3.x, _Change_adj3.z, changeChannel_high.b) * changeChannel_Low.b;
			float mixChannelR = mixCol.r + +mixChannelR_adj1 + mixChannelR_adj2 + mixChannelR_adj3;

			mixCol.rb = saturate(float2(mixChannelR, mixChannelB));
		#endif

		// TBN生成
		half3x3 TBN = half3x3(input.tangentWS.xyz, input.bitangentWS.xyz, input.normalWS.xyz);
		// 世界法线
		// 这里只使用packednormal.xy 的值，并将normal.z 赋值为 1，因为面部法线的z取1时正好可以去除面部的自投影。
		half3 normalTS = UnpackNormalRG_Optimize(normalCol.rg, 1.0);
		#ifndef USE_AO
			// 目前观察没有AO就用0.7
			const half normalMapScale = 0.7;
		#else
			const half normalMapScale = 1.0;
		#endif

		half3 normalWS = normalize(TransformTangentToWorld_Scale(normalTS, normalMapScale, TBN));
		half3 normalVS = TransformWorldToViewDir(normalWS);



		
		///////////////////////////////////////////////////////////////
		// 世界翻转法线
		half3 flipNormalTS = UnpackNormalRG_Optimize(normalCol.rg, 1.0);
		flipNormalTS.xy = -flipNormalTS.xy;
		half3 flipNormalWS = normalize(TransformTangentToWorld_Scale(flipNormalTS, 1.0, TBN));
		///////////////////////////////////////////////////////////////




		#ifdef USE_ANISOTROPIC
			// 世界各向异性法线
			half3 anisotropicNormalTS = UnpackNormalRG_Optimize(anisotropicCol.rg, 0);
			half3 anisotropicNormalWS = normalize(TransformTangentToWorld_Scale(anisotropicNormalTS, 1.0, TBN));
		#endif


		// 光照计算数据
		float3 positionWS = input.positionWSAndFogFactor.xyz;
		Light mainLight = GetMainLight(input.shadowCoord);
		#ifdef USE_TONE
			half3 lightColor = lerp(_Dir_Tone.rgb * _Dir_Light_Intensity, mainLight.color.rgb, _ChangeAmount);
		#else
			half3 lightColor = mainLight.color.rgb;
		#endif

		half3 lightDirectionWS = mainLight.direction;
		half3 scaleLightDirectionWS = lightDirectionWS * _U_Light_Scale;
		
		half3 viewDirectionWS = SafeNormalize(GetCameraPositionWS() - positionWS);
		half3 halfDirectionWS = SafeNormalize(float3(lightDirectionWS) + float3(viewDirectionWS));
		half3 reflectVectorWS = reflect(-viewDirectionWS, normalWS);
		half shadowAttenuation = mainLight.shadowAttenuation;
		#ifdef USE_CARTOON
			shadowAttenuation = lerp(shadowAttenuation, 1.0, _CartoonFactor.w);
		#endif
		// 点积数据
		half VoH = saturate(dot(viewDirectionWS, halfDirectionWS));
		half NoH = max(0, dot(normalWS, halfDirectionWS));
		half NoV = saturate(dot(normalWS, viewDirectionWS));
		half NoSL = dot(normalWS, scaleLightDirectionWS);
		half FNoL01 = saturate(dot(flipNormalWS, lightDirectionWS));
		half NoSL01 = saturate(NoSL);
		half finalNoL = min(NoSL01, shadowAttenuation);
		half finalFNoL = min(FNoL01, lerp(1.0, shadowAttenuation, 0.5));

		#ifdef USE_SSS
			// remap -1到1 但去掉-1到0的值（即去掉原图0-0.5的值，取0.5-1）
			half sss = saturate((mixCol.g * 2) - 1);
			half finalSSS = sss * _SSS_Factor;
			// wrap lighting
			float NoSL01_wrap = WrapDiffuse(NoSL, 0.45);
			half finalNoL_wrap = min(NoSL01_wrap, shadowAttenuation);
			finalNoL_wrap *= finalNoL_wrap;
			finalNoL = lerp(finalNoL, finalNoL_wrap, finalSSS);
		#endif

		#ifdef USE_SSS
			half diffuseNoL = finalNoL;
		#else
			// 这是不对的，不知道是不是平安京写错
			//half diffuseNoL = finalFNoL;
			half diffuseNoL = finalNoL;
		#endif

		
		#ifdef USE_ANISOTROPIC
			//-------------------------------
			// 计算各向异性
			// anisotropicCol.b - 0.5 意思是从0-1 remap到 -0.5 到 0.5，因为后面有_Noise_Offset了，所以不用再乘2或其它
			half normalScale = _Normal_Offset + ((anisotropicCol.b - 0.5) * _Noise_Offset);
			half anisotropicMask = step(mixCol.g, 0.25);
			anisotropicNormalWS = normalize((normalWS * normalScale) + anisotropicNormalWS);
			half VoA = saturate(dot(anisotropicNormalWS, viewDirectionWS));
			half aniso = max(0.0, sin(VoA * PI));
			NoH = lerp(NoH, aniso, anisotropicMask);
		#endif

		// 各种材质输入参数
		half ao = normalCol.b;
		#ifdef USE_CARTOON
			ao = lerp(ao, 1.0, _CartoonFactor.z);
		#endif
		half metallic = mixCol.r;
		half roughness = mixCol.b;
		metallic = saturate(metallic + _Metal_Multi);
		roughness = saturate(roughness + _Rough_Multi);

		// half roughnessRange = lerp(_Min_GGX_Roughness, _Max_GGX_Roughness, roughness);
		half roughnessRange = lerp(_Min_GGX_Roughness, _Max_GGX_Roughness, roughness);
		half roughnessRange2 = roughnessRange * roughnessRange;
		half oneMinusReflectivity = 1 - metallic;
		half3 albedo = baseCol.rgb * baseCol.rgb * _Diffuse_Intensity;
		half3 diffColor = albedo * oneMinusReflectivity;
		// 高光颜色 == f0 == SpecularColor
		half3 specColor = lerp(albedo, 0.04, oneMinusReflectivity);
		// 控制暗部颜色
		float3 colorNoL = lerp(_Env_Shadow_Factor.xyz, 1.0, diffuseNoL);
		half finalAO = 1.0;
		#ifdef USE_AO
			// 调整过的AO
			finalAO = GetSpecularOcclusion(NoV, _AO_Slider, ao);
		#endif

		

		//-------------------------------
		// 计算Subsurface Scattering
		half3 sssResult = 0;
		half3 sssIndirectResult = 0;
		#ifdef USE_SSS
			// TODO永远0???
			half finalNoL_NegativePart = clamp(finalNoL, -1.0, 0.0);
			// RGB值小于0.35的恒定(baseCol.rgb - 0.1)，越大于0.35，得到值越暗
			half3 sssColor = saturate(baseCol.rgb - max(max(max(baseCol.r, baseCol.g), baseCol.b) - 0.39, 0.1));
			half unknowSSS_1 = smoothstep(0.51, 0.0, ((finalNoL_NegativePart + finalNoL) / 2.0));
			half sssNoSL = 1 - lerp(saturate(NoSL), saturate(-NoSL), 0.61);
			half sssNoSL_wrap = WrapDiffuse(sssNoSL, -0.47);
			sssResult = (((sssNoSL_wrap * unknowSSS_1 * finalSSS * sssColor) * 2.35) * 0.3);
			sssIndirectResult = (2.0 - NoV) * sssColor * finalSSS;
		#endif

		//-------------------------------
		// 计算间接Diffuse
		// 计算sh(间接Diffuse)
		half3 sh = ShaderSH(normalVS);
		half3 indirectDiffuse = colorNoL + sssIndirectResult;
		half3 indirectDiffuseTerm = sh * indirectDiffuse * _Envir_Brightness;

		//-------------------------------
		// 计算直接Diffuse
		half3 diffuse = diffuseNoL + sssResult;
		half3 diffuseTerm = diffuse * lightColor;

		//-------------------------------
		// 计算Diffuse(直接+间接)
		half3 diffuseTotal = diffColor * (indirectDiffuseTerm + diffuseTerm);


		//-------------------------------
		// 计算直接Specular BRDF
		half3 F = My_F_Schlick(specColor, VoH);
		half D = My_D_GGX(roughnessRange2, NoH);
		// 使粗糙度增加(迪士尼法则)
		half visRoughnessRange = 0.5 * roughnessRange + 0.5;
		half Vis = My_Vis_Schlick(visRoughnessRange * visRoughnessRange, NoV, finalNoL);
		// Vis = G / (4*NoL*NoV)
		// Microfacet specular = D*G*F / (4*NoL*NoV) = D*Vis*F
		half3 specularTerm = D * Vis * F;
		// 直接高光应用NoL，因为每个部分的NoL可能不一样，单独应用
		specularTerm *= finalNoL;

		//-------------------------------
		// 计算间接Specular BRDF
		half3 indirectSpecular = GlossyEnvironmentReflection(reflectVectorWS, roughness);
		half3 indirectSpecularColor = EnvironmentBRDFApprox(roughnessRange, NoV, specColor);
		half3 indirectSpecularTerm = indirectSpecularColor * indirectSpecular * _Envir_Brightness;
		// 间接高光应用颜色
		indirectSpecularTerm *= colorNoL;
		half3 saveIndirectSpecularTerm = indirectSpecularTerm;
		// 间接高光应用NoL(减弱暗部亮度)
		indirectSpecularTerm *= lerp(0.6, 1.0, finalNoL);

		//-------------------------------
		// 计算Specular(直接+间接)
		// TODO: 这里没有使用LightColor?
		half3 specularTotal = specularTerm + indirectSpecularTerm;

		// 边缘光
		half3 rimColor = CalcRim(NoV);

		// 自发光
		half3 emissiveColor = 0;
		half emissiveMask = 0;
		#ifdef USE_EMISSIVE
			// Alpha通道只取0.5-1之间的值映射为0-1的值
			emissiveMask = saturate(baseCol.a - 0.5) * 2.0;
			emissiveColor = (emissiveMask * _Emissive_Intensity) * diffColor;
		#endif

		// 应用环境光屏蔽
		// TODO: AO连直接光也屏蔽????
		half3 color = (diffuseTotal + specularTotal) * finalAO;
		// 应用自发光
		color += emissiveColor;

		// 应用边缘光,_Adjust_Inner,_Force_Pixel_Color
		#ifdef USE_CHANGE_AMOUNT_RIM_AND_ADJUST_INNER
			half3 adjustInner = lerp(1.0, _Adjust_Inner.rgb, _ChangeAmount);
		#else
			half3 adjustInner = _Adjust_Inner.rgb;
		#endif
		color = (adjustInner * color) + rimColor + _Force_Pixel_Color;
		half alpha = ((1.0 - NoV) + _Inner_Alpha) * _AlphaMtl;


		#ifdef USE_NO_TONEMAPPING_FACTOR
			float specularLuminance = saturate(dot(saveIndirectSpecularTerm, float3(0.3, 0.59, 0.11)) - 0.02);
			float local_1156 = lerp(specularLuminance, 1.0, baseCol.a);
			float local_1162 = saturate((1.0 - NoV) - (1.0 - (0.5 * roughnessRange)));
			float local_1163 = (local_1162 / roughnessRange);
			float local_1165 = (local_1163 * 6.0);
			float local_1166 = (local_1156 * local_1165);
			float local_1167 = (local_1156 + local_1166);
			alpha *= local_1167;
		#else


			half3 colorA = sqrt(color) / 1.5;
			float specularLuminance = dot(specularTotal, float3(0.3, 0.59, 0.11));
			half illumBloom = (specularLuminance * saturate(metallic + _Bloom_Range)) * _Illum_Multi;
			half emissiveBloom = 0;
			#ifdef USE_EMISSIVE
				emissiveBloom = emissiveMask * _Emissive_Bloom;
			#endif
			half alphaA = illumBloom + emissiveBloom;


		#endif

		//return half4(step(1.00001, color), 0);

		// 色调映射(HDR到LDR)可以和gamma组合在一起
		// Tone mapper
		// https://docs.unrealengine.com/udk/Three/ColorGrading.html
		// GammaColor = LinearColor / (LinearColor + 0.187) * 1.035;
		half3 colorB = (color / (color + 0.187)) * 1.035;
		#ifdef USE_CLIP_LERP
			alpha *= lerp(1.0, baseCol.a, _Cull_Lerp);
		#endif
		half alphaB = alpha;


		
		#ifdef USE_NO_TONEMAPPING_FACTOR
			float4 finalColor = half4(colorB, alphaB);
		#else
			float4 finalColor = lerp(half4(colorA, alphaA), half4(colorB, alphaB), _U_Tonemapping_Factor);
		#endif


		#ifdef USE_BURN
			half2 burnUV = input.uv.xy;
			half4 burnCol = SAMPLE_TEXTURE2D(_BurnMap, sampler_BurnMap, burnUV);
			// BurnUV动画区域
			float burnMask = burnCol.g;
			
			// 算uv
			float2 noiseMapUV = ((_Noise_Speed01 * _Time.y) + burnUV) * _Noise_Density01;
			half4 burnNoiseCol_1 = SAMPLE_TEXTURE2D(_BurnNoiseMap, sampler_BurnNoiseMap, noiseMapUV);
			// 在-1和1之间
			float2 burnTortuosityUV = (burnNoiseCol_1.rg * 2.0) - 1.0;

			float2 local_588 = ((_Noise_Speed02 * _Time.y) + burnUV);
			float2 local_589 = (_Tortuosity_Intensity02 * burnTortuosityUV);
			float2 local_591 = ((local_588 + local_589) * _Noise_Density02);
			half4 burnNoiseCol_2 = SAMPLE_TEXTURE2D(_BurnNoiseMap, sampler_BurnNoiseMap, local_591);
			// remap -1 to 1
			float maskNoise_NP1 = (burnNoiseCol_2.z * 2.0) - 1.0;

			float2 tortuosityUV = burnUV + (_Tortuosity_Intensity01 * burnTortuosityUV) + (burnMask * _Mask_Intensity);
			half4 burnCol_2 = SAMPLE_TEXTURE2D(_BurnMap, sampler_BurnMap, tortuosityUV);
			float burnTortuosityFire = burnCol_2.r;
			float flowNoise = (maskNoise_NP1 * _Noise_Intensity02);
			float local_610 = ((flowNoise + burnTortuosityFire) * burnMask);
			float finalBurnMask_01 = saturate(local_610);

			// _Burn_Line_Width 基线偏移(0-1)
			float finalMaskCutDown_01 = max(finalBurnMask_01 - _Burn_Line_Width, 0.0);
			// 缩小了_Burn_Color01的区域_Burn_Color01表外焰 内焰,焰心
			float colorRange = smoothstep(0.6, 1.0, finalMaskCutDown_01);
			//return lerp(colorRange.xxxx, finalMaskCutDown_01.xxxx, _DebugValue1);
			float3 local_618 = lerp(_Burn_Color02, _Burn_Color01, colorRange);
			float local_630 = saturate(finalMaskCutDown_01 / 0.7);
			float3 local_632 = lerp(_Burn_Color03, local_618, local_630);

			float local_619 = normalTS.x;
			float local_620 = normalTS.y;
			float local_622 = abs(local_619) * _ColorUPAmount;
			float local_623 = (local_622 + 1.0);
			float local_625 = abs(local_620) * _ColorUPAmount;
			float local_626 = (local_625 + 1.0);
			float local_627 = (local_623 * local_626);
			// local_627 立体,光线亮面提亮_Burn_Color03
			float3 local_633 = (local_627 * local_632);

			float burnAmount = (1.0 - _Burn_Amount);
			float local_641 = smoothstep(burnAmount - 0.1, burnAmount + 0.2, finalBurnMask_01 + _Black_Height);


			finalColor.rgb = lerp(finalColor.rgb, finalColor.rgb + local_633, local_641);

			float local_646 = (1.0 - _AlphaAmount);
			float local_647 = smoothstep(local_646, 1.0, finalMaskCutDown_01);
			float local_648 = (1.0 - local_647);
			finalColor.a = local_648;
		#endif


		return finalColor;
	}


#endif