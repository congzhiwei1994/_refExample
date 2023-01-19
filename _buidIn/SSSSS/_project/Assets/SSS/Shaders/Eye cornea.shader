// Made with Amplify Shader Editor
// Available at the Unity Asset Store - http://u3d.as/y3X 
Shader "SSS/Eye cornea"
{
	Properties
	{
		[NoScaleOffset][Normal]_Normal("Normal", 2D) = "bump" {}
		_Smoothness("Smoothness", Range( 0 , 1)) = 0
		_Specular("Specular", Range( 0 , 1)) = 0
		[NoScaleOffset]_Occlusion("Occlusion", 2D) = "white" {}
		[HideInInspector] _texcoord( "", 2D ) = "white" {}
		[HideInInspector] __dirty( "", Int ) = 1
	}

	SubShader
	{
		Tags{ "RenderType" = "Opaque"  "Queue" = "Geometry+0" "IgnoreProjector" = "True" }
		Cull Back
		ZWrite Off
		Blend One One
		
		CGPROGRAM
		#pragma target 3.0
		#pragma surface surf StandardSpecular keepalpha addshadow fullforwardshadows 
		struct Input
		{
			float2 uv_texcoord;
		};

		uniform sampler2D _Normal;
		uniform float _Specular;
		uniform float _Smoothness;
		uniform sampler2D _Occlusion;

		void surf( Input i , inout SurfaceOutputStandardSpecular o )
		{
			float2 uv_Normal1 = i.uv_texcoord;
			o.Normal = UnpackNormal( tex2D( _Normal, uv_Normal1 ) );
			float3 temp_cast_0 = (0.0).xxx;
			o.Albedo = temp_cast_0;
			float3 temp_cast_1 = (_Specular).xxx;
			o.Specular = temp_cast_1;
			o.Smoothness = _Smoothness;
			float2 uv_Occlusion6 = i.uv_texcoord;
			float4 tex2DNode6 = tex2D( _Occlusion, uv_Occlusion6 );
			o.Occlusion = tex2DNode6.r;
			o.Alpha = 1;
		}

		ENDCG
	}
	Fallback "Diffuse"
	CustomEditor "ASEMaterialInspector"
}
/*ASEBEGIN
Version=16100
4099;93;2546;1256;1273;569;1;True;True
Node;AmplifyShaderEditor.RangedFloatNode;4;-36,-181;Float;False;Constant;_Float0;Float 0;3;0;Create;True;0;0;False;0;0;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;3;-597,86;Float;False;Property;_Smoothness;Smoothness;1;0;Create;True;0;0;False;0;0;1;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;2;-602,7;Float;False;Property;_Specular;Specular;2;0;Create;True;0;0;False;0;0;0.087;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.SamplerNode;1;-614,-205;Float;True;Property;_Normal;Normal;0;2;[NoScaleOffset];[Normal];Create;True;0;0;False;0;8d7331b02b76b744b9f436d403c0aeec;8d7331b02b76b744b9f436d403c0aeec;True;0;True;bump;Auto;True;Object;-1;Auto;Texture2D;6;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;5;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SamplerNode;6;-578,232;Float;True;Property;_Occlusion;Occlusion;3;1;[NoScaleOffset];Create;True;0;0;False;0;None;56d1e98d23f1ca146a0b2811817713b9;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;6;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.StandardSurfaceOutputNode;0;405,-99;Float;False;True;2;Float;ASEMaterialInspector;0;0;StandardSpecular;SSS/Eye cornea;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;False;False;False;False;False;Back;2;False;-1;0;False;-1;False;0;False;-1;0;False;-1;False;0;Opaque;0.5;True;True;0;False;Opaque;;Geometry;All;True;True;True;True;True;True;True;True;True;True;True;True;True;True;True;True;True;0;False;-1;False;0;False;-1;255;False;-1;255;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;False;2;15;10;25;False;0.5;True;4;1;False;-1;1;False;-1;0;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;0;0,0,0,0;VertexOffset;True;False;Cylindrical;False;Relative;0;;-1;-1;-1;-1;0;False;0;0;False;-1;-1;0;False;-1;0;0;0;16;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;2;FLOAT3;0,0,0;False;3;FLOAT3;0,0,0;False;4;FLOAT;0;False;5;FLOAT;0;False;6;FLOAT3;0,0,0;False;7;FLOAT3;0,0,0;False;8;FLOAT;0;False;9;FLOAT;0;False;10;FLOAT;0;False;13;FLOAT3;0,0,0;False;11;FLOAT3;0,0,0;False;12;FLOAT3;0,0,0;False;14;FLOAT4;0,0,0,0;False;15;FLOAT3;0,0,0;False;0
WireConnection;0;0;4;0
WireConnection;0;1;1;0
WireConnection;0;3;2;0
WireConnection;0;4;3;0
WireConnection;0;5;6;1
ASEEND*/
//CHKSM=2D719A1DDA731009FD9F35DD1E835F4028327B37