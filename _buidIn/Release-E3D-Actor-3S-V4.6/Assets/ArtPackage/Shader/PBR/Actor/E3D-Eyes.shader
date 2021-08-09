// Made with Amplify Shader Editor
// Available at the Unity Asset Store - http://u3d.as/y3X 
Shader "E3D/PBRActor/Eyes-4T"
{
	Properties
	{
		_MainTexP("MainTex-P", 2D) = "white" {}
		_EyesColor("Eyes-Color", Color) = (0,0,0,0)
		_Smooth("Smooth", Range( 0 , 2)) = 1
		_MainTexW("MainTex-W", 2D) = "white" {}
		_Normal("Normal", 2D) = "bump" {}
		_SizeEyes("Size-Eyes", Range( 2 , 3.5)) = 2
		_SizePupil("Size-Pupil", Range( -0.55 , 1)) = 0
		_PuilSoft("Puil-Soft", Range( 0 , 0.3)) = 0.1058824
		_PuilDepthScale("Puil-DepthScale", Range( 0 , 0.4)) = 0
		_MatCapMap("MatCapMap", 2D) = "white" {}
		_MatcapLighting("Matcap-Lighting", Range( 0 , 8)) = 3
		[HideInInspector] _texcoord( "", 2D ) = "white" {}
		[HideInInspector] __dirty( "", Int ) = 1
	}

	SubShader
	{
		Tags{ "RenderType" = "Opaque"  "Queue" = "Geometry+0" }
		Cull Back
		CGINCLUDE
		#include "UnityStandardUtils.cginc"
		#include "UnityShaderVariables.cginc"
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
			float3 worldNormal;
			INTERNAL_DATA
			float3 worldPos;
		};

		uniform sampler2D _Normal;
		uniform float _SizeEyes;
		uniform sampler2D _MatCapMap;
		uniform float _MatcapLighting;
		uniform sampler2D _MainTexP;
		uniform float _PuilSoft;
		uniform sampler2D _MainTexW;
		uniform float4 _MainTexW_ST;
		uniform float _PuilDepthScale;
		uniform float _SizePupil;
		uniform float4 _EyesColor;
		uniform float _Smooth;

		void surf( Input i , inout SurfaceOutputStandard o )
		{
			float SizeEyes53 = _SizeEyes;
			float2 UVEyesContent112 = ( ( SizeEyes53 * ( i.uv_texcoord - float2( 0.5,0.5 ) ) ) + 0.5 );
			float3 tex2DNode111 = UnpackScaleNormal( tex2D( _Normal, UVEyesContent112 ), 1.2 );
			o.Normal = tex2DNode111;
			float4 tex2DNode1 = tex2D( _MainTexP, UVEyesContent112 );
			float EyesEdge140 = tex2DNode1.a;
			float temp_output_64_0 = saturate( (0.0 + (EyesEdge140 - 0.0) * (1.0 - 0.0) / (_PuilSoft - 0.0)) );
			float2 uv_MainTexW = i.uv_texcoord * _MainTexW_ST.xy + _MainTexW_ST.zw;
			float3 ase_worldPos = i.worldPos;
			float3 ase_worldViewDir = Unity_SafeNormalize( UnityWorldSpaceViewDir( ase_worldPos ) );
			float3 ase_worldNormal = WorldNormalVector( i, float3( 0, 0, 1 ) );
			float3 ase_worldTangent = WorldNormalVector( i, float3( 1, 0, 0 ) );
			float3 ase_worldBitangent = WorldNormalVector( i, float3( 0, 1, 0 ) );
			float3x3 ase_worldToTangent = float3x3( ase_worldTangent, ase_worldBitangent, ase_worldNormal );
			float3 ase_tanViewDir = mul( ase_worldToTangent, ase_worldViewDir );
			float2 Offset95 = ( ( 0.27 - 1 ) * ase_tanViewDir.xy * ( _PuilDepthScale * tex2DNode1.a ) ) + UVEyesContent112;
			float2 ParaUV129 = Offset95;
			float2 normalizeResult10 = normalize( ( ( Offset95 - float2( 0.5,0.5 ) ) * 0.5 ) );
			float2 lerpResult26 = lerp( ParaUV129 , ( float2( 0.5,0.5 ) + normalizeResult10 ) , ( ( ( 0.8 / SizeEyes53 ) * _SizePupil ) * ( 1.0 - ( 2.0 * SizeEyes53 * length( ( i.uv_texcoord - float2( 0.5,0.5 ) ) ) ) ) ));
			float4 lerpResult52 = lerp( tex2D( _MainTexW, uv_MainTexW ) , ( tex2D( _MainTexP, lerpResult26 ) * _EyesColor ) , temp_output_64_0);
			o.Albedo = ( ( tex2D( _MatCapMap, ( ( mul( UNITY_MATRIX_V, float4( normalize( (WorldNormalVector( i , tex2DNode111 )) ) , 0.0 ) ).xyz * 0.5 ) + 0.5 ).xy ) * _MatcapLighting * ( 0.02096644 + temp_output_64_0 ) ) + ( 2.0 * lerpResult52 ) ).rgb;
			o.Metallic = 0.0;
			o.Smoothness = ( _Smooth * saturate( ( temp_output_64_0 + 1.0 ) ) );
			o.Alpha = 1;
		}

		ENDCG
		CGPROGRAM
		#pragma surface surf Standard keepalpha fullforwardshadows 

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
				SurfaceOutputStandard o;
				UNITY_INITIALIZE_OUTPUT( SurfaceOutputStandard, o )
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
93;586;1377;475;-4509.069;1117.414;1.330382;True;False
Node;AmplifyShaderEditor.RangedFloatNode;48;1014.935,-939.3132;Inherit;False;Property;_SizeEyes;Size-Eyes;5;0;Create;True;0;0;False;0;2;2.2;2;3.5;0;1;FLOAT;0
Node;AmplifyShaderEditor.CommentaryNode;128;-376.7077,-540.3402;Inherit;False;1333.841;516.4736;Center-Scale;8;126;112;109;127;107;125;104;108;;1,1,1,1;0;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;53;1341.315,-941.3313;Inherit;False;SizeEyes;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.Vector2Node;125;-114.3081,-289.959;Inherit;False;Constant;_Vector2;Vector 2;1;0;Create;True;0;0;False;0;0.5,0.5;0,0;0;3;FLOAT2;0;FLOAT;1;FLOAT;2
Node;AmplifyShaderEditor.TextureCoordinatesNode;104;-340.13,-362.7028;Inherit;True;0;-1;2;3;2;SAMPLER2D;;False;0;FLOAT2;1,1;False;1;FLOAT2;0,0;False;5;FLOAT2;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.GetLocalVarNode;126;119.6396,-448.0218;Inherit;False;53;SizeEyes;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleSubtractOpNode;107;97.65421,-367.2866;Inherit;True;2;0;FLOAT2;0,0;False;1;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;108;350.2913,-414.0049;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RangedFloatNode;127;351.8725,-304.9565;Inherit;False;Constant;_Float3;Float 3;11;0;Create;True;0;0;False;0;0.5;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;109;543.0577,-396.374;Inherit;False;2;2;0;FLOAT2;0,0;False;1;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.CommentaryNode;138;1012.157,-787.7335;Inherit;False;1262.203;784.5166;Para;9;129;113;99;95;101;96;97;1;140;;1,1,1,1;0;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;112;714.5784,-283.551;Inherit;True;UVEyesContent;-1;True;1;0;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SamplerNode;1;1062.154,-300.9106;Inherit;True;Property;_MainTexP;MainTex-P;0;0;Create;True;0;0;False;0;-1;None;9109a332f4dbd9145b62c7b862191ea0;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;6;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.CommentaryNode;139;1632.931,-1559.284;Inherit;False;1906.148;723.6211;Pupil Lerp;15;3;136;137;82;51;30;37;29;50;2;56;49;54;31;144;;1,1,1,1;0;0
Node;AmplifyShaderEditor.RangedFloatNode;97;1060.722,-383.1034;Inherit;False;Property;_PuilDepthScale;Puil-DepthScale;8;0;Create;True;0;0;False;0;0;0.4;0;0.4;0;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;113;1071.462,-678.2171;Inherit;False;112;UVEyesContent;1;0;OBJECT;;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RangedFloatNode;99;1070.721,-604.8325;Inherit;False;Constant;_PuilHeight;Puil-Height;9;0;Create;True;0;0;False;0;0.27;0.27;0;3;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;101;1429.176,-317.838;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ViewDirInputsCoordNode;96;1072.347,-528.9276;Inherit;False;Tangent;True;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.Vector2Node;137;1761.236,-1031.697;Inherit;False;Constant;_Vector3;Vector 3;1;0;Create;True;0;0;False;0;0.5,0.5;0,0;0;3;FLOAT2;0;FLOAT;1;FLOAT;2
Node;AmplifyShaderEditor.TextureCoordinatesNode;3;1704.141,-1159.215;Inherit;False;0;-1;2;3;2;SAMPLER2D;;False;0;FLOAT2;1,1;False;1;FLOAT2;0,0;False;5;FLOAT2;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.CommentaryNode;57;2351.008,-700.472;Inherit;False;1579.277;509.7144;Radioactivity;7;18;17;10;8;5;9;7;;1,1,1,1;0;0
Node;AmplifyShaderEditor.SimpleSubtractOpNode;136;1981.927,-1092.271;Inherit;True;2;0;FLOAT2;0,0;False;1;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.Vector2Node;7;2377.566,-529.1984;Inherit;False;Constant;_Vector0;Vector 0;1;0;Create;True;0;0;False;0;0.5,0.5;0,0;0;3;FLOAT2;0;FLOAT;1;FLOAT;2
Node;AmplifyShaderEditor.ParallaxMappingNode;95;1641.822,-611.4694;Inherit;True;Normal;4;0;FLOAT2;0,0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT3;0,0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleSubtractOpNode;5;2600.85,-608.8489;Inherit;True;2;0;FLOAT2;0,0;False;1;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.GetLocalVarNode;54;2372.863,-1424.769;Inherit;False;53;SizeEyes;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;31;2229.139,-1255.312;Inherit;False;Constant;_C1;C1;2;0;Create;True;0;0;False;0;2;2;2;2;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;49;2392.692,-1515.965;Inherit;False;Constant;_Float2;Float 2;5;0;Create;True;0;0;False;0;0.8;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.LengthOpNode;2;2237.484,-1100.493;Inherit;False;1;0;FLOAT2;0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;56;2202.115,-1167.978;Inherit;False;53;SizeEyes;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;9;2597.616,-383.4753;Inherit;False;Constant;_C2;C2;1;0;Create;True;0;0;False;0;0.5;0.5;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;8;3008.281,-518.0532;Inherit;True;2;2;0;FLOAT2;0,0;False;1;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RangedFloatNode;37;2366.531,-1331.722;Inherit;False;Property;_SizePupil;Size-Pupil;6;0;Create;True;0;0;False;0;0;-0.384;-0.55;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;29;2424.526,-1187.069;Inherit;True;3;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;114;5121.514,-439.1735;Inherit;False;112;UVEyesContent;1;0;OBJECT;;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleDivideOpNode;50;2627.787,-1438.97;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;129;2053.486,-487.0024;Inherit;False;ParaUV;-1;True;1;0;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.OneMinusNode;30;2797.334,-1206.826;Inherit;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.Vector2Node;17;3288.367,-644.527;Inherit;False;Constant;_C2v;C2v;1;0;Create;True;0;0;False;0;0.5,0.5;0,0;0;3;FLOAT2;0;FLOAT;1;FLOAT;2
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;51;2830.696,-1436.04;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SamplerNode;111;5446.901,-464.9074;Inherit;True;Property;_Normal;Normal;4;0;Create;True;0;0;False;0;-1;None;15400b18d160e9e4091b87575f22d11c;True;0;True;bump;Auto;True;Object;-1;Auto;Texture2D;6;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1.2;False;5;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.CommentaryNode;155;4136.734,-1531.416;Inherit;False;1176.01;402.0377;Matcap;8;151;150;147;149;148;145;157;146;;1,1,1,1;0;0
Node;AmplifyShaderEditor.NormalizeNode;10;3237.683,-516.729;Inherit;True;1;0;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.GetLocalVarNode;135;3655.873,-847.607;Inherit;False;129;ParaUV;1;0;OBJECT;;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleAddOpNode;18;3525.375,-586.9561;Inherit;True;2;2;0;FLOAT2;0,0;False;1;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;82;3038.798,-1306.044;Inherit;True;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ViewMatrixNode;145;4275.464,-1431.465;Inherit;False;0;1;FLOAT4x4;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;140;1436.269,-205.8102;Inherit;False;EyesEdge;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.CommentaryNode;142;3975.639,-424.331;Inherit;False;886.8926;384.517;Soft-EyesEdge;4;141;61;64;60;;1,1,1,1;0;0
Node;AmplifyShaderEditor.WorldNormalVector;146;4175.48,-1322.942;Inherit;False;True;1;0;FLOAT3;0,0,1;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.RangedFloatNode;61;4006.278,-248.1211;Inherit;False;Property;_PuilSoft;Puil-Soft;7;0;Create;True;0;0;False;0;0.1058824;0.216;0;0.3;0;1;FLOAT;0
Node;AmplifyShaderEditor.CommentaryNode;124;4270.6,-1074.015;Inherit;False;1036.645;611.5093;Para;5;52;47;92;94;98;;1,1,1,1;0;0
Node;AmplifyShaderEditor.LerpOp;26;4007.13,-834.6476;Inherit;True;3;0;FLOAT2;0,0;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.GetLocalVarNode;141;4091.916,-332.2106;Inherit;False;140;EyesEdge;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;147;4452.477,-1398.825;Inherit;False;2;2;0;FLOAT4x4;0,0,0,0,0,1,0,0,0,0,1,0,0,0,0,1;False;1;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RangedFloatNode;149;4421.09,-1297.137;Inherit;False;Constant;_Float1;Float 1;9;0;Create;True;0;0;False;0;0.5;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.ColorNode;94;4425.765,-662.4817;Inherit;False;Property;_EyesColor;Eyes-Color;1;0;Create;True;0;0;False;0;0,0,0,0;0.5073529,0.6534483,1,0;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SamplerNode;98;4394.982,-867.4127;Inherit;True;Property;_TextureSample0;Texture Sample 0;0;0;Create;True;0;0;False;0;-1;None;9109a332f4dbd9145b62c7b862191ea0;True;0;False;white;Auto;False;Instance;1;Auto;Texture2D;6;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.CommentaryNode;143;4962.754,-243.4083;Inherit;False;1052.168;437.149;Smooth;5;117;121;89;119;118;;1,1,1,1;0;0
Node;AmplifyShaderEditor.TFHCRemapNode;60;4299.544,-324.6413;Inherit;True;5;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;3;FLOAT;0;False;4;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;148;4633.25,-1398.825;Inherit;False;2;2;0;FLOAT3;0,0,0;False;1;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SaturateNode;64;4611.181,-326.8201;Inherit;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;92;4809.625,-714.3104;Inherit;True;2;2;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.SamplerNode;47;4758.844,-1004.006;Inherit;True;Property;_MainTexW;MainTex-W;3;0;Create;True;0;0;False;0;-1;None;3070326a755c94d4b8c194bb67fa8032;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;6;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleAddOpNode;150;4815.279,-1400.079;Inherit;False;2;2;0;FLOAT3;0,0,0;False;1;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RangedFloatNode;159;5205.914,-1154.454;Inherit;False;Constant;_Float4;Float 4;11;0;Create;True;0;0;False;0;0.02096644;0;0;0.1;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;118;4987.741,-74.4604;Inherit;False;Constant;_WhiteSmooth;White-Smooth;9;0;Create;True;0;0;False;0;1;1;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.LerpOp;52;5135.585,-777.3881;Inherit;True;3;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;2;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleAddOpNode;158;5518.552,-1151.61;Inherit;True;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;162;5437.195,-855.1161;Inherit;False;Constant;_Float6;Float 6;11;0;Create;True;0;0;False;0;2;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;157;4986.47,-1223.039;Inherit;False;Property;_MatcapLighting;Matcap-Lighting;10;0;Create;True;0;0;False;0;3;5;0;8;0;1;FLOAT;0
Node;AmplifyShaderEditor.SamplerNode;151;4990.43,-1430.209;Inherit;True;Property;_MatCapMap;MatCapMap;9;0;Create;True;0;0;False;0;-1;None;96497bba6238d0b45b22980b45826a33;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;6;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleAddOpNode;119;5289.287,-130.9354;Inherit;True;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;156;5761.576,-1337.139;Inherit;False;3;3;0;COLOR;0,0,0,0;False;1;FLOAT;0;False;2;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;161;5698.153,-819.9317;Inherit;False;2;2;0;FLOAT;0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.RangedFloatNode;89;5278.749,76.25549;Inherit;False;Property;_Smooth;Smooth;2;0;Create;True;0;0;False;0;1;0.6;0;2;0;1;FLOAT;0
Node;AmplifyShaderEditor.SaturateNode;121;5560.257,-132.8654;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;90;5871.13,-398.8325;Inherit;False;Constant;_Float0;Float 0;7;0;Create;True;0;0;False;0;0;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;117;5761.167,-67.5475;Inherit;True;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;160;6076.262,-616.6816;Inherit;False;Constant;_Float5;Float 5;11;0;Create;True;0;0;False;0;0.5;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;154;6015.993,-1123.619;Inherit;True;2;2;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;144;2625.881,-1534.455;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.StandardSurfaceOutputNode;0;6379.69,-473.035;Float;False;True;-1;2;ASEMaterialInspector;0;0;Standard;E3D/PBRActor/Eyes-4T;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;Back;0;False;-1;0;False;-1;False;0;False;-1;0;False;-1;False;0;Opaque;0.5;True;True;0;False;Opaque;;Geometry;All;14;all;True;True;True;True;0;False;-1;False;0;False;-1;255;False;-1;255;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;False;2;15;10;25;False;0.5;True;0;0;False;-1;0;False;-1;0;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;0;0,0,0,0;VertexOffset;True;False;Cylindrical;False;Relative;0;;-1;-1;-1;-1;0;False;0;0;False;-1;-1;0;False;-1;0;0;0;False;0.1;False;-1;0;False;-1;16;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;2;FLOAT3;0,0,0;False;3;FLOAT;0;False;4;FLOAT;0;False;5;FLOAT;0;False;6;FLOAT3;0,0,0;False;7;FLOAT3;0,0,0;False;8;FLOAT;0;False;9;FLOAT;0;False;10;FLOAT;0;False;13;FLOAT3;0,0,0;False;11;FLOAT3;0,0,0;False;12;FLOAT3;0,0,0;False;14;FLOAT4;0,0,0,0;False;15;FLOAT3;0,0,0;False;0
WireConnection;53;0;48;0
WireConnection;107;0;104;0
WireConnection;107;1;125;0
WireConnection;108;0;126;0
WireConnection;108;1;107;0
WireConnection;109;0;108;0
WireConnection;109;1;127;0
WireConnection;112;0;109;0
WireConnection;1;1;112;0
WireConnection;101;0;97;0
WireConnection;101;1;1;4
WireConnection;136;0;3;0
WireConnection;136;1;137;0
WireConnection;95;0;113;0
WireConnection;95;1;99;0
WireConnection;95;2;101;0
WireConnection;95;3;96;0
WireConnection;5;0;95;0
WireConnection;5;1;7;0
WireConnection;2;0;136;0
WireConnection;8;0;5;0
WireConnection;8;1;9;0
WireConnection;29;0;31;0
WireConnection;29;1;56;0
WireConnection;29;2;2;0
WireConnection;50;0;49;0
WireConnection;50;1;54;0
WireConnection;129;0;95;0
WireConnection;30;0;29;0
WireConnection;51;0;50;0
WireConnection;51;1;37;0
WireConnection;111;1;114;0
WireConnection;10;0;8;0
WireConnection;18;0;17;0
WireConnection;18;1;10;0
WireConnection;82;0;51;0
WireConnection;82;1;30;0
WireConnection;140;0;1;4
WireConnection;146;0;111;0
WireConnection;26;0;135;0
WireConnection;26;1;18;0
WireConnection;26;2;82;0
WireConnection;147;0;145;0
WireConnection;147;1;146;0
WireConnection;98;1;26;0
WireConnection;60;0;141;0
WireConnection;60;2;61;0
WireConnection;148;0;147;0
WireConnection;148;1;149;0
WireConnection;64;0;60;0
WireConnection;92;0;98;0
WireConnection;92;1;94;0
WireConnection;150;0;148;0
WireConnection;150;1;149;0
WireConnection;52;0;47;0
WireConnection;52;1;92;0
WireConnection;52;2;64;0
WireConnection;158;0;159;0
WireConnection;158;1;64;0
WireConnection;151;1;150;0
WireConnection;119;0;64;0
WireConnection;119;1;118;0
WireConnection;156;0;151;0
WireConnection;156;1;157;0
WireConnection;156;2;158;0
WireConnection;161;0;162;0
WireConnection;161;1;52;0
WireConnection;121;0;119;0
WireConnection;117;0;89;0
WireConnection;117;1;121;0
WireConnection;154;0;156;0
WireConnection;154;1;161;0
WireConnection;144;0;49;0
WireConnection;144;1;54;0
WireConnection;0;0;154;0
WireConnection;0;1;111;0
WireConnection;0;3;90;0
WireConnection;0;4;117;0
ASEEND*/
//CHKSM=253A35F5F85BB947F358584BD40ED03C922F4095