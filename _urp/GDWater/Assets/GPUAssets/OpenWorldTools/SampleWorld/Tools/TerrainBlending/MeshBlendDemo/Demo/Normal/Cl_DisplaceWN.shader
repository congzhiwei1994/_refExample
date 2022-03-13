// Made with Amplify Shader Editor
// Available at the Unity Asset Store - http://u3d.as/y3X 
Shader "Cl_DisplaceWN"
{
	Properties
	{
		_TN("TN", 2D) = "bump" {}
		_Offset("Offset", Float) = 0
		_Length("Length", Float) = 0
		[HideInInspector] _texcoord( "", 2D ) = "white" {}
		[HideInInspector] __dirty( "", Int ) = 1
	}

	SubShader
	{
		Tags{ "RenderType" = "Opaque"  "Queue" = "Geometry+0" "IsEmissive" = "true"  }
		Cull Back
		CGPROGRAM
		#include "UnityShaderVariables.cginc"
		#pragma target 3.0
		#pragma surface surf Unlit keepalpha addshadow fullforwardshadows vertex:vertexDataFunc 
		struct Input
		{
			float eyeDepth;
			float2 uv_texcoord;
		};

		uniform float _Length;
		uniform float _Offset;
		uniform sampler2D _TN;
		uniform float4 _TN_ST;

		void vertexDataFunc( inout appdata_full v, out Input o )
		{
			UNITY_INITIALIZE_OUTPUT( Input, o );
			o.eyeDepth = -UnityObjectToViewPos( v.vertex.xyz ).z;
		}

		inline half4 LightingUnlit( SurfaceOutput s, half3 lightDir, half atten )
		{
			return half4 ( 0, 0, 0, s.Alpha );
		}

		void surf( Input i , inout SurfaceOutput o )
		{
			float cameraDepthFade4 = (( i.eyeDepth -_ProjectionParams.y - _Offset ) / _Length);
			float temp_output_7_0 = ( 1.0 - cameraDepthFade4 );
			float2 uv_TN = i.uv_texcoord * _TN_ST.xy + _TN_ST.zw;
			float3 tex2DNode2 = UnpackNormal( tex2D( _TN, uv_TN ) );
			float3 temp_output_12_0 = ( ( tex2DNode2 * 0.5 ) + 0.5 );
			float temp_output_16_0 = ( temp_output_7_0 + 0.01 );
			float lerpResult15 = lerp( temp_output_7_0 , (temp_output_12_0).y , temp_output_16_0);
			float3 temp_cast_0 = (lerpResult15).xxx;
			o.Emission = temp_cast_0;
			o.Alpha = 1;
		}

		ENDCG
	}
	Fallback "Diffuse"
	CustomEditor "ASEMaterialInspector"
}
/*ASEBEGIN
Version=17500
0;743;943;275;1992.573;336.5145;1;True;False
Node;AmplifyShaderEditor.RangedFloatNode;6;-1649.803,-36.46164;Inherit;False;Property;_Offset;Offset;1;0;Create;True;0;0;False;0;0;1;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;5;-1647.803,-135.4616;Inherit;False;Property;_Length;Length;2;0;Create;True;0;0;False;0;0;13.8;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;10;-1607.86,664.7426;Inherit;False;Constant;_Float1;Float 1;0;0;Create;True;0;0;False;0;0.5;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SamplerNode;2;-1790.072,193.1182;Inherit;True;Property;_TN;TN;0;0;Create;True;0;0;False;0;-1;None;f53512d44b91e954dae7bf028209df1a;True;0;True;bump;Auto;True;Object;-1;Auto;Texture2D;6;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;5;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.CameraDepthFade;4;-1438.775,-87.40936;Inherit;False;3;2;FLOAT3;0,0,0;False;0;FLOAT;1;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;11;-1463.796,381.2027;Inherit;True;2;2;0;FLOAT3;0,0,0;False;1;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.OneMinusNode;7;-1174.802,-94.36169;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;17;-1163.263,108.3555;Inherit;False;Constant;_Float0;Float 0;3;0;Create;True;0;0;False;0;0.01;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;12;-1215.09,379.3576;Inherit;False;2;2;0;FLOAT3;0,0,0;False;1;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleAddOpNode;16;-986.6631,81.8555;Inherit;True;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SwizzleNode;14;-1072.19,496.6377;Inherit;False;FLOAT;1;1;2;3;1;0;FLOAT3;0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.LerpOp;15;-439.1641,-98.34447;Inherit;True;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SwizzleNode;13;-1069.289,374.4378;Inherit;False;FLOAT;0;1;2;3;1;0;FLOAT3;0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;8;-606.0028,230.1385;Inherit;True;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.StandardSurfaceOutputNode;0;-114,-81;Float;False;True;-1;2;ASEMaterialInspector;0;0;Unlit;Cl_DisplaceWN;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;Back;0;False;-1;0;False;-1;False;0;False;-1;0;False;-1;False;0;Opaque;0.5;True;True;0;False;Opaque;;Geometry;All;14;all;True;True;True;True;0;False;-1;False;0;False;-1;255;False;-1;255;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;False;2;15;10;25;False;0.5;True;0;0;False;-1;0;False;-1;0;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;0;0,0,0,0;VertexOffset;True;False;Cylindrical;False;Relative;0;;-1;-1;-1;-1;0;False;0;0;False;-1;-1;0;False;-1;0;0;0;False;0.1;False;-1;0;False;-1;15;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;2;FLOAT3;0,0,0;False;3;FLOAT;0;False;4;FLOAT;0;False;6;FLOAT3;0,0,0;False;7;FLOAT3;0,0,0;False;8;FLOAT;0;False;9;FLOAT;0;False;10;FLOAT;0;False;13;FLOAT3;0,0,0;False;11;FLOAT3;0,0,0;False;12;FLOAT3;0,0,0;False;14;FLOAT4;0,0,0,0;False;15;FLOAT3;0,0,0;False;0
WireConnection;4;0;5;0
WireConnection;4;1;6;0
WireConnection;11;0;2;0
WireConnection;11;1;10;0
WireConnection;7;0;4;0
WireConnection;12;0;11;0
WireConnection;12;1;10;0
WireConnection;16;0;7;0
WireConnection;16;1;17;0
WireConnection;14;0;12;0
WireConnection;15;0;7;0
WireConnection;15;1;14;0
WireConnection;15;2;16;0
WireConnection;13;0;12;0
WireConnection;8;0;16;0
WireConnection;8;1;2;2
WireConnection;0;2;15;0
ASEEND*/
//CHKSM=6BEC16417421068A81A7051083272EC1E6E26FD6