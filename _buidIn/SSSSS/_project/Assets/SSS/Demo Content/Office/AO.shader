// Made with Amplify Shader Editor
// Available at the Unity Asset Store - http://u3d.as/y3X 
Shader "SSS/Demo/AO"
{
	Properties
	{
		_Hardness("Hardness", Range( 1 , 10)) = 10
		_Opacity("Opacity", Range( 0 , 1)) = 10
		_c("c", Float) = -0.5
		_Radius("Radius", Range( 0 , 1)) = 10
		[HideInInspector] _texcoord( "", 2D ) = "white" {}
		[HideInInspector] __dirty( "", Int ) = 1
	}

	SubShader
	{
		Tags{ "RenderType" = "Transparent"  "Queue" = "Transparent+0" "IgnoreProjector" = "True" "IsEmissive" = "true"  }
		Cull Back
		Blend DstColor Zero
		
		CGPROGRAM
		#pragma target 3.0
		#pragma surface surf Unlit keepalpha addshadow fullforwardshadows 
		struct Input
		{
			float2 uv_texcoord;
		};

		uniform float _c;
		uniform float _Radius;
		uniform float _Hardness;
		uniform float _Opacity;

		inline half4 LightingUnlit( SurfaceOutput s, half3 lightDir, half atten )
		{
			return half4 ( 0, 0, 0, s.Alpha );
		}

		void surf( Input i , inout SurfaceOutput o )
		{
			float2 temp_cast_0 = (_c).xx;
			float2 temp_output_17_0 = ( ( i.uv_texcoord - temp_cast_0 ) / _Radius );
			float2 temp_cast_1 = (_c).xx;
			float dotResult14 = dot( temp_output_17_0 , temp_output_17_0 );
			float3 temp_cast_2 = (pow( saturate( dotResult14 ) , _Hardness )).xxx;
			float temp_output_2_0_g2 = _Opacity;
			float temp_output_3_0_g2 = ( 1.0 - temp_output_2_0_g2 );
			float3 appendResult7_g2 = (float3(temp_output_3_0_g2 , temp_output_3_0_g2 , temp_output_3_0_g2));
			o.Emission = ( ( temp_cast_2 * temp_output_2_0_g2 ) + appendResult7_g2 );
			o.Alpha = 1;
		}

		ENDCG
	}
	Fallback "Diffuse"
	CustomEditor "ASEMaterialInspector"
}
/*ASEBEGIN
Version=18800
-1786;19;1736;1053;395.6711;1243.239;1.490308;True;True
Node;AmplifyShaderEditor.TextureCoordinatesNode;1;-586.5958,-819.1882;Inherit;True;0;-1;2;3;2;SAMPLER2D;;False;0;FLOAT2;1,1;False;1;FLOAT2;0,0;False;5;FLOAT2;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RangedFloatNode;3;-259.4821,-575.6013;Inherit;False;Property;_c;c;3;0;Create;True;0;0;0;False;0;False;-0.5;0.5;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleSubtractOpNode;15;32.16618,-699.8299;Inherit;False;2;0;FLOAT2;0,0;False;1;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RangedFloatNode;7;-103.0228,-514.1489;Inherit;False;Property;_Radius;Radius;4;0;Create;True;0;0;0;False;0;False;10;0.444;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleDivideOpNode;17;224.1662,-699.8299;Inherit;False;2;0;FLOAT2;0,0;False;1;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.DotProductOpNode;14;384.1662,-699.8299;Inherit;False;2;0;FLOAT2;0,0;False;1;FLOAT2;0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SaturateNode;13;528.1663,-699.8299;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;9;305.7671,-498.6534;Inherit;False;Property;_Hardness;Hardness;1;0;Create;True;0;0;0;False;0;False;10;3.68;1;10;0;1;FLOAT;0
Node;AmplifyShaderEditor.PowerNode;16;704.1661,-699.8299;Inherit;False;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;18;772.7302,-301.3643;Inherit;False;Property;_Opacity;Opacity;2;0;Create;True;0;0;0;False;0;False;10;1;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.FunctionNode;19;1170.643,-445.924;Inherit;False;Lerp White To;-1;;2;047d7c189c36a62438973bad9d37b1c2;0;2;1;FLOAT3;0,0,0;False;2;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.StandardSurfaceOutputNode;11;1589.497,-467.3919;Float;False;True;-1;2;ASEMaterialInspector;0;0;Unlit;SSS/Demo/AO;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;False;False;False;False;False;False;Back;0;False;-1;0;False;-1;False;0;False;-1;0;False;-1;False;0;Custom;0.5;True;True;0;False;Transparent;;Transparent;All;14;all;True;True;True;True;0;False;-1;False;0;False;-1;255;False;-1;255;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;False;2;15;10;25;False;0.5;True;6;2;False;-1;0;False;-1;0;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;0;0,0,0,0;VertexOffset;True;False;Cylindrical;False;Relative;0;;0;-1;-1;-1;0;False;0;0;False;-1;-1;0;False;-1;0;0;0;False;0.1;False;-1;0;False;-1;False;15;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;2;FLOAT3;0,0,0;False;3;FLOAT;0;False;4;FLOAT;0;False;6;FLOAT3;0,0,0;False;7;FLOAT3;0,0,0;False;8;FLOAT;0;False;9;FLOAT;0;False;10;FLOAT;0;False;13;FLOAT3;0,0,0;False;11;FLOAT3;0,0,0;False;12;FLOAT3;0,0,0;False;14;FLOAT4;0,0,0,0;False;15;FLOAT3;0,0,0;False;0
WireConnection;15;0;1;0
WireConnection;15;1;3;0
WireConnection;17;0;15;0
WireConnection;17;1;7;0
WireConnection;14;0;17;0
WireConnection;14;1;17;0
WireConnection;13;0;14;0
WireConnection;16;0;13;0
WireConnection;16;1;9;0
WireConnection;19;1;16;0
WireConnection;19;2;18;0
WireConnection;11;2;19;0
ASEEND*/
//CHKSM=55B854A294A325200CF11303635A1D789C44539B