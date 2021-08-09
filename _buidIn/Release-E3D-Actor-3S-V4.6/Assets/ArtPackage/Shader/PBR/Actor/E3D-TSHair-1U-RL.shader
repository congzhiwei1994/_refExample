// Made with Amplify Shader Editor
// Available at the Unity Asset Store - http://u3d.as/y3X 
Shader "E3D/PBRActor/BAHair-2T-RL"
{
	Properties
	{
		[HDR]_AlbedoColor("AlbedoColor", Color) = (0.9779412,0.7868161,0.6831207,0.997)
		_R1SpecalurColor("R1-SpecalurColor", Color) = (0.9632353,0.9038391,0.8499135,0)
		[HDR]_R2SpecalurColor("R2-SpecalurColor", Color) = (0.9632353,0.9038391,0.8499135,0)
		_AnisotropyRang1("Anisotropy-Rang1", Range( 1 , 100)) = 100
		_AnisotropyRang2("Anisotropy-Rang2", Range( 1 , 1000)) = 391.6256
		_MaskMap("MaskMap", 2D) = "white" {}
		_Normal("Normal", 2D) = "bump" {}
		_AnisotropyBiasR("Anisotropy-BiasR", Range( -2 , 2)) = -1
		_AnisotropyBiasG("Anisotropy-BiasG", Range( -2 , 2)) = -1
		_HLFrePower("HL-Fre-Power", Range( 0 , 5)) = 0
		_PBRInstensity("PBR-Instensity", Range( 0 , 1)) = 0
		_Smoothness("Smoothness", Range( 0 , 1)) = 0.2
		_UTiling("U-Tiling", Range( 0.05 , 2)) = 0.05
		_HairAlbedoAO("Hair-Albedo-AO", Range( 0 , 1)) = 1
		_HairSpecularAO("Hair-Specular-AO", Range( 0 , 1)) = 0.7761405
		_SpecularInDark("Specular-InDark", Color) = (0.4720924,0.4571259,0.6544118,0)
		[HideInInspector] _texcoord( "", 2D ) = "white" {}
		[HideInInspector] __dirty( "", Int ) = 1
	}

	SubShader
	{
		Tags{ "RenderType" = "Opaque"  "Queue" = "Geometry+0" }
		Cull Back
		ZWrite On
		CGINCLUDE
		#include "UnityPBSLighting.cginc"
		#include "UnityCG.cginc"
		#include "Lighting.cginc"
		#pragma target 4.5
		#ifdef UNITY_PASS_SHADOWCASTER
			#undef INTERNAL_DATA
			#undef WorldReflectionVector
			#undef WorldNormalVector
			#define INTERNAL_DATA half3 internalSurfaceTtoW0; half3 internalSurfaceTtoW1; half3 internalSurfaceTtoW2;
			#define WorldReflectionVector(data,normal) reflect (data.worldRefl, half3(dot(data.internalSurfaceTtoW0,normal), dot(data.internalSurfaceTtoW1,normal), dot(data.internalSurfaceTtoW2,normal)))
			#define WorldNormalVector(data,normal) half3(dot(data.internalSurfaceTtoW0,normal), dot(data.internalSurfaceTtoW1,normal), dot(data.internalSurfaceTtoW2,normal))
		#endif
		struct Input
		{
			float2 uv_texcoord;
			half3 worldNormal;
			INTERNAL_DATA
			float3 worldPos;
		};

		struct SurfaceOutputCustomLightingCustom
		{
			half3 Albedo;
			half3 Normal;
			half3 Emission;
			half Metallic;
			half Smoothness;
			half Occlusion;
			half Alpha;
			Input SurfInput;
			UnityGIInput GIData;
		};

		uniform sampler2D _MaskMap;
		uniform half _UTiling;
		uniform half _HairAlbedoAO;
		uniform float4 _AlbedoColor;
		uniform sampler2D _Normal;
		uniform half4 _Normal_ST;
		uniform float _Smoothness;
		uniform float _PBRInstensity;
		uniform half4 _SpecularInDark;
		uniform float _AnisotropyBiasR;
		uniform float _AnisotropyBiasG;
		uniform float _AnisotropyRang1;
		uniform float4 _R1SpecalurColor;
		uniform float _AnisotropyRang2;
		uniform float4 _R2SpecalurColor;
		uniform half _HairSpecularAO;
		uniform float _HLFrePower;

		inline half4 LightingStandardCustomLighting( inout SurfaceOutputCustomLightingCustom s, half3 viewDir, UnityGI gi )
		{
			UnityGIInput data = s.GIData;
			Input i = s.SurfInput;
			half4 c = 0;
			#ifdef UNITY_PASS_FORWARDBASE
			float ase_lightAtten = data.atten;
			if( _LightColor0.a == 0)
			ase_lightAtten = 0;
			#else
			float3 ase_lightAttenRGB = gi.light.color / ( ( _LightColor0.rgb ) + 0.000001 );
			float ase_lightAtten = max( max( ase_lightAttenRGB.r, ase_lightAttenRGB.g ), ase_lightAttenRGB.b );
			#endif
			#if defined(HANDLE_SHADOWS_BLENDING_IN_GI)
			half bakedAtten = UnitySampleBakedOcclusion(data.lightmapUV.xy, data.worldPos);
			float zDist = dot(_WorldSpaceCameraPos - data.worldPos, UNITY_MATRIX_V[2].xyz);
			float fadeDist = UnityComputeShadowFadeDistance(data.worldPos, zDist);
			ase_lightAtten = UnityMixRealtimeAndBakedShadows(data.atten, bakedAtten, UnityComputeShadowFade(fadeDist));
			#endif
			half2 appendResult264 = (half2(_UTiling , 1.0));
			float2 uv_TexCoord261 = i.uv_texcoord * appendResult264;
			half4 tex2DNode65 = tex2D( _MaskMap, uv_TexCoord261 );
			half lerpResult269 = lerp( 1.0 , tex2DNode65.b , _HairAlbedoAO);
			half4 temp_output_231_0 = ( lerpResult269 * _AlbedoColor );
			SurfaceOutputStandard s105 = (SurfaceOutputStandard ) 0;
			s105.Albedo = temp_output_231_0.rgb;
			float2 uv_Normal = i.uv_texcoord * _Normal_ST.xy + _Normal_ST.zw;
			s105.Normal = WorldNormalVector( i , UnpackNormal( tex2D( _Normal, uv_Normal ) ) );
			s105.Emission = float3( 0,0,0 );
			s105.Metallic = 0.0;
			s105.Smoothness = _Smoothness;
			s105.Occlusion = 1.0;

			data.light = gi.light;

			UnityGI gi105 = gi;
			#ifdef UNITY_PASS_FORWARDBASE
			Unity_GlossyEnvironmentData g105 = UnityGlossyEnvironmentSetup( s105.Smoothness, data.worldViewDir, s105.Normal, float3(0,0,0));
			gi105 = UnityGlobalIllumination( data, s105.Occlusion, s105.Normal, g105 );
			#endif

			float3 surfResult105 = LightingStandard ( s105, viewDir, gi105 ).rgb;
			surfResult105 += s105.Emission;

			#ifdef UNITY_PASS_FORWARDADD//105
			surfResult105 -= s105.Emission;
			#endif//105
			float4 color227 = IsGammaSpace() ? float4(1,1,1,0) : float4(1,1,1,0);
			half3 clampResult226 = clamp( surfResult105 , float3( 0,0,0 ) , color227.rgb );
			half4 lerpResult125 = lerp( temp_output_231_0 , half4( clampResult226 , 0.0 ) , _PBRInstensity);
			half3 ase_worldBitangent = WorldNormalVector( i, half3( 0, 1, 0 ) );
			half3 ase_worldNormal = WorldNormalVector( i, half3( 0, 0, 1 ) );
			half3 ase_normWorldNormal = normalize( ase_worldNormal );
			half3 worldSpaceViewDir242 = WorldSpaceViewDir( float4( 0,0,0,1 ) );
			half3 normalizeResult243 = normalize( worldSpaceViewDir242 );
			float3 ase_worldPos = i.worldPos;
			#if defined(LIGHTMAP_ON) && UNITY_VERSION < 560 //aseld
			half3 ase_worldlightDir = 0;
			#else //aseld
			half3 ase_worldlightDir = Unity_SafeNormalize( UnityWorldSpaceLightDir( ase_worldPos ) );
			#endif //aseld
			half3 normalizeResult248 = normalize( ase_worldlightDir );
			half3 normalizeResult246 = normalize( ( normalizeResult243 + normalizeResult248 ) );
			half dotResult156 = dot( ( ase_worldBitangent + ( ase_normWorldNormal * ( ( tex2DNode65.r * _AnisotropyBiasR ) + ( tex2DNode65.g * _AnisotropyBiasG ) ) ) ) , normalizeResult246 );
			half temp_output_186_0 = sqrt( sqrt( ( 1.0 - ( dotResult156 * dotResult156 ) ) ) );
			half4 tex2DNode176 = tex2D( _MaskMap, uv_TexCoord261 );
			half lerpResult274 = lerp( 1.0 , tex2DNode176.b , _HairSpecularAO);
			half3 ase_worldViewDir = normalize( UnityWorldSpaceViewDir( ase_worldPos ) );
			half dotResult117 = dot( ase_worldViewDir , ase_worldNormal );
			half4 temp_output_76_0 = ( ( ( pow( temp_output_186_0 , _AnisotropyRang1 ) * _R1SpecalurColor ) + ( pow( temp_output_186_0 , ( _AnisotropyRang2 * tex2DNode176.r ) ) * _R2SpecalurColor * tex2DNode176.r ) ) * lerpResult274 * pow( dotResult117 , _HLFrePower ) );
			half4 temp_cast_3 = (ase_lightAtten).xxxx;
			half4 color257 = IsGammaSpace() ? half4(1,1,1,0) : half4(1,1,1,0);
			half4 lerpResult277 = lerp( temp_cast_3 , color257 , _SpecularInDark.a);
			half4 lerpResult279 = lerp( ( _SpecularInDark * temp_output_76_0 ) , temp_output_76_0 , lerpResult277);
			float4 color241 = IsGammaSpace() ? float4(1.51,1.51,1.51,0) : float4(2.475992,2.475992,2.475992,0);
			half4 clampResult240 = clamp( lerpResult279 , float4( 0,0,0,0 ) , color241 );
			c.rgb = ( lerpResult125 + clampResult240 ).rgb;
			c.a = 1;
			return c;
		}

		inline void LightingStandardCustomLighting_GI( inout SurfaceOutputCustomLightingCustom s, UnityGIInput data, inout UnityGI gi )
		{
			s.GIData = data;
		}

		void surf( Input i , inout SurfaceOutputCustomLightingCustom o )
		{
			o.SurfInput = i;
			o.Normal = float3(0,0,1);
		}

		ENDCG
		CGPROGRAM
		#pragma only_renderers d3d9 d3d11 glcore gles gles3 metal 
		#pragma surface surf StandardCustomLighting keepalpha fullforwardshadows exclude_path:deferred novertexlights nolightmap  nodynlightmap nodirlightmap  11

		ENDCG
		Pass
		{
			Name "ShadowCaster"
			Tags{ "LightMode" = "ShadowCaster" }
			ZWrite On
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma target 4.5
			#pragma multi_compile_shadowcaster
			#pragma multi_compile UNITY_PASS_SHADOWCASTER
			#pragma skip_variants FOG_LINEAR FOG_EXP FOG_EXP2
			#include "HLSLSupport.cginc"
			#if ( SHADER_API_D3D11 || SHADER_API_GLCORE || SHADER_API_GLES3 || SHADER_API_METAL || SHADER_API_VULKAN )
				#define CAN_SKIP_VPOS
			#endif
			#include "UnityCG.cginc"
			#include "Lighting.cginc"
			#include "UnityPBSLighting.cginc"
			struct v2f
			{
				V2F_SHADOW_CASTER;
				float2 customPack1 : TEXCOORD1;
				float4 tSpace0 : TEXCOORD2;
				float4 tSpace1 : TEXCOORD3;
				float4 tSpace2 : TEXCOORD4;
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};
			v2f vert( appdata_full v )
			{
				v2f o;
				UNITY_SETUP_INSTANCE_ID( v );
				UNITY_INITIALIZE_OUTPUT( v2f, o );
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO( o );
				UNITY_TRANSFER_INSTANCE_ID( v, o );
				Input customInputData;
				float3 worldPos = mul( unity_ObjectToWorld, v.vertex ).xyz;
				half3 worldNormal = UnityObjectToWorldNormal( v.normal );
				half3 worldTangent = UnityObjectToWorldDir( v.tangent.xyz );
				half tangentSign = v.tangent.w * unity_WorldTransformParams.w;
				half3 worldBinormal = cross( worldNormal, worldTangent ) * tangentSign;
				o.tSpace0 = float4( worldTangent.x, worldBinormal.x, worldNormal.x, worldPos.x );
				o.tSpace1 = float4( worldTangent.y, worldBinormal.y, worldNormal.y, worldPos.y );
				o.tSpace2 = float4( worldTangent.z, worldBinormal.z, worldNormal.z, worldPos.z );
				o.customPack1.xy = customInputData.uv_texcoord;
				o.customPack1.xy = v.texcoord;
				TRANSFER_SHADOW_CASTER_NORMALOFFSET( o )
				return o;
			}
			half4 frag( v2f IN
			#if !defined( CAN_SKIP_VPOS )
			, UNITY_VPOS_TYPE vpos : VPOS
			#endif
			) : SV_Target
			{
				UNITY_SETUP_INSTANCE_ID( IN );
				Input surfIN;
				UNITY_INITIALIZE_OUTPUT( Input, surfIN );
				surfIN.uv_texcoord = IN.customPack1.xy;
				float3 worldPos = float3( IN.tSpace0.w, IN.tSpace1.w, IN.tSpace2.w );
				half3 worldViewDir = normalize( UnityWorldSpaceViewDir( worldPos ) );
				surfIN.worldPos = worldPos;
				surfIN.worldNormal = float3( IN.tSpace0.z, IN.tSpace1.z, IN.tSpace2.z );
				surfIN.internalSurfaceTtoW0 = IN.tSpace0.xyz;
				surfIN.internalSurfaceTtoW1 = IN.tSpace1.xyz;
				surfIN.internalSurfaceTtoW2 = IN.tSpace2.xyz;
				SurfaceOutputCustomLightingCustom o;
				UNITY_INITIALIZE_OUTPUT( SurfaceOutputCustomLightingCustom, o )
				surf( surfIN, o );
				#if defined( CAN_SKIP_VPOS )
				float2 vpos = IN.pos;
				#endif
				SHADOW_CASTER_FRAGMENT( IN )
			}
			ENDCG
		}
	}
	Fallback "Diffuse"
	CustomEditor "ASEMaterialInspector"
}
/*ASEBEGIN
Version=17500
391;382;1253;503;4798.128;2167.406;9.202664;True;False
Node;AmplifyShaderEditor.CommentaryNode;142;-2626.047,-626.2667;Inherit;False;2756.781;832.3922;E3D-Anisotropy;18;159;148;156;250;140;139;138;137;260;235;258;77;65;259;261;264;265;292;;1,1,1,1;0;0
Node;AmplifyShaderEditor.RangedFloatNode;263;-2609.246,-289.9283;Inherit;False;Property;_UTiling;U-Tiling;12;0;Create;True;0;0;False;0;0.05;0.81;0.05;2;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;265;-2493.246,-202.9283;Inherit;False;Constant;_Float1;Float 1;15;0;Create;True;0;0;False;0;1;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.CommentaryNode;249;-2327.104,309.8827;Inherit;False;1274.582;418.7328;E3D-LightCal;6;246;245;243;248;242;244;;1,1,1,1;0;0
Node;AmplifyShaderEditor.DynamicAppendNode;264;-2328.246,-264.9283;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.WorldSpaceLightDirHlpNode;244;-2259.97,555.5073;Inherit;False;True;1;0;FLOAT;0;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.TextureCoordinatesNode;261;-2180.034,-287.2671;Inherit;False;0;-1;2;3;2;SAMPLER2D;;False;0;FLOAT2;1,1;False;1;FLOAT2;0,0;False;5;FLOAT2;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.WorldSpaceViewDirHlpNode;242;-2255.405,400.7544;Inherit;False;1;0;FLOAT4;0,0,0,1;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.NormalizeNode;248;-1967.555,555.5108;Inherit;False;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.NormalizeNode;243;-1966.199,400.9376;Inherit;False;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RangedFloatNode;259;-1921.07,-107.8598;Float;False;Property;_AnisotropyBiasR;Anisotropy-BiasR;7;0;Create;True;0;0;False;0;-1;0.88;-2;2;0;1;FLOAT;0
Node;AmplifyShaderEditor.SamplerNode;65;-1886.972,-366.3167;Inherit;True;Property;_MaskMap;MaskMap;5;0;Create;True;0;0;False;0;-1;None;51973b6087f556a4bbcdf123991a99ec;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;6;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RangedFloatNode;77;-1919.303,-13.17009;Float;False;Property;_AnisotropyBiasG;Anisotropy-BiasG;8;0;Create;True;0;0;False;0;-1;-1.25;-2;2;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;235;-1430.495,-259.9728;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;258;-1421.201,-140.3304;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;245;-1691.955,435.8533;Inherit;False;2;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.WorldNormalVector;137;-1276.136,-386.6973;Inherit;False;True;1;0;FLOAT3;0,0,1;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.NormalizeNode;246;-1499.021,434.8774;Inherit;False;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleAddOpNode;260;-1220.169,-200.3844;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.WireNode;290;-1075.84,390.3136;Inherit;False;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;138;-1050.354,-303.8076;Inherit;True;2;2;0;FLOAT3;0,0,0;False;1;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.VertexBinormalNode;139;-1048.013,-444.4323;Inherit;False;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.SimpleAddOpNode;140;-775.8087,-352.3529;Inherit;False;2;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.WireNode;250;-810.7062,-114.8984;Inherit;False;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.DotProductOpNode;156;-611.5284,-350.807;Inherit;True;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.WireNode;292;-1385.905,162.3342;Inherit;False;1;0;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;148;-319.1332,-346.0825;Inherit;True;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.CommentaryNode;166;224.8272,579.7133;Inherit;False;862.25;402.7751;Fre-Highlighing;5;118;116;115;117;119;;1,1,1,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;144;227.0894,-456.2935;Inherit;False;2221.765;990.8641;Anisotropy-HighLight-Cal;18;76;191;274;236;238;275;273;164;239;190;176;75;186;161;189;158;284;285;;1,1,1,1;0;0
Node;AmplifyShaderEditor.WireNode;289;-583.4075,234.4724;Inherit;False;1;0;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.OneMinusNode;159;-85.41939,-346.9709;Inherit;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SqrtOpNode;158;285.3924,-349.0692;Inherit;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;189;623.3821,-19.52859;Float;False;Property;_AnisotropyRang2;Anisotropy-Rang2;4;0;Create;True;0;0;False;0;391.6256;728;1;1000;0;1;FLOAT;0
Node;AmplifyShaderEditor.ViewDirInputsCoordNode;115;328.5483,640.1965;Float;False;World;False;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.WorldNormalVector;116;308.542,786.3915;Inherit;False;False;1;0;FLOAT3;0,0,1;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.SamplerNode;176;577.7556,171.5832;Inherit;True;Property;_TextureSample1;Texture Sample 1;5;0;Create;True;0;0;False;0;-1;51973b6087f556a4bbcdf123991a99ec;51973b6087f556a4bbcdf123991a99ec;True;0;False;white;Auto;False;Instance;65;Auto;Texture2D;6;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;284;913.3225,73.62242;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;161;735.1697,-302.6313;Float;False;Property;_AnisotropyRang1;Anisotropy-Rang1;3;0;Create;True;0;0;False;0;100;52.2;1;100;0;1;FLOAT;0
Node;AmplifyShaderEditor.DotProductOpNode;117;546.1309,672.0623;Inherit;True;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;119;478.4738,898.6691;Float;False;Property;_HLFrePower;HL-Fre-Power;9;0;Create;True;0;0;False;0;0;2.13;0;5;0;1;FLOAT;0
Node;AmplifyShaderEditor.SqrtOpNode;186;524.0679,-350.6267;Inherit;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.WireNode;288;-1117.254,-907.9062;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.PowerNode;164;1072.545,-366.8296;Inherit;True;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;273;1284.373,319.5545;Inherit;False;Property;_HairSpecularAO;Hair-Specular-AO;14;0;Create;True;0;0;False;0;0.7761405;0.694;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;275;1370.613,185.0641;Inherit;False;Constant;_Float3;Float 3;15;0;Create;True;0;0;False;0;1;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.ColorNode;239;1291.552,-26.19299;Float;False;Property;_R2SpecalurColor;R2-SpecalurColor;2;1;[HDR];Create;True;0;0;False;0;0.9632353,0.9038391,0.8499135,0;1,0.8970582,0.8970582,0;False;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.PowerNode;190;1072.407,-135.8123;Inherit;True;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.CommentaryNode;287;-503.7484,-1451.504;Inherit;False;718.7348;363.9935;Hair-BAO;3;270;271;269;;1,1,1,1;0;0
Node;AmplifyShaderEditor.ColorNode;75;1331.279,-271.831;Float;False;Property;_R1SpecalurColor;R1-SpecalurColor;1;0;Create;True;0;0;False;0;0.9632353,0.9038391,0.8499135,0;0.308823,0.186202,0.186202,0;False;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.PowerNode;118;775.2787,664.3444;Inherit;True;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;238;1624.63,-361.2302;Inherit;True;2;2;0;FLOAT;0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.RangedFloatNode;270;-346.3623,-1380.763;Inherit;False;Constant;_Float0;Float 0;14;0;Create;True;0;0;False;0;1;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;236;1605.977,-58.34098;Inherit;True;3;3;0;FLOAT;0;False;1;COLOR;0,0,0,0;False;2;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.CommentaryNode;133;1075.605,-1449.815;Inherit;False;2245.839;814.85;E3D-BasePBR-Cal;11;105;221;136;135;120;125;226;227;126;231;291;;1,1,1,1;0;0
Node;AmplifyShaderEditor.WireNode;296;1671.183,627.912;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;271;-400.559,-1243.67;Inherit;False;Property;_HairAlbedoAO;Hair-Albedo-AO;13;0;Create;True;0;0;False;0;1;0.597;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.WireNode;293;-693.0539,-1240.087;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.LerpOp;274;1590.496,196.9889;Inherit;True;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.LerpOp;269;-94.39101,-1352.279;Inherit;True;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.CommentaryNode;280;2526.474,-262.15;Inherit;False;1143.202;767.1252;Specular-InShadow;6;281;277;282;257;252;279;;1,1,1,1;0;0
Node;AmplifyShaderEditor.ColorNode;221;1472.74,-1208.391;Float;False;Property;_AlbedoColor;AlbedoColor;0;1;[HDR];Create;True;0;0;False;0;0.9779412,0.7868161,0.6831207,0.997;0.1617646,0.08801895,0.08801895,0.997;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleAddOpNode;191;1931.646,-228.5316;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.WireNode;285;1939.323,142.9741;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.WireNode;297;1940.116,43.69072;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;231;1963.182,-1321.337;Inherit;True;2;2;0;FLOAT;1;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.LightAttenuation;252;2585.139,-79.01997;Inherit;True;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;120;1484.447,-756.6602;Float;False;Property;_Smoothness;Smoothness;11;0;Create;True;0;0;False;0;0.2;0.26;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;135;1484.003,-840.2689;Float;False;Constant;_Metallic;Metallic;7;0;Create;True;0;0;False;0;0;0;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.ColorNode;257;2586.417,107.2862;Inherit;False;Constant;_Color1;Color 1;14;0;Create;True;0;0;False;0;1,1,1,0;0,0,0,0;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SamplerNode;136;1484.462,-1029.334;Inherit;True;Property;_Normal;Normal;6;0;Create;True;0;0;False;0;-1;None;1deb33f87538867469c4090d1ce52647;True;0;True;bump;Auto;True;Object;-1;Auto;Texture2D;6;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;5;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;76;2199.968,-229.3666;Inherit;True;3;3;0;COLOR;0,0,0,0;False;1;FLOAT;1;False;2;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.ColorNode;282;2588.195,283.4746;Inherit;False;Property;_SpecularInDark;Specular-InDark;15;0;Create;True;0;0;False;0;0.4720924,0.4571259,0.6544118,0;0.2481801,0.2335637,0.2941174,0.06;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;281;2994.718,-215.5662;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.LerpOp;277;2995.197,96.52998;Inherit;True;3;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;2;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.RangedFloatNode;126;2358.559,-777.545;Float;False;Property;_PBRInstensity;PBR-Instensity;10;0;Create;True;0;0;False;0;0;0.205;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.ColorNode;227;2362.58,-963.257;Float;False;Constant;_Color0;Color 0;13;0;Create;True;0;0;False;0;1,1,1,0;0,0,0,0;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.CustomStandardSurface;105;2347.601,-1171.471;Inherit;False;Metallic;Tangent;6;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,1;False;2;FLOAT3;0,0,0;False;3;FLOAT;0;False;4;FLOAT;0;False;5;FLOAT;1;False;1;FLOAT3;0
Node;AmplifyShaderEditor.WireNode;291;2626.595,-1235.971;Inherit;False;1;0;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.ClampOpNode;226;2676.533,-1011.045;Inherit;False;3;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;2;FLOAT3;1,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.WireNode;294;2786.356,-828.9697;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.LerpOp;279;3289.238,-153.9859;Inherit;True;3;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;2;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.ColorNode;241;3776.871,-348.1493;Float;False;Constant;_MaxHDRColor;MaxHDRColor;15;1;[HDR];Create;True;0;0;False;0;1.51,1.51,1.51,0;0,0,0,0;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.LerpOp;125;2976.501,-1031.76;Inherit;False;3;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;2;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.WireNode;283;3751.308,-418.2435;Inherit;False;1;0;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.WireNode;295;3572.297,-760.8766;Inherit;False;1;0;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.ClampOpNode;240;4133.027,-485.2032;Inherit;False;3;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;2;COLOR;1,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleAddOpNode;114;4315.671,-741.6871;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.StandardSurfaceOutputNode;0;4480.482,-970.7655;Half;False;True;-1;5;ASEMaterialInspector;0;0;CustomLighting;E3D/PBRActor/BAHair-2T-RL;False;False;False;False;False;True;True;True;True;False;False;False;False;False;False;False;False;False;False;False;False;Back;1;False;-1;0;False;-1;False;0;False;-1;0;False;-1;False;0;Opaque;0.5;True;True;0;True;Opaque;;Geometry;ForwardOnly;6;d3d9;d3d11;glcore;gles;gles3;metal;True;True;True;True;0;False;-1;False;0;False;-1;255;False;-1;255;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;False;2;15;10;25;False;0.5;True;0;5;False;-1;10;False;-1;0;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;0;0,0,0,0;VertexOffset;True;False;Cylindrical;False;Relative;0;;11;-1;-1;-1;0;False;0;0;False;-1;-1;0;False;-1;0;1;11;0;False;0.1;False;-1;0;False;-1;15;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;2;FLOAT3;0,0,0;False;3;FLOAT3;0,0,0;False;4;FLOAT;0;False;6;FLOAT3;0,0,0;False;7;FLOAT3;0,0,0;False;8;FLOAT;0;False;9;FLOAT;0;False;10;FLOAT;0;False;13;FLOAT3;0,0,0;False;11;FLOAT3;0,0,0;False;12;FLOAT3;0,0,0;False;14;FLOAT4;0,0,0,0;False;15;FLOAT3;0,0,0;False;0
WireConnection;264;0;263;0
WireConnection;264;1;265;0
WireConnection;261;0;264;0
WireConnection;248;0;244;0
WireConnection;243;0;242;0
WireConnection;65;1;261;0
WireConnection;235;0;65;1
WireConnection;235;1;259;0
WireConnection;258;0;65;2
WireConnection;258;1;77;0
WireConnection;245;0;243;0
WireConnection;245;1;248;0
WireConnection;246;0;245;0
WireConnection;260;0;235;0
WireConnection;260;1;258;0
WireConnection;290;0;246;0
WireConnection;138;0;137;0
WireConnection;138;1;260;0
WireConnection;140;0;139;0
WireConnection;140;1;138;0
WireConnection;250;0;290;0
WireConnection;156;0;140;0
WireConnection;156;1;250;0
WireConnection;292;0;261;0
WireConnection;148;0;156;0
WireConnection;148;1;156;0
WireConnection;289;0;292;0
WireConnection;159;0;148;0
WireConnection;158;0;159;0
WireConnection;176;1;289;0
WireConnection;284;0;189;0
WireConnection;284;1;176;1
WireConnection;117;0;115;0
WireConnection;117;1;116;0
WireConnection;186;0;158;0
WireConnection;288;0;65;3
WireConnection;164;0;186;0
WireConnection;164;1;161;0
WireConnection;190;0;186;0
WireConnection;190;1;284;0
WireConnection;118;0;117;0
WireConnection;118;1;119;0
WireConnection;238;0;164;0
WireConnection;238;1;75;0
WireConnection;236;0;190;0
WireConnection;236;1;239;0
WireConnection;236;2;176;1
WireConnection;296;0;118;0
WireConnection;293;0;288;0
WireConnection;274;0;275;0
WireConnection;274;1;176;3
WireConnection;274;2;273;0
WireConnection;269;0;270;0
WireConnection;269;1;293;0
WireConnection;269;2;271;0
WireConnection;191;0;238;0
WireConnection;191;1;236;0
WireConnection;285;0;296;0
WireConnection;297;0;274;0
WireConnection;231;0;269;0
WireConnection;231;1;221;0
WireConnection;76;0;191;0
WireConnection;76;1;297;0
WireConnection;76;2;285;0
WireConnection;281;0;282;0
WireConnection;281;1;76;0
WireConnection;277;0;252;0
WireConnection;277;1;257;0
WireConnection;277;2;282;4
WireConnection;105;0;231;0
WireConnection;105;1;136;0
WireConnection;105;3;135;0
WireConnection;105;4;120;0
WireConnection;291;0;231;0
WireConnection;226;0;105;0
WireConnection;226;2;227;0
WireConnection;294;0;126;0
WireConnection;279;0;281;0
WireConnection;279;1;76;0
WireConnection;279;2;277;0
WireConnection;125;0;291;0
WireConnection;125;1;226;0
WireConnection;125;2;294;0
WireConnection;283;0;279;0
WireConnection;295;0;125;0
WireConnection;240;0;283;0
WireConnection;240;2;241;0
WireConnection;114;0;295;0
WireConnection;114;1;240;0
WireConnection;0;13;114;0
ASEEND*/
//CHKSM=413EB47A333BCE26D2C128D99FFCA3F9152024D0