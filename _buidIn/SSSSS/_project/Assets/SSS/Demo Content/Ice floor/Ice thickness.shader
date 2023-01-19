// Made with Amplify Shader Editor
// Available at the Unity Asset Store - http://u3d.as/y3X 
Shader "SSS/Demo/Ice thickness"
{
	Properties
	{
		_Color("Color", Color) = (0.3901744,0.5953239,0.6037736,0)
		_Colortransmission("Color transmission", Color) = (0.3901744,0.5953239,0.6037736,0)
		[NoScaleOffset]_tex("tex", 2D) = "white" {}
		_Displacement("Displacement", Range( 0 , 0.001)) = 0
		_PushAlpha("Push Alpha", Range( 0.9 , 1.5)) = 0
		_end("end", Range( 0 , 0.03)) = 0
		_end2("end2", Range( 0 , 0.0061)) = 0
		_Transmission("Transmission", Range( 0 , 4)) = 0
		_Tiling("Tiling", Float) = 0
		[HideInInspector] _texcoord( "", 2D ) = "white" {}
		[HideInInspector] __dirty( "", Int ) = 1
	}

	SubShader
	{
		Tags{ "RenderType" = "Transparent"  "Queue" = "Transparent+0" "IgnoreProjector" = "True" "DisableBatching" = "True" }
		Cull Back
		CGPROGRAM
		#pragma target 3.0
		#pragma surface surf Lambert alpha:fade keepalpha exclude_path:deferred nometa noforwardadd 
		struct Input
		{
			float3 worldNormal;
			INTERNAL_DATA
			float3 worldPos;
			float2 uv_texcoord;
		};

		uniform float4 _Color;
		uniform float4 _Colortransmission;
		uniform sampler2D _tex;
		uniform float _Tiling;
		uniform float _Displacement;
		uniform float _end;
		uniform float _end2;
		uniform float _PushAlpha;
		uniform float _Transmission;


		float4 parallax3( sampler2D t, float3 E, float2 uv, float d, float end, float end2, float alpha )
		{
			#define steps 30
			float4 c=0, c2=0;
			for(int i= steps; i>= 0 ; i --)
			{
				float2 dispUV = -E.xy/E.z * i * d + uv;
				c = 1- tex2Dlod(t, float4(dispUV, 0, 0));
				c2.a = c2.a + c.a * saturate((1.0 - c.a * alpha));
				c2.r = c2.r + c.r * saturate((1.0 - c.a * alpha));
				
				c2.r = pow(c2.r  ,1 + i * end2);
				c2.a = pow(c2.a  ,1 + i * end);
			}
			return (c2);
		}


		void surf( Input i , inout SurfaceOutput o )
		{
			o.Normal = float3(0,0,1);
			sampler2D t3 = _tex;
			float3 ase_worldPos = i.worldPos;
			float3 ase_worldViewDir = Unity_SafeNormalize( UnityWorldSpaceViewDir( ase_worldPos ) );
			float3 ase_worldNormal = WorldNormalVector( i, float3( 0, 0, 1 ) );
			float3 ase_worldTangent = WorldNormalVector( i, float3( 1, 0, 0 ) );
			float3 ase_worldBitangent = WorldNormalVector( i, float3( 0, 1, 0 ) );
			float3x3 ase_worldToTangent = float3x3( ase_worldTangent, ase_worldBitangent, ase_worldNormal );
			float3 ase_tanViewDir = mul( ase_worldToTangent, ase_worldViewDir );
			float3 E3 = ase_tanViewDir;
			float2 temp_cast_0 = (_Tiling).xx;
			float2 uv_TexCoord5 = i.uv_texcoord * temp_cast_0;
			float2 uv3 = uv_TexCoord5;
			float d3 = _Displacement;
			float end3 = _end;
			float end23 = _end2;
			float alpha3 = _PushAlpha;
			float4 localparallax3 = parallax3( t3 , E3 , uv3 , d3 , end3 , end23 , alpha3 );
			float4 temp_output_41_0 = ( _Colortransmission * (localparallax3).x * 0.2 * _Transmission );
			o.Albedo = ( _Color + temp_output_41_0 ).rgb;
			float temp_output_39_0 = (localparallax3).w;
			float temp_output_48_0 = ( 1.0 - exp( -( _Color.a * temp_output_39_0 ) ) );
			o.Alpha = temp_output_48_0;
		}

		ENDCG
	}
	Fallback "Diffuse"
	CustomEditor "ASEMaterialInspector"
}
/*ASEBEGIN
Version=18800
2675;47;2334;1253;952.5999;598.9981;1;True;True
Node;AmplifyShaderEditor.RangedFloatNode;26;-2159.904,382.7578;Inherit;False;Property;_Tiling;Tiling;8;0;Create;True;0;0;0;False;0;False;0;0.5;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.TextureCoordinatesNode;5;-1249.915,213.5632;Inherit;False;0;-1;2;3;2;SAMPLER2D;;False;0;FLOAT2;0.5,0.5;False;1;FLOAT2;0,0;False;5;FLOAT2;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RangedFloatNode;7;-1871.1,87.80007;Inherit;False;Property;_Displacement;Displacement;3;0;Create;True;0;0;0;False;0;False;0;0.000163;0;0.001;0;1;FLOAT;0
Node;AmplifyShaderEditor.TexturePropertyNode;2;-1199,-198.5;Inherit;True;Property;_tex;tex;2;1;[NoScaleOffset];Create;True;0;0;0;False;0;False;62341cb5dcb18894585d5aa2a3c2c7f4;62341cb5dcb18894585d5aa2a3c2c7f4;False;white;Auto;Texture2D;-1;0;2;SAMPLER2D;0;SAMPLERSTATE;1
Node;AmplifyShaderEditor.RangedFloatNode;50;-1173.594,99.82993;Inherit;False;Property;_end2;end2;6;0;Create;True;0;0;0;False;0;False;0;0.00359;0;0.0061;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;23;-1756.742,632.2747;Inherit;False;Property;_PushAlpha;Push Alpha;4;0;Create;True;0;0;0;False;0;False;0;1.053;0.9;1.5;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;24;-1447.41,-11.84818;Inherit;False;Property;_end;end;5;0;Create;True;0;0;0;False;0;False;0;0.0004;0;0.03;0;1;FLOAT;0
Node;AmplifyShaderEditor.ViewDirInputsCoordNode;20;-1946.528,-210.7254;Float;False;Tangent;True;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.CustomExpressionNode;3;-634,-76.5;Inherit;False;#define steps 30$float4 c=0, c2=0@$$for(int i= steps@ i>= 0 @ i --)${$	float2 dispUV = -E.xy/E.z * i * d + uv@$	c = 1- tex2Dlod(t, float4(dispUV, 0, 0))@$$	c2.a = c2.a + c.a * saturate((1.0 - c.a * alpha))@$	c2.r = c2.r + c.r * saturate((1.0 - c.a * alpha))@$	$	c2.r = pow(c2.r  ,1 + i * end2)@$	c2.a = pow(c2.a  ,1 + i * end)@$$}$$$return (c2)@$;4;False;7;True;t;SAMPLER2D;;In;;Inherit;False;True;E;FLOAT3;0,0,0;In;;Inherit;False;True;uv;FLOAT2;0,0;In;;Inherit;False;True;d;FLOAT;0;In;;Inherit;False;True;end;FLOAT;0.02;In;;Inherit;False;True;end2;FLOAT;0;In;;Inherit;False;True;alpha;FLOAT;1;In;;Inherit;False;parallax;True;False;0;7;0;SAMPLER2D;;False;1;FLOAT3;0,0,0;False;2;FLOAT2;0,0;False;3;FLOAT;0;False;4;FLOAT;0.02;False;5;FLOAT;0;False;6;FLOAT;1;False;1;FLOAT4;0
Node;AmplifyShaderEditor.ComponentMaskNode;39;-310.5939,65.82993;Inherit;False;False;False;False;True;1;0;FLOAT4;0,0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ColorNode;25;-345.6813,-549.5655;Inherit;False;Property;_Color;Color;0;0;Create;True;0;0;0;False;0;False;0.3901744,0.5953239,0.6037736,0;0.7122642,0.9641692,1,0.07058824;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;27;202.2258,144.3231;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ColorNode;54;-509.5999,-297.9981;Inherit;False;Property;_Colortransmission;Color transmission;1;0;Create;True;0;0;0;False;0;False;0.3901744,0.5953239,0.6037736,0;0.1982467,0.4245283,0.4245283,1;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.ComponentMaskNode;40;-326.5939,-70.17007;Inherit;False;True;False;False;False;1;0;FLOAT4;0,0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;28;30.40613,-2.170074;Inherit;False;Property;_Transmission;Transmission;7;0;Create;True;0;0;0;False;0;False;0;0.89;0;4;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;46;170.4061,-50.17007;Inherit;False;Constant;_Float0;Float 0;7;0;Create;True;0;0;0;False;0;False;0.2;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.NegateNode;52;363.4063,172.83;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;41;330.4061,-210.1701;Inherit;False;4;4;0;COLOR;0,0,0,0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.ExpOpNode;51;649.4063,192.83;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.OneMinusNode;48;764.4061,114.8299;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SaturateNode;33;-28.59387,152.8299;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.Exp2OpNode;53;580.4063,122.83;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;44;668.4061,-251.1701;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.SaturateNode;49;512.4061,-128.1701;Inherit;False;1;0;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.StandardSurfaceOutputNode;0;1015.121,-229.3538;Float;False;True;-1;2;ASEMaterialInspector;0;0;Lambert;SSS/Demo/Ice thickness;False;False;False;False;False;False;False;False;False;False;True;True;False;True;True;False;False;False;False;False;False;Back;0;False;-1;0;False;-1;False;0;False;-1;0;False;-1;False;0;Transparent;0.5;True;False;0;False;Transparent;;Transparent;ForwardOnly;14;all;True;True;True;True;0;False;-1;False;0;False;-1;255;False;-1;255;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;False;2;15;10;25;False;0.5;True;2;5;False;-1;10;False;-1;0;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;0;0,0,0,0;VertexOffset;True;False;Cylindrical;False;Relative;0;;-1;-1;-1;-1;0;False;0;0;False;-1;-1;0;False;-1;0;0;0;False;0.1;False;-1;0;False;-1;False;15;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;2;FLOAT3;0,0,0;False;3;FLOAT;0;False;4;FLOAT;0;False;6;FLOAT3;0,0,0;False;7;FLOAT3;0,0,0;False;8;FLOAT;0;False;9;FLOAT;0;False;10;FLOAT;0;False;13;FLOAT3;0,0,0;False;11;FLOAT3;0,0,0;False;12;FLOAT3;0,0,0;False;14;FLOAT4;0,0,0,0;False;15;FLOAT3;0,0,0;False;0
WireConnection;5;0;26;0
WireConnection;3;0;2;0
WireConnection;3;1;20;0
WireConnection;3;2;5;0
WireConnection;3;3;7;0
WireConnection;3;4;24;0
WireConnection;3;5;50;0
WireConnection;3;6;23;0
WireConnection;39;0;3;0
WireConnection;27;0;25;4
WireConnection;27;1;39;0
WireConnection;40;0;3;0
WireConnection;52;0;27;0
WireConnection;41;0;54;0
WireConnection;41;1;40;0
WireConnection;41;2;46;0
WireConnection;41;3;28;0
WireConnection;51;0;52;0
WireConnection;48;0;51;0
WireConnection;33;0;39;0
WireConnection;44;0;25;0
WireConnection;44;1;41;0
WireConnection;49;0;41;0
WireConnection;0;0;44;0
WireConnection;0;9;48;0
ASEEND*/
//CHKSM=39C58981BF8BCAAFFA21726C48DFE2E64016DDF1