// Made with Amplify Shader Editor
// Available at the Unity Asset Store - http://u3d.as/y3X 
Shader "E3D/PBRActor/3S-Skin-BPR-4T"
{
	Properties
	{
		_Albedo("Albedo", 2D) = "white" {}
		_BaseColor("BaseColor", Color) = (0,0,0,0)
		_NormalMap("NormalMap", 2D) = "bump" {}
		_DetailMap("DetailMap", 2D) = "white" {}
		_NoiseBump("NoiseBump", Range( 0 , 2)) = 1
		_MaskMap("MaskMap", 2D) = "white" {}
		_AOIntensity("AO-Intensity", Range( 0 , 1)) = 1
		_3SOffset("3S-Offset", Range( 0 , 2)) = 0.5
		_RampMap("RampMap", 2D) = "white" {}
		[Toggle]_3SSwitch("3S-Switch", Float) = 1
		_3SColor("3S-Color", Color) = (0,0,0,0)
		_3SColorEmissionBack("3SColor-EmissionBack", Color) = (0,1,0.1724138,0)
		_Metallic("Metallic", Range( 0 , 2)) = 0.7639677
		_Smoothness("Smoothness", Range( 0 , 2)) = 0.7639677
		[Header(Translucency)]
		_Translucency("Strength", Range( 0 , 50)) = 1
		_TransNormalDistortion("Normal Distortion", Range( 0 , 1)) = 0.1
		_TransScattering("Scaterring Falloff", Range( 1 , 50)) = 2
		_TransDirect("Direct", Range( 0 , 1)) = 1
		_TransAmbient("Ambient", Range( 0 , 1)) = 0.2
		_TransShadow("Shadow", Range( 0 , 1)) = 0.9
		[HideInInspector] _texcoord( "", 2D ) = "white" {}
		[HideInInspector] __dirty( "", Int ) = 1
	}

	SubShader
	{
		Tags{ "RenderType" = "Opaque"  "Queue" = "Geometry+0" "IsEmissive" = "true"  }
		Cull Back
		ZTest LEqual
		CGINCLUDE
		#include "UnityCG.cginc"
		#include "UnityPBSLighting.cginc"
		#include "Lighting.cginc"
		#pragma target 3.0
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
			float3 worldPos;
			half3 worldNormal;
			INTERNAL_DATA
		};

		struct SurfaceOutputStandardCustom
		{
			half3 Albedo;
			half3 Normal;
			half3 Emission;
			half Metallic;
			half Smoothness;
			half Occlusion;
			half Alpha;
			half3 Translucency;
		};

		uniform sampler2D _NormalMap;
		uniform half4 _NormalMap_ST;
		uniform sampler2D _DetailMap;
		uniform half4 _DetailMap_ST;
		uniform half _NoiseBump;
		uniform sampler2D _MaskMap;
		uniform half4 _MaskMap_ST;
		uniform float4 _BaseColor;
		uniform sampler2D _Albedo;
		uniform half4 _Albedo_ST;
		uniform float _3SOffset;
		uniform float4 _3SColorEmissionBack;
		uniform float _Metallic;
		uniform float _Smoothness;
		uniform float _AOIntensity;
		uniform half _Translucency;
		uniform half _TransNormalDistortion;
		uniform half _TransScattering;
		uniform half _TransDirect;
		uniform half _TransAmbient;
		uniform half _TransShadow;
		uniform half _3SSwitch;
		uniform float4 _3SColor;
		uniform sampler2D _RampMap;

		inline half4 LightingStandardCustom(SurfaceOutputStandardCustom s, half3 viewDir, UnityGI gi )
		{
			#if !DIRECTIONAL
			float3 lightAtten = gi.light.color;
			#else
			float3 lightAtten = lerp( _LightColor0.rgb, gi.light.color, _TransShadow );
			#endif
			half3 lightDir = gi.light.dir + s.Normal * _TransNormalDistortion;
			half transVdotL = pow( saturate( dot( viewDir, -lightDir ) ), _TransScattering );
			half3 translucency = lightAtten * (transVdotL * _TransDirect + gi.indirect.diffuse * _TransAmbient) * s.Translucency;
			half4 c = half4( s.Albedo * translucency * _Translucency, 0 );

			SurfaceOutputStandard r;
			r.Albedo = s.Albedo;
			r.Normal = s.Normal;
			r.Emission = s.Emission;
			r.Metallic = s.Metallic;
			r.Smoothness = s.Smoothness;
			r.Occlusion = s.Occlusion;
			r.Alpha = s.Alpha;
			return LightingStandard (r, viewDir, gi) + c;
		}

		inline void LightingStandardCustom_GI(SurfaceOutputStandardCustom s, UnityGIInput data, inout UnityGI gi )
		{
			#if defined(UNITY_PASS_DEFERRED) && UNITY_ENABLE_REFLECTION_BUFFERS
				gi = UnityGlobalIllumination(data, s.Occlusion, s.Normal);
			#else
				UNITY_GLOSSY_ENV_FROM_SURFACE( g, s, data );
				gi = UnityGlobalIllumination( data, s.Occlusion, s.Normal, g );
			#endif
		}

		void surf( Input i , inout SurfaceOutputStandardCustom o )
		{
			float2 uv_NormalMap = i.uv_texcoord * _NormalMap_ST.xy + _NormalMap_ST.zw;
			half3 tex2DNode12 = UnpackNormal( tex2D( _NormalMap, uv_NormalMap ) );
			half4 color93 = IsGammaSpace() ? half4(0.5019608,0.5019608,1,0) : half4(0.2158605,0.2158605,1,0);
			float2 uv_DetailMap = i.uv_texcoord * _DetailMap_ST.xy + _DetailMap_ST.zw;
			half4 tex2DNode60 = tex2D( _DetailMap, uv_DetailMap );
			float2 uv_MaskMap = i.uv_texcoord * _MaskMap_ST.xy + _MaskMap_ST.zw;
			half4 tex2DNode21 = tex2D( _MaskMap, uv_MaskMap );
			half4 lerpResult94 = lerp( color93 , tex2DNode60 , saturate( ( _NoiseBump * ( 1.0 - ( ( tex2DNode21.g + 0.0 ) * 2.0 ) ) ) ));
			half4 break95 = lerpResult94;
			half3 appendResult78 = (half3(( tex2DNode12.r + break95.r ) , ( break95.g + tex2DNode12.g ) , ( tex2DNode12.b + tex2DNode60.b )));
			half3 normalizeResult85 = normalize( ( ( 2.0 * appendResult78 ) + -0.43 ) );
			o.Normal = normalizeResult85;
			float2 uv_Albedo = i.uv_texcoord * _Albedo_ST.xy + _Albedo_ST.zw;
			half4 temp_output_11_0 = ( _BaseColor * tex2D( _Albedo, uv_Albedo ) );
			o.Albedo = temp_output_11_0.rgb;
			float3 ase_worldPos = i.worldPos;
			#if defined(LIGHTMAP_ON) && UNITY_VERSION < 560 //aseld
			half3 ase_worldlightDir = 0;
			#else //aseld
			half3 ase_worldlightDir = normalize( UnityWorldSpaceLightDir( ase_worldPos ) );
			#endif //aseld
			half3 ase_worldNormal = WorldNormalVector( i, half3( 0, 0, 1 ) );
			half dotResult32 = dot( ase_worldlightDir , ase_worldNormal );
			half temp_output_35_0 = saturate( (dotResult32*_3SOffset + 0.5) );
			o.Emission = ( ( 1.0 - temp_output_35_0 ) * temp_output_11_0 * _3SColorEmissionBack ).rgb;
			o.Metallic = _Metallic;
			o.Smoothness = ( tex2DNode21.r * _Smoothness );
			half lerpResult82 = lerp( 1.0 , tex2DNode21.b , _AOIntensity);
			o.Occlusion = lerpResult82;
			half4 temp_cast_2 = (0.0).xxxx;
			half2 temp_cast_3 = (temp_output_35_0).xx;
			o.Translucency = (( _3SSwitch )?( saturate( ( tex2DNode21.g * _3SColor * tex2D( _RampMap, temp_cast_3 ) * (dotResult32*0.85 + 0.27) ) ) ):( temp_cast_2 )).rgb;
			o.Alpha = 1;
		}

		ENDCG
		CGPROGRAM
		#pragma surface surf StandardCustom keepalpha fullforwardshadows exclude_path:deferred 

		ENDCG
		Pass
		{
			Name "ShadowCaster"
			Tags{ "LightMode" = "ShadowCaster" }
			ZWrite On
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma target 3.0
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
				SurfaceOutputStandardCustom o;
				UNITY_INITIALIZE_OUTPUT( SurfaceOutputStandardCustom, o )
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
178;352;1253;503;1516.299;896.7897;1.445677;True;False
Node;AmplifyShaderEditor.CommentaryNode;97;-2524.976,-1900.577;Inherit;False;2955.698;1055.021;NormalBlender;20;100;85;91;87;92;78;90;76;79;77;12;95;94;93;60;99;96;102;105;103;;1,1,1,1;0;0
Node;AmplifyShaderEditor.SamplerNode;21;-1549.755,394.925;Inherit;True;Property;_MaskMap;MaskMap;5;0;Create;True;0;0;False;0;-1;None;3542647dd1252164d97237936233de61;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;6;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RangedFloatNode;105;-2564.724,-927.6584;Inherit;False;Constant;_Float4;Float 4;15;0;Create;True;0;0;False;0;2;0;0;12;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;98;-2476.811,-1169.076;Inherit;True;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;103;-2252.724,-1058.658;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;96;-2353.161,-1309.049;Inherit;False;Property;_NoiseBump;NoiseBump;4;0;Create;True;0;0;False;0;1;1.2;0;2;0;1;FLOAT;0
Node;AmplifyShaderEditor.OneMinusNode;99;-2077.164,-1189.89;Inherit;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;100;-1888.461,-1216.775;Inherit;True;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SaturateNode;102;-1629.051,-1216.904;Inherit;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SamplerNode;60;-1782.295,-1456.557;Inherit;True;Property;_DetailMap;DetailMap;3;0;Create;True;0;0;False;0;-1;None;517b361a418b5864699ffd72cfb6cd48;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;6;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.ColorNode;93;-1721.114,-1652.491;Inherit;False;Constant;_Color0;Color 0;14;0;Create;True;0;0;False;0;0.5019608,0.5019608,1,0;0,0,0,0;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.WorldSpaceLightDirHlpNode;31;-2688.837,-255.1099;Inherit;False;False;1;0;FLOAT;0;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.WorldNormalVector;30;-2644.659,-117.3423;Inherit;False;False;1;0;FLOAT3;0,0,0;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.LerpOp;94;-1414.16,-1474.364;Inherit;True;3;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;2;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.RangedFloatNode;33;-1958.288,-147.8455;Float;False;Property;_3SOffset;3S-Offset;7;0;Create;True;0;0;False;0;0.5;0.17;0;2;0;1;FLOAT;0
Node;AmplifyShaderEditor.DotProductOpNode;32;-2377.693,-199.6373;Inherit;True;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;59;-1954.834,-69.74673;Float;False;Constant;_Float0;Float 0;15;0;Create;True;0;0;False;0;0.5;0;0;2;0;1;FLOAT;0
Node;AmplifyShaderEditor.SamplerNode;12;-1417.3,-1191.684;Inherit;True;Property;_NormalMap;NormalMap;2;0;Create;True;0;0;False;0;-1;None;1e9c94fcfa28db24e8f3efd9f22e87a4;True;0;True;bump;Auto;True;Object;-1;Auto;Texture2D;6;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;1;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;5;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.BreakToComponentsNode;95;-1139.89,-1474.138;Inherit;False;COLOR;1;0;COLOR;0,0,0,0;False;16;FLOAT;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4;FLOAT;5;FLOAT;6;FLOAT;7;FLOAT;8;FLOAT;9;FLOAT;10;FLOAT;11;FLOAT;12;FLOAT;13;FLOAT;14;FLOAT;15
Node;AmplifyShaderEditor.ScaleAndOffsetNode;34;-1586.217,-167.0434;Inherit;True;3;0;FLOAT;0;False;1;FLOAT;1;False;2;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;108;-2321.001,266.54;Inherit;False;Constant;_Float5;Float 5;15;0;Create;True;0;0;False;0;0.27;0.27;-1;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;109;-2326.44,163.9768;Inherit;False;Constant;_Float6;Float 6;16;0;Create;True;0;0;False;0;0.85;0.85;-1;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;77;-863.9643,-1351.556;Inherit;True;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;76;-856.0263,-1585.573;Inherit;True;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;79;-851.0903,-1117.022;Inherit;True;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ScaleAndOffsetNode;107;-1955.447,152.3154;Inherit;True;3;0;FLOAT;0;False;1;FLOAT;1;False;2;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SaturateNode;35;-1260.875,-166.8039;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;90;-563.9378,-1449.584;Inherit;False;Constant;_Float2;Float 2;14;0;Create;True;0;0;False;0;2;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RelayNode;106;-146.6783,184.3684;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.DynamicAppendNode;78;-593.2047,-1331.141;Inherit;True;FLOAT3;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.ColorNode;6;-418.7569,-71.01105;Float;False;Property;_3SColor;3S-Color;10;0;Create;True;0;0;False;0;0,0,0,0;1,0,0,0;False;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SamplerNode;36;-837.9774,1.714665;Inherit;True;Property;_RampMap;RampMap;8;0;Create;True;0;0;False;0;-1;None;469a7c91254dda2408bc42abafdd51a5;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;6;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;87;-310.4379,-1427.483;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SamplerNode;9;-805.9276,-557.064;Inherit;True;Property;_Albedo;Albedo;0;0;Create;True;0;0;False;0;-1;None;b3ce7bc3bf614344c8fdd033cbf7c5dd;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;6;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;1;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.ColorNode;10;-771.1101,-742.5295;Float;False;Property;_BaseColor;BaseColor;1;0;Create;True;0;0;False;0;0,0,0,0;0.8823529,0.875865,0.875865,0;False;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RangedFloatNode;83;-749.0721,868.8274;Inherit;False;Constant;_Float1;Float 1;14;0;Create;True;0;0;False;0;1;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;92;-330.738,-1323.584;Inherit;False;Constant;_Float3;Float 3;14;0;Create;True;0;0;False;0;-0.43;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;8;55.96514,-43.77344;Inherit;True;4;4;0;FLOAT;0;False;1;COLOR;0,0,0,0;False;2;COLOR;0,0,0,0;False;3;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.RangedFloatNode;57;-838.0796,976.1384;Float;False;Property;_AOIntensity;AO-Intensity;6;0;Create;True;0;0;False;0;1;1;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.LerpOp;82;-418.0352,872.1509;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ColorNode;43;-426.7034,-297.86;Float;False;Property;_3SColorEmissionBack;3SColor-EmissionBack;11;0;Create;True;0;0;False;0;0,1,0.1724138,0;0.6029412,0.5320069,0.5320069,0;False;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RangedFloatNode;18;-798.2668,476.6119;Float;False;Property;_Smoothness;Smoothness;13;0;Create;True;0;0;False;0;0.7639677;1.13;0;2;0;1;FLOAT;0
Node;AmplifyShaderEditor.OneMinusNode;44;-430.043,-379.3867;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;91;-113.5381,-1418.483;Inherit;True;2;2;0;FLOAT3;0,0,0;False;1;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RangedFloatNode;81;82.66536,-131.429;Inherit;False;Constant;_Black;Black;14;0;Create;True;0;0;False;0;0;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SaturateNode;110;259.8301,23.92738;Inherit;False;1;0;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;11;-462.2128,-628.8449;Inherit;True;2;2;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;41;53.33026,-356.7828;Inherit;True;3;3;0;FLOAT;0;False;1;COLOR;0,0,0,0;False;2;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.RangedFloatNode;16;370.71,-180.5264;Float;False;Property;_Metallic;Metallic;12;0;Create;True;0;0;False;0;0.7639677;0;0;2;0;1;FLOAT;0
Node;AmplifyShaderEditor.NormalizeNode;85;121.0097,-1416.93;Inherit;True;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;23;-388.2755,398.1871;Inherit;True;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RelayNode;84;161.7224,871.3933;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.TextureCoordinatesNode;17;-2206.922,-498.7475;Inherit;False;0;9;2;3;2;SAMPLER2D;;False;0;FLOAT2;1,1;False;1;FLOAT2;0,0;False;5;FLOAT2;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.ToggleSwitchNode;80;404.4295,-66.08544;Inherit;True;Property;_3SSwitch;3S-Switch;9;0;Create;True;0;0;False;0;1;2;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.StandardSurfaceOutputNode;0;774.0132,-225.855;Half;False;True;-1;2;ASEMaterialInspector;0;0;Standard;E3D/PBRActor/3S-Skin-BPR-4T;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;Back;0;False;-1;3;False;-1;False;0;False;-1;0;False;-1;False;0;Opaque;0.5;True;True;0;False;Opaque;;Geometry;ForwardOnly;14;all;True;True;True;True;0;False;-1;False;0;False;-1;255;False;-1;255;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;False;0;4;10;25;False;0.5;True;0;0;False;-1;0;False;-1;0;0;False;-1;0;False;-1;1;False;-1;1;False;-1;0;False;0;0,0,0,0;VertexOffset;True;False;Cylindrical;False;Relative;0;;-1;14;-1;-1;0;False;0;0;False;-1;-1;0;False;-1;0;0;0;False;0.1;False;-1;0;False;-1;16;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;2;FLOAT3;0,0,0;False;3;FLOAT;0;False;4;FLOAT;0;False;5;FLOAT;0;False;6;FLOAT3;0,0,0;False;7;FLOAT3;0,0,0;False;8;FLOAT;0;False;9;FLOAT;0;False;10;FLOAT;0;False;13;FLOAT3;0,0,0;False;11;FLOAT3;0,0,0;False;12;FLOAT3;0,0,0;False;14;FLOAT4;0,0,0,0;False;15;FLOAT3;0,0,0;False;0
WireConnection;98;0;21;2
WireConnection;103;0;98;0
WireConnection;103;1;105;0
WireConnection;99;0;103;0
WireConnection;100;0;96;0
WireConnection;100;1;99;0
WireConnection;102;0;100;0
WireConnection;94;0;93;0
WireConnection;94;1;60;0
WireConnection;94;2;102;0
WireConnection;32;0;31;0
WireConnection;32;1;30;0
WireConnection;95;0;94;0
WireConnection;34;0;32;0
WireConnection;34;1;33;0
WireConnection;34;2;59;0
WireConnection;77;0;95;1
WireConnection;77;1;12;2
WireConnection;76;0;12;1
WireConnection;76;1;95;0
WireConnection;79;0;12;3
WireConnection;79;1;60;3
WireConnection;107;0;32;0
WireConnection;107;1;109;0
WireConnection;107;2;108;0
WireConnection;35;0;34;0
WireConnection;106;0;107;0
WireConnection;78;0;76;0
WireConnection;78;1;77;0
WireConnection;78;2;79;0
WireConnection;36;1;35;0
WireConnection;87;0;90;0
WireConnection;87;1;78;0
WireConnection;8;0;21;2
WireConnection;8;1;6;0
WireConnection;8;2;36;0
WireConnection;8;3;106;0
WireConnection;82;0;83;0
WireConnection;82;1;21;3
WireConnection;82;2;57;0
WireConnection;44;0;35;0
WireConnection;91;0;87;0
WireConnection;91;1;92;0
WireConnection;110;0;8;0
WireConnection;11;0;10;0
WireConnection;11;1;9;0
WireConnection;41;0;44;0
WireConnection;41;1;11;0
WireConnection;41;2;43;0
WireConnection;85;0;91;0
WireConnection;23;0;21;1
WireConnection;23;1;18;0
WireConnection;84;0;82;0
WireConnection;80;0;81;0
WireConnection;80;1;110;0
WireConnection;0;0;11;0
WireConnection;0;1;85;0
WireConnection;0;2;41;0
WireConnection;0;3;16;0
WireConnection;0;4;23;0
WireConnection;0;5;84;0
WireConnection;0;7;80;0
ASEEND*/
//CHKSM=55A3FCDDA7C9A16E6AAE6579847D5CACEDCB3400