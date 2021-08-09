// Made with Amplify Shader Editor
// Available at the Unity Asset Store - http://u3d.as/y3X 
Shader "E3D/PBRActor/3S-Skin-BPR-4T/Test"
{
	Properties
	{
		_TessValue( "Max Tessellation", Range( 1, 32 ) ) = 4
		_TessMin( "Tess Min Distance", Float ) = 10
		_TessMax( "Tess Max Distance", Float ) = 25
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
		#include "Tessellation.cginc"
		#include "Lighting.cginc"
		#pragma target 4.6
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
		uniform float _TessValue;
		uniform float _TessMin;
		uniform float _TessMax;

		float4 tessFunction( appdata_full v0, appdata_full v1, appdata_full v2 )
		{
			return UnityDistanceBasedTess( v0.vertex, v1.vertex, v2.vertex, _TessMin, _TessMax, _TessValue );
		}

		void vertexDataFunc( inout appdata_full v )
		{
		}

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
			half Mask_G114 = tex2DNode21.g;
			half4 lerpResult94 = lerp( color93 , tex2DNode60 , saturate( ( _NoiseBump * ( 1.0 - ( ( Mask_G114 + 0.0 ) * 2.0 ) ) ) ));
			half4 break95 = lerpResult94;
			half3 appendResult78 = (half3(( tex2DNode12.r + break95.r ) , ( break95.g + tex2DNode12.g ) , ( tex2DNode12.b + tex2DNode60.b )));
			half3 normalizeResult85 = normalize( ( ( 2.0 * appendResult78 ) + -0.43 ) );
			half3 Normal130 = normalizeResult85;
			o.Normal = Normal130;
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
			half NoL121 = dotResult32;
			half RampUV125 = saturate( (NoL121*_3SOffset + 0.5) );
			o.Emission = ( ( 1.0 - RampUV125 ) * temp_output_11_0 * _3SColorEmissionBack ).rgb;
			o.Metallic = _Metallic;
			half Mask_R113 = tex2DNode21.r;
			o.Smoothness = ( Mask_R113 * _Smoothness );
			half Mask_B115 = tex2DNode21.b;
			half lerpResult82 = lerp( 1.0 , Mask_B115 , _AOIntensity);
			o.Occlusion = lerpResult82;
			half4 temp_cast_2 = (0.0).xxxx;
			half2 temp_cast_3 = (RampUV125).xx;
			half4 Translucency111 = (( _3SSwitch )?( saturate( ( Mask_G114 * _3SColor * tex2D( _RampMap, temp_cast_3 ) * (NoL121*0.85 + 0.27) ) ) ):( temp_cast_2 ));
			o.Translucency = Translucency111.rgb;
			o.Alpha = 1;
		}

		ENDCG
		CGPROGRAM
		#pragma surface surf StandardCustom keepalpha fullforwardshadows exclude_path:deferred vertex:vertexDataFunc tessellate:tessFunction 

		ENDCG
		Pass
		{
			Name "ShadowCaster"
			Tags{ "LightMode" = "ShadowCaster" }
			ZWrite On
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma target 4.6
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
				vertexDataFunc( v );
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
-4;463;1906;724;341.4418;705.9199;1;True;False
Node;AmplifyShaderEditor.CommentaryNode;120;720.4467,-1883.501;Inherit;False;684.5164;360.0001;MaskMap;4;21;113;115;114;MaskMap;1,1,1,1;0;0
Node;AmplifyShaderEditor.SamplerNode;21;770.4467,-1822.304;Inherit;True;Property;_MaskMap;MaskMap;10;0;Create;True;0;0;False;0;-1;None;3542647dd1252164d97237936233de61;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;6;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.CommentaryNode;97;-2806.954,-2017.85;Inherit;False;3410.506;1085.628;NormalBlender;23;130;85;91;87;92;90;78;79;76;77;12;95;94;93;102;60;100;96;99;103;105;98;117;;1,1,1,1;0;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;114;1144.963,-1758.501;Inherit;False;Mask_G;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.CommentaryNode;124;1604.349,-1858.609;Inherit;False;852.8101;366.7676;NoL;4;30;31;32;121;NoL;1,1,1,1;0;0
Node;AmplifyShaderEditor.GetLocalVarNode;117;-2763.677,-1292.396;Inherit;False;114;Mask_G;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.WorldSpaceLightDirHlpNode;31;1654.349,-1808.609;Inherit;False;False;1;0;FLOAT;0;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.SimpleAddOpNode;98;-2517.789,-1206.349;Inherit;True;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;105;-2608.702,-1044.932;Inherit;False;Constant;_Float4;Float 4;15;0;Create;True;0;0;False;0;2;0;0;12;0;1;FLOAT;0
Node;AmplifyShaderEditor.WorldNormalVector;30;1698.527,-1670.841;Inherit;False;False;1;0;FLOAT3;0,0,0;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.DotProductOpNode;32;1965.493,-1753.136;Inherit;True;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;103;-2296.702,-1175.931;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;121;2214.16,-1750.818;Inherit;False;NoL;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.CommentaryNode;128;741.6378,-1433.099;Inherit;False;1113.133;386.2753;RampUV;6;59;33;34;123;35;125;RampUV;1,1,1,1;0;0
Node;AmplifyShaderEditor.OneMinusNode;99;-2119.94,-1199.014;Inherit;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;96;-2195.26,-1313.366;Inherit;False;Property;_NoiseBump;NoiseBump;9;0;Create;True;0;0;False;0;1;0.8468186;0;2;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;33;781.6389,-1290.626;Float;False;Property;_3SOffset;3S-Offset;12;0;Create;True;0;0;False;0;0.5;0;0;2;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;59;795.0928,-1202.527;Float;False;Constant;_Float0;Float 0;15;0;Create;True;0;0;False;0;0.5;0;0;2;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;100;-1909.607,-1277.57;Inherit;True;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;123;894.8998,-1371.099;Inherit;False;121;NoL;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.ColorNode;93;-1797.536,-1810.621;Inherit;False;Constant;_Color0;Color 0;14;0;Create;True;0;0;False;0;0.5019608,0.5019608,1,0;0,0,0,0;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.ScaleAndOffsetNode;34;1163.71,-1299.824;Inherit;True;3;0;FLOAT;0;False;1;FLOAT;1;False;2;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SamplerNode;60;-1904.381,-1510.142;Inherit;True;Property;_DetailMap;DetailMap;8;0;Create;True;0;0;False;0;-1;None;517b361a418b5864699ffd72cfb6cd48;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;6;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SaturateNode;102;-1676.634,-1283.708;Inherit;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.CommentaryNode;129;-4332.017,433.112;Inherit;False;2443.584;645.6686;Translucency;14;126;36;6;109;111;80;110;81;8;106;118;107;122;108;Translucency;1,1,1,1;0;0
Node;AmplifyShaderEditor.LerpOp;94;-1476.162,-1722.619;Inherit;True;3;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;2;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.SaturateNode;35;1431.052,-1299.584;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;108;-3880.579,949.0057;Inherit;False;Constant;_Float5;Float 5;21;0;Create;True;0;0;False;0;0.27;0.27;-1;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;125;1611.771,-1299.401;Inherit;False;RampUV;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;122;-3786.605,774.1469;Inherit;False;121;NoL;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.BreakToComponentsNode;95;-1217.514,-1709.174;Inherit;False;COLOR;1;0;COLOR;0,0,0,0;False;16;FLOAT;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4;FLOAT;5;FLOAT;6;FLOAT;7;FLOAT;8;FLOAT;9;FLOAT;10;FLOAT;11;FLOAT;12;FLOAT;13;FLOAT;14;FLOAT;15
Node;AmplifyShaderEditor.RangedFloatNode;109;-3886.018,846.4428;Inherit;False;Constant;_Float6;Float 6;22;0;Create;True;0;0;False;0;0.85;0.85;-1;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.SamplerNode;12;-1295.448,-1528.861;Inherit;True;Property;_NormalMap;NormalMap;7;0;Create;True;0;0;False;0;-1;None;1e9c94fcfa28db24e8f3efd9f22e87a4;True;0;True;bump;Auto;True;Object;-1;Auto;Texture2D;6;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;1;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;5;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.GetLocalVarNode;126;-3753.961,630.9203;Inherit;False;125;RampUV;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;77;-892.3202,-1471.233;Inherit;True;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;79;-895.0678,-1234.295;Inherit;True;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;76;-892.7939,-1737.695;Inherit;True;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ScaleAndOffsetNode;107;-3515.025,834.7812;Inherit;True;3;0;FLOAT;0;False;1;FLOAT;1;False;2;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RelayNode;106;-3188.485,834.9101;Inherit;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ColorNode;6;-3247.565,468.53;Float;False;Property;_3SColor;3S-Color;15;0;Create;True;0;0;False;0;0,0,0,0;1,0,0,0;False;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SamplerNode;36;-3553.784,620.2558;Inherit;True;Property;_RampMap;RampMap;13;0;Create;True;0;0;False;0;-1;None;469a7c91254dda2408bc42abafdd51a5;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;6;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.DynamicAppendNode;78;-637.1823,-1448.414;Inherit;True;FLOAT3;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RangedFloatNode;90;-550.2357,-1594.496;Inherit;False;Constant;_Float2;Float 2;14;0;Create;True;0;0;False;0;2;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;118;-2978.394,477.2131;Inherit;False;114;Mask_G;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;92;-375.9172,-1420.429;Inherit;False;Constant;_Float3;Float 3;14;0;Create;True;0;0;False;0;-0.43;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;87;-354.4154,-1544.756;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;8;-2766.841,570.7679;Inherit;True;4;4;0;FLOAT;0;False;1;COLOR;0,0,0,0;False;2;COLOR;0,0,0,0;False;3;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.SaturateNode;110;-2531.386,582.7874;Inherit;False;1;0;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.RangedFloatNode;81;-2663.141,479.112;Inherit;False;Constant;_Black;Black;14;0;Create;True;0;0;False;0;0;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;115;1161.963,-1638.501;Inherit;False;Mask_B;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ColorNode;10;-4129.138,-895.9114;Float;False;Property;_BaseColor;BaseColor;6;0;Create;True;0;0;False;0;0,0,0,0;0.8823529,0.8758649,0.8758649,0;False;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SamplerNode;9;-4163.956,-710.4464;Inherit;True;Property;_Albedo;Albedo;5;0;Create;True;0;0;False;0;-1;None;b3ce7bc3bf614344c8fdd033cbf7c5dd;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;6;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;1;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleAddOpNode;91;-157.5157,-1535.756;Inherit;True;2;2;0;FLOAT3;0,0,0;False;1;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.NormalizeNode;85;77.03209,-1534.203;Inherit;True;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.ToggleSwitchNode;80;-2362.561,487.2293;Inherit;True;Property;_3SSwitch;3S-Switch;14;0;Create;True;0;0;False;0;1;2;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.GetLocalVarNode;127;-3393.184,-729.0032;Inherit;False;125;RampUV;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;83;-3754.996,-21.2093;Inherit;False;Constant;_Float1;Float 1;14;0;Create;True;0;0;False;0;1;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;119;-3716.077,101.5858;Inherit;False;115;Mask_B;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;11;-3820.241,-782.2271;Inherit;True;2;2;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.RangedFloatNode;57;-3854.004,155.1017;Float;False;Property;_AOIntensity;AO-Intensity;11;0;Create;True;0;0;False;0;1;1;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;113;1153.963,-1833.501;Inherit;False;Mask_R;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.LerpOp;82;-3433.959,51.11421;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;116;-3325.959,-248.8854;Inherit;False;113;Mask_R;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.WireNode;133;-3287.996,-918.201;Inherit;False;1;0;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.OneMinusNode;44;-3211.071,-726.7692;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;111;-2103.088,532.921;Inherit;False;Translucency;-1;True;1;0;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;130;378.989,-1534.003;Inherit;False;Normal;-1;True;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RangedFloatNode;18;-3462.551,-137.3639;Float;False;Property;_Smoothness;Smoothness;18;0;Create;True;0;0;False;0;0.7639677;1.09;0;2;0;1;FLOAT;0
Node;AmplifyShaderEditor.ColorNode;43;-3472.731,-474.2424;Float;False;Property;_3SColorEmissionBack;3SColor-EmissionBack;16;0;Create;True;0;0;False;0;0,1,0.1724138,0;0.6029412,0.5320069,0.5320069,0;False;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.WireNode;134;-3483.996,-588.201;Inherit;False;1;0;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;23;-2936.297,-228.5881;Inherit;True;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.WireNode;132;-2515.996,-826.201;Inherit;False;1;0;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.RelayNode;84;-2854.202,50.35661;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;16;-2848.915,-411.563;Float;False;Property;_Metallic;Metallic;17;0;Create;True;0;0;False;0;0.7639677;0.5105928;0;2;0;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;131;-2801.371,-690.7812;Inherit;False;130;Normal;1;0;OBJECT;;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;41;-3086.698,-535.1651;Inherit;True;3;3;0;FLOAT;0;False;1;COLOR;0,0,0,0;False;2;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.GetLocalVarNode;112;-2558.066,-9.091293;Inherit;False;111;Translucency;1;0;OBJECT;;False;1;COLOR;0
Node;AmplifyShaderEditor.StandardSurfaceOutputNode;0;1237.532,-710.728;Half;False;True;-1;6;ASEMaterialInspector;0;0;Standard;E3D/PBRActor/3S-Skin-BPR-4T/Test;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;Back;0;False;-1;3;False;-1;False;0;False;-1;0;False;-1;False;0;Opaque;0.5;True;True;0;False;Opaque;;Geometry;ForwardOnly;14;all;True;True;True;True;0;False;-1;False;0;False;-1;255;False;-1;255;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;True;0;4;10;25;False;0.5;True;0;0;False;-1;0;False;-1;0;0;False;-1;0;False;-1;1;False;-1;1;False;-1;0;False;0;0,0,0,0;VertexOffset;True;False;Cylindrical;False;Relative;0;;-1;19;-1;0;0;False;0;0;False;-1;-1;0;False;-1;0;0;0;False;0.1;False;-1;0;False;-1;16;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;2;FLOAT3;0,0,0;False;3;FLOAT;0;False;4;FLOAT;0;False;5;FLOAT;0;False;6;FLOAT3;0,0,0;False;7;FLOAT3;0,0,0;False;8;FLOAT;0;False;9;FLOAT;0;False;10;FLOAT;0;False;13;FLOAT3;0,0,0;False;11;FLOAT3;0,0,0;False;12;FLOAT3;0,0,0;False;14;FLOAT4;0,0,0,0;False;15;FLOAT3;0,0,0;False;0
WireConnection;114;0;21;2
WireConnection;98;0;117;0
WireConnection;32;0;31;0
WireConnection;32;1;30;0
WireConnection;103;0;98;0
WireConnection;103;1;105;0
WireConnection;121;0;32;0
WireConnection;99;0;103;0
WireConnection;100;0;96;0
WireConnection;100;1;99;0
WireConnection;34;0;123;0
WireConnection;34;1;33;0
WireConnection;34;2;59;0
WireConnection;102;0;100;0
WireConnection;94;0;93;0
WireConnection;94;1;60;0
WireConnection;94;2;102;0
WireConnection;35;0;34;0
WireConnection;125;0;35;0
WireConnection;95;0;94;0
WireConnection;77;0;95;1
WireConnection;77;1;12;2
WireConnection;79;0;12;3
WireConnection;79;1;60;3
WireConnection;76;0;12;1
WireConnection;76;1;95;0
WireConnection;107;0;122;0
WireConnection;107;1;109;0
WireConnection;107;2;108;0
WireConnection;106;0;107;0
WireConnection;36;1;126;0
WireConnection;78;0;76;0
WireConnection;78;1;77;0
WireConnection;78;2;79;0
WireConnection;87;0;90;0
WireConnection;87;1;78;0
WireConnection;8;0;118;0
WireConnection;8;1;6;0
WireConnection;8;2;36;0
WireConnection;8;3;106;0
WireConnection;110;0;8;0
WireConnection;115;0;21;3
WireConnection;91;0;87;0
WireConnection;91;1;92;0
WireConnection;85;0;91;0
WireConnection;80;0;81;0
WireConnection;80;1;110;0
WireConnection;11;0;10;0
WireConnection;11;1;9;0
WireConnection;113;0;21;1
WireConnection;82;0;83;0
WireConnection;82;1;119;0
WireConnection;82;2;57;0
WireConnection;133;0;11;0
WireConnection;44;0;127;0
WireConnection;111;0;80;0
WireConnection;130;0;85;0
WireConnection;134;0;11;0
WireConnection;23;0;116;0
WireConnection;23;1;18;0
WireConnection;132;0;133;0
WireConnection;84;0;82;0
WireConnection;41;0;44;0
WireConnection;41;1;134;0
WireConnection;41;2;43;0
WireConnection;0;0;132;0
WireConnection;0;1;131;0
WireConnection;0;2;41;0
WireConnection;0;3;16;0
WireConnection;0;4;23;0
WireConnection;0;5;84;0
WireConnection;0;7;112;0
ASEEND*/
//CHKSM=B3DD0A7F65C8DE7118CE9C155A62AC10AF3645AF