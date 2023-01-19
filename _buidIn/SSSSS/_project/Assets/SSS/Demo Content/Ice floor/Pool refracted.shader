// Upgrade NOTE: commented out 'sampler2D unity_Lightmap', a built-in variable
// Upgrade NOTE: replaced tex2D unity_Lightmap with UNITY_SAMPLE_TEX2D

// Made with Amplify Shader Editor
// Available at the Unity Asset Store - http://u3d.as/y3X 
Shader "SSS/Demo/Pool refracted"
{
	Properties
	{
		_Color("Color", Color) = (0,0,0,0)
		_MainTex("MainTex", 2D) = "white" {}
		_SpecularMap("Specular Map", 2D) = "white" {}
		_Specular("Specular", Range( 0 , 1)) = 0
		_Smoothness("Smoothness", Range( 0 , 1)) = 0
		[Normal]_Bump("Bump", 2D) = "bump" {}
		_Destinationheight("Destination height", Float) = 0
		_Intensity("Intensity", Range( 0.001 , 10)) = 0
		_H0("H0", Range( -1 , 1)) = 0
		_Hmax("Hmax", Range( -1 , 1)) = 0
		[Toggle]_Viewgradient("View gradient", Float) = 0
		_Causticsscale("Caustics scale", Range( 0 , 20)) = 0
		_Causticsblurbias("Caustics blur bias", Range( 0 , 8)) = 0
		_Caustics("Caustics", Range( 0 , 5)) = 0
		_CausticsH0("Caustics H0", Range( -1 , 1)) = 0
		_CausticsHmax("Caustics Hmax", Range( -1 , 1)) = 0
		[NoScaleOffset]_CausticsFrame("CausticsFrame", 2D) = "black" {}
		[HideInInspector] _texcoord3( "", 2D ) = "white" {}
		[HideInInspector] _texcoord( "", 2D ) = "white" {}
		[HideInInspector] __dirty( "", Int ) = 1
		[Header(Forward Rendering Options)]
		[ToggleOff] _SpecularHighlights("Specular Highlights", Float) = 1.0
		[ToggleOff] _GlossyReflections("Reflections", Float) = 1.0
	}

	SubShader
	{
		Tags{ "RenderType" = "Opaque"  "Queue" = "Geometry+0" "DisableBatching" = "True" "IsEmissive" = "true"  }
		Cull Back
		CGPROGRAM
		#include "UnityCG.cginc"
		#pragma target 3.0
		#pragma shader_feature _SPECULARHIGHLIGHTS_OFF
		#pragma shader_feature _GLOSSYREFLECTIONS_OFF
		#pragma surface surf StandardSpecular keepalpha addshadow fullforwardshadows vertex:vertexDataFunc 
		struct Input
		{
			float3 worldPos;
			float2 uv_texcoord;
			float2 uv3_texcoord3;
			float4 vertexColor : COLOR;
			float2 vertexToFrag10_g2;
		};

		uniform float _Destinationheight;
		uniform float _Intensity;
		uniform float _H0;
		uniform float _Hmax;
		uniform sampler2D _Bump;
		uniform float4 _Bump_ST;
		uniform float _Viewgradient;
		uniform float4 _Color;
		uniform sampler2D _MainTex;
		uniform float4 _MainTex_ST;
		uniform sampler2D _CausticsFrame;
		uniform float _Causticsscale;
		uniform float _Causticsblurbias;
		uniform float _Caustics;
		// uniform sampler2D unity_Lightmap;
		uniform float _CausticsH0;
		uniform float _CausticsHmax;
		uniform float _Specular;
		uniform sampler2D _SpecularMap;
		uniform float4 _SpecularMap_ST;
		uniform float _Smoothness;


		float MyCustomExpression115( float In0 )
		{
			float o = 1;
			if(In0 < .5) o = 0;
			return In0 * o;
		}


		void vertexDataFunc( inout appdata_full v, out Input o )
		{
			UNITY_INITIALIZE_OUTPUT( Input, o );
			float3 ase_vertex3Pos = v.vertex.xyz;
			float3 ase_worldPos = mul( unity_ObjectToWorld, v.vertex );
			float3 ase_worldViewDir = Unity_SafeNormalize( UnityWorldSpaceViewDir( ase_worldPos ) );
			float dotResult22 = dot( float3(0,1,0) , ase_worldViewDir );
			float temp_output_55_0 = saturate( ( ( ase_worldPos.y - _H0 ) / ( _Hmax - _H0 ) ) );
			float lerpResult38 = lerp( ase_vertex3Pos.z , _Destinationheight , ( ( 1.0 - pow( saturate( dotResult22 ) , _Intensity ) ) * temp_output_55_0 ));
			float4 appendResult25 = (float4(ase_vertex3Pos.x , ase_vertex3Pos.y , lerpResult38 , 0.0));
			v.vertex.xyz = appendResult25.xyz;
			v.vertex.w = 1;
			o.vertexToFrag10_g2 = ( ( v.texcoord1.xy * (unity_LightmapST).xy ) + (unity_LightmapST).zw );
		}

		void surf( Input i , inout SurfaceOutputStandardSpecular o )
		{
			float2 uv_Bump = i.uv_texcoord * _Bump_ST.xy + _Bump_ST.zw;
			o.Normal = UnpackNormal( tex2D( _Bump, uv_Bump ) );
			float2 uv_MainTex = i.uv_texcoord * _MainTex_ST.xy + _MainTex_ST.zw;
			float3 ase_worldPos = i.worldPos;
			float temp_output_55_0 = saturate( ( ( ase_worldPos.y - _H0 ) / ( _Hmax - _H0 ) ) );
			float4 temp_cast_0 = (temp_output_55_0).xxxx;
			o.Albedo = (( _Viewgradient )?( temp_cast_0 ):( ( _Color * tex2D( _MainTex, uv_MainTex ) ) )).rgb;
			float4 tex2DNode7_g2 = UNITY_SAMPLE_TEX2D( unity_Lightmap, i.vertexToFrag10_g2 );
			float3 decodeLightMap6_g2 = DecodeLightmap(tex2DNode7_g2);
			float3 desaturateInitialColor116 = decodeLightMap6_g2;
			float desaturateDot116 = dot( desaturateInitialColor116, float3( 0.299, 0.587, 0.114 ));
			float3 desaturateVar116 = lerp( desaturateInitialColor116, desaturateDot116.xxx, 1.0 );
			float In0115 = desaturateVar116.x;
			float localMyCustomExpression115 = MyCustomExpression115( In0115 );
			float4 temp_output_92_0 = ( tex2Dlod( _CausticsFrame, float4( ( _Causticsscale * i.uv3_texcoord3 ), 0, ( i.vertexColor.r * _Causticsblurbias )) ) * _Caustics * localMyCustomExpression115 * saturate( ( ( ase_worldPos.y - _CausticsH0 ) / ( _CausticsHmax - _CausticsH0 ) ) ) );
			o.Emission = temp_output_92_0.rgb;
			float2 uv_SpecularMap = i.uv_texcoord * _SpecularMap_ST.xy + _SpecularMap_ST.zw;
			float4 tex2DNode46 = tex2D( _SpecularMap, uv_SpecularMap );
			o.Specular = ( _Specular * tex2DNode46 ).rgb;
			o.Smoothness = ( _Smoothness * tex2DNode46.a );
			o.Alpha = 1;
		}

		ENDCG
	}
	Fallback "Diffuse"
	CustomEditor "ASEMaterialInspector"
}
/*ASEBEGIN
Version=18800
62;71;2458;1192;6811.515;2656.17;3.842841;True;True
Node;AmplifyShaderEditor.CommentaryNode;68;-2445.131,470.6818;Inherit;False;1254.633;405.4337;Height Mask / water level;7;51;54;52;53;49;50;55;;1,1,1,1;0;0
Node;AmplifyShaderEditor.Vector3Node;5;-1295.57,-178.7557;Inherit;False;Constant;_Vector0;Vector 0;0;0;Create;True;0;0;0;False;0;False;0,1,0;0,0,0;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.ViewDirInputsCoordNode;18;-1470.17,23.14448;Inherit;False;World;True;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.WorldPosInputsNode;49;-2395.131,520.6819;Inherit;False;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.RangedFloatNode;51;-2154.655,722.6052;Inherit;False;Property;_Hmax;Hmax;11;0;Create;True;0;0;0;False;0;False;0;-0.58;-1;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;50;-2195.6,636.2921;Inherit;False;Property;_H0;H0;10;0;Create;True;0;0;0;False;0;False;0;-0.33;-1;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.DotProductOpNode;22;-1129.17,-10.55558;Inherit;False;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SaturateNode;16;-985.4697,32.0444;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;41;-1098.552,248.7338;Inherit;False;Property;_Intensity;Intensity;9;0;Create;True;0;0;0;False;0;False;0;1.85;0.001;10;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleSubtractOpNode;54;-1885.499,741.1155;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleSubtractOpNode;52;-1895.499,568.1155;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.CommentaryNode;120;-5009.071,-1587.763;Inherit;False;1254.633;405.4337;Height Mask / water level;7;127;126;125;124;123;122;121;;1,1,1,1;0;0
Node;AmplifyShaderEditor.RangedFloatNode;123;-4759.541,-1422.152;Inherit;False;Property;_CausticsH0;Caustics H0;16;0;Create;True;0;0;0;False;0;False;0;1;-1;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.WorldPosInputsNode;122;-4959.071,-1537.762;Inherit;False;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.RangedFloatNode;121;-4718.596,-1335.839;Inherit;False;Property;_CausticsHmax;Caustics Hmax;17;0;Create;True;0;0;0;False;0;False;0;-0.5;-1;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleDivideOpNode;53;-1592.499,644.1156;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.PowerNode;43;-728.3867,177.1037;Inherit;False;False;2;0;FLOAT;0;False;1;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.TextureCoordinatesNode;118;-3156.995,-1091.492;Inherit;False;2;-1;2;3;2;SAMPLER2D;;False;0;FLOAT2;1,1;False;1;FLOAT2;0,0;False;5;FLOAT2;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.VertexColorNode;129;-3603.09,-1464.041;Inherit;False;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleSubtractOpNode;125;-4449.439,-1317.329;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SaturateNode;55;-1355.499,672.1156;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;130;-3645.09,-1262.041;Inherit;False;Property;_Causticsblurbias;Caustics blur bias;14;0;Create;True;0;0;0;False;0;False;0;2.7;0;8;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleSubtractOpNode;124;-4459.439,-1490.329;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.OneMinusNode;65;-470.0136,312.3709;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;112;-3372.766,-957.6203;Inherit;False;Property;_Causticsscale;Caustics scale;13;0;Create;True;0;0;0;False;0;False;0;10.3;0;20;0;1;FLOAT;0
Node;AmplifyShaderEditor.FunctionNode;114;-2191.133,-1455.814;Inherit;False;FetchLightmapValue;0;;2;43de3d4ae59f645418fdd020d1b8e78e;0;0;1;FLOAT3;0
Node;AmplifyShaderEditor.PosVertexDataNode;26;-360.1916,-23.26753;Inherit;False;0;0;5;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;64;-289.6112,403.3533;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.WireNode;67;510.2043,455.9681;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SamplerNode;34;-100.1,-973.0999;Inherit;True;Property;_MainTex;MainTex;3;0;Create;True;0;0;0;False;0;False;-1;None;4454467991c87404fa29aae443caf789;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;128;-3308.281,-1318.791;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;8;False;1;FLOAT;0
Node;AmplifyShaderEditor.DesaturateOpNode;116;-1782.246,-1317.466;Inherit;False;2;0;FLOAT3;0,0,0;False;1;FLOAT;1;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RangedFloatNode;40;-430.4021,144.6819;Inherit;False;Property;_Destinationheight;Destination height;8;0;Create;True;0;0;0;False;0;False;0;0.04;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;119;-2818.575,-1074.661;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.TexturePropertyNode;102;-3076.592,-1846.274;Inherit;True;Property;_CausticsFrame;CausticsFrame;18;1;[NoScaleOffset];Create;True;0;0;0;False;0;False;None;e6eb8035f17f5844a881ff8296682d80;False;black;Auto;Texture2D;-1;0;2;SAMPLER2D;0;SAMPLERSTATE;1
Node;AmplifyShaderEditor.SimpleDivideOpNode;126;-4156.439,-1414.329;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ColorNode;109;-100.3626,-1191.928;Inherit;False;Property;_Color;Color;2;0;Create;True;0;0;0;False;0;False;0,0,0,0;0.9528301,0.9528301,0.9528301,0;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SaturateNode;127;-3919.439,-1386.329;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;110;273.2182,-982.4556;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.CustomExpressionNode;115;-1552.246,-1314.466;Inherit;False;float o = 1@$if(In0 < .5) o = 0@$return In0 * o@;1;False;1;True;In0;FLOAT;0;In;;Inherit;False;My Custom Expression;True;False;0;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;108;-1830.698,-1504.858;Inherit;False;Property;_Caustics;Caustics;15;0;Create;True;0;0;0;False;0;False;0;5;0;5;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;44;-308.1302,-465.1519;Inherit;False;Property;_Smoothness;Smoothness;6;0;Create;True;0;0;0;False;0;False;0;0.921;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.CommentaryNode;69;110.8,-36.19999;Inherit;False;211;233;Final vertex position;1;25;;1,1,1,1;0;0
Node;AmplifyShaderEditor.LerpOp;38;-103.5824,113.9892;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.WireNode;66;539.1363,433.4654;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;45;-294.1302,-336.1519;Inherit;False;Property;_Specular;Specular;5;0;Create;True;0;0;0;False;0;False;0;0.02;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.SamplerNode;46;-267.6825,-244.0674;Inherit;True;Property;_SpecularMap;Specular Map;4;0;Create;True;0;0;0;False;0;False;-1;None;2c8d284cdc59acb4e8968e14807520c3;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SamplerNode;76;-2535.137,-1544.958;Inherit;True;Property;_TextureSample0;Texture Sample 0;11;0;Create;True;0;0;0;False;0;False;-1;None;f1dd56ce2936dc34bbfbb4121628a605;True;0;False;white;Auto;False;Object;-1;MipLevel;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SamplerNode;35;-316.1523,-733.973;Inherit;True;Property;_Bump;Bump;7;1;[Normal];Create;True;0;0;0;False;0;False;-1;None;b410d1ef9e4a3fd4fbf58427d18ca8c4;True;0;True;bump;Auto;True;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;107;-547.915,-820.1852;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.ToggleSwitchNode;56;631.3904,-471.2189;Inherit;False;Property;_Viewgradient;View gradient;12;0;Create;True;0;0;0;False;0;False;0;2;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;92;-1271.338,-1445.977;Inherit;False;4;4;0;COLOR;0,0,0,0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.DynamicAppendNode;25;160.8,13.80001;Inherit;False;FLOAT4;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.CustomExpressionNode;93;-2134.5,-1287.514;Inherit;False; float x = 0@$ float y = 0@$if(uv.x > 0 && uv.x < 1) x= 1@$if(uv.y > 0 && uv.y < 1) y= 1@$return x * y@;1;False;1;True;uv;FLOAT2;0,0;In;;Inherit;False;My Custom Expression;True;False;0;1;0;FLOAT2;0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;47;254.3175,-404.0674;Inherit;False;2;2;0;FLOAT;0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;48;218.3175,-157.0674;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.StandardSurfaceOutputNode;0;1011.503,-378.4197;Float;False;True;-1;2;ASEMaterialInspector;0;0;StandardSpecular;SSS/Demo/Pool refracted;False;False;False;False;False;False;False;False;False;False;False;False;False;True;False;False;False;False;True;True;False;Back;0;False;-1;0;False;-1;False;0;False;-1;0;False;-1;False;0;Opaque;0.5;True;True;0;False;Opaque;;Geometry;All;14;all;True;True;True;True;0;False;-1;False;0;False;-1;255;False;-1;255;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;False;2;15;10;25;False;0.5;True;0;0;False;-1;0;False;-1;0;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;0;0,0,0,0;VertexOffset;True;False;Cylindrical;False;Absolute;0;;-1;-1;-1;-1;0;False;0;0;False;-1;-1;0;False;-1;0;0;0;False;0.1;False;-1;0;False;-1;False;16;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;2;FLOAT3;0,0,0;False;3;FLOAT3;0,0,0;False;4;FLOAT;0;False;5;FLOAT;0;False;6;FLOAT3;0,0,0;False;7;FLOAT3;0,0,0;False;8;FLOAT;0;False;9;FLOAT;0;False;10;FLOAT;0;False;13;FLOAT3;0,0,0;False;11;FLOAT3;0,0,0;False;12;FLOAT3;0,0,0;False;14;FLOAT4;0,0,0,0;False;15;FLOAT3;0,0,0;False;0
WireConnection;22;0;5;0
WireConnection;22;1;18;0
WireConnection;16;0;22;0
WireConnection;54;0;51;0
WireConnection;54;1;50;0
WireConnection;52;0;49;2
WireConnection;52;1;50;0
WireConnection;53;0;52;0
WireConnection;53;1;54;0
WireConnection;43;0;16;0
WireConnection;43;1;41;0
WireConnection;125;0;121;0
WireConnection;125;1;123;0
WireConnection;55;0;53;0
WireConnection;124;0;122;2
WireConnection;124;1;123;0
WireConnection;65;0;43;0
WireConnection;64;0;65;0
WireConnection;64;1;55;0
WireConnection;67;0;55;0
WireConnection;128;0;129;1
WireConnection;128;1;130;0
WireConnection;116;0;114;0
WireConnection;119;0;112;0
WireConnection;119;1;118;0
WireConnection;126;0;124;0
WireConnection;126;1;125;0
WireConnection;127;0;126;0
WireConnection;110;0;109;0
WireConnection;110;1;34;0
WireConnection;115;0;116;0
WireConnection;38;0;26;3
WireConnection;38;1;40;0
WireConnection;38;2;64;0
WireConnection;66;0;67;0
WireConnection;76;0;102;0
WireConnection;76;1;119;0
WireConnection;76;2;128;0
WireConnection;107;0;92;0
WireConnection;107;1;55;0
WireConnection;56;0;110;0
WireConnection;56;1;66;0
WireConnection;92;0;76;0
WireConnection;92;1;108;0
WireConnection;92;2;115;0
WireConnection;92;3;127;0
WireConnection;25;0;26;1
WireConnection;25;1;26;2
WireConnection;25;2;38;0
WireConnection;47;0;45;0
WireConnection;47;1;46;0
WireConnection;48;0;44;0
WireConnection;48;1;46;4
WireConnection;0;0;56;0
WireConnection;0;1;35;0
WireConnection;0;2;92;0
WireConnection;0;3;47;0
WireConnection;0;4;48;0
WireConnection;0;11;25;0
ASEEND*/
//CHKSM=11A3CE25A4C9470A550C48620F32149EC60D5C1D