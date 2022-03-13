// Made with Amplify Shader Editor
// Available at the Unity Asset Store - http://u3d.as/y3X 
Shader "E3DEffect/C2/Flipbook-blend"
{
	Properties
	{
		_MaskMap("MaskMap", 2D) = "white" {}
		_BaseMap("BaseMap", 2D) = "white" {}
		[HDR]_BaseColor("BaseColor", Color) = (1,1,1,1)
		_Glow("Glow", Range( 0 , 4)) = 1
		_Y("Y", Float) = 4
		_X("X", Float) = 4
		[HideInInspector] _texcoord( "", 2D ) = "white" {}
		[HideInInspector] __dirty( "", Int ) = 1
	}

	SubShader
	{
		Tags{ "RenderType" = "Transparent"  "Queue" = "Transparent+0" "IgnoreProjector" = "True" "IsEmissive" = "true"  }
		Cull Off
		CGPROGRAM
		#include "UnityPBSLighting.cginc"
		#include "UnityShaderVariables.cginc"
		#pragma target 3.0
		#pragma exclude_renderers xbox360 xboxone ps4 psp2 n3ds wiiu 
		#pragma surface surf StandardCustomLighting alpha:fade keepalpha noshadow nolightmap  nodynlightmap nodirlightmap noforwardadd 
		struct Input
		{
			float4 vertexColor : COLOR;
			float2 uv_texcoord;
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

		uniform float4 _BaseColor;
		uniform sampler2D _BaseMap;
		uniform float _X;
		uniform float _Y;
		uniform sampler2D _MaskMap;
		uniform float4 _MaskMap_ST;
		uniform float _Glow;

		inline half4 LightingStandardCustomLighting( inout SurfaceOutputCustomLightingCustom s, half3 viewDir, UnityGI gi )
		{
			UnityGIInput data = s.GIData;
			Input i = s.SurfInput;
			half4 c = 0;
			// *** BEGIN Flipbook UV Animation vars ***
			// Total tiles of Flipbook Texture
			float fbtotaltiles98 = _X * _Y;
			// Offsets for cols and rows of Flipbook Texture
			float fbcolsoffset98 = 1.0f / _X;
			float fbrowsoffset98 = 1.0f / _Y;
			// Speed of animation
			float fbspeed98 = _Time.y * 3.0;
			// UV Tiling (col and row offset)
			float2 fbtiling98 = float2(fbcolsoffset98, fbrowsoffset98);
			// UV Offset - calculate current tile linear index, and convert it to (X * coloffset, Y * rowoffset)
			// Calculate current tile linear index
			float fbcurrenttileindex98 = round( fmod( fbspeed98 + 0.0, fbtotaltiles98) );
			fbcurrenttileindex98 += ( fbcurrenttileindex98 < 0) ? fbtotaltiles98 : 0;
			// Obtain Offset X coordinate from current tile linear index
			float fblinearindextox98 = round ( fmod ( fbcurrenttileindex98, _X ) );
			// Multiply Offset X by coloffset
			float fboffsetx98 = fblinearindextox98 * fbcolsoffset98;
			// Obtain Offset Y coordinate from current tile linear index
			float fblinearindextoy98 = round( fmod( ( fbcurrenttileindex98 - fblinearindextox98 ) / _X, _Y ) );
			// Reverse Y to get tiles from Top to Bottom
			fblinearindextoy98 = (int)(_Y-1) - fblinearindextoy98;
			// Multiply Offset Y by rowoffset
			float fboffsety98 = fblinearindextoy98 * fbrowsoffset98;
			// UV Offset
			float2 fboffset98 = float2(fboffsetx98, fboffsety98);
			// Flipbook UV
			half2 fbuv98 = i.uv_texcoord * fbtiling98 + fboffset98;
			// *** END Flipbook UV Animation vars ***
			float4 tex2DNode54 = tex2D( _BaseMap, fbuv98 );
			float2 uv0_MaskMap = i.uv_texcoord * _MaskMap_ST.xy + _MaskMap_ST.zw;
			float2 panner49 = ( _Time.y * float2( 0,0 ) + uv0_MaskMap);
			float4 tex2DNode50 = tex2D( _MaskMap, panner49 );
			c.rgb = 0;
			c.a = ( ( ( _BaseColor.a * i.vertexColor.a ) * ( tex2DNode54.a * tex2DNode50.a ) ) * _Glow );
			return c;
		}

		inline void LightingStandardCustomLighting_GI( inout SurfaceOutputCustomLightingCustom s, UnityGIInput data, inout UnityGI gi )
		{
			s.GIData = data;
		}

		void surf( Input i , inout SurfaceOutputCustomLightingCustom o )
		{
			o.SurfInput = i;
			// *** BEGIN Flipbook UV Animation vars ***
			// Total tiles of Flipbook Texture
			float fbtotaltiles98 = _X * _Y;
			// Offsets for cols and rows of Flipbook Texture
			float fbcolsoffset98 = 1.0f / _X;
			float fbrowsoffset98 = 1.0f / _Y;
			// Speed of animation
			float fbspeed98 = _Time.y * 3.0;
			// UV Tiling (col and row offset)
			float2 fbtiling98 = float2(fbcolsoffset98, fbrowsoffset98);
			// UV Offset - calculate current tile linear index, and convert it to (X * coloffset, Y * rowoffset)
			// Calculate current tile linear index
			float fbcurrenttileindex98 = round( fmod( fbspeed98 + 0.0, fbtotaltiles98) );
			fbcurrenttileindex98 += ( fbcurrenttileindex98 < 0) ? fbtotaltiles98 : 0;
			// Obtain Offset X coordinate from current tile linear index
			float fblinearindextox98 = round ( fmod ( fbcurrenttileindex98, _X ) );
			// Multiply Offset X by coloffset
			float fboffsetx98 = fblinearindextox98 * fbcolsoffset98;
			// Obtain Offset Y coordinate from current tile linear index
			float fblinearindextoy98 = round( fmod( ( fbcurrenttileindex98 - fblinearindextox98 ) / _X, _Y ) );
			// Reverse Y to get tiles from Top to Bottom
			fblinearindextoy98 = (int)(_Y-1) - fblinearindextoy98;
			// Multiply Offset Y by rowoffset
			float fboffsety98 = fblinearindextoy98 * fbrowsoffset98;
			// UV Offset
			float2 fboffset98 = float2(fboffsetx98, fboffsety98);
			// Flipbook UV
			half2 fbuv98 = i.uv_texcoord * fbtiling98 + fboffset98;
			// *** END Flipbook UV Animation vars ***
			float4 tex2DNode54 = tex2D( _BaseMap, fbuv98 );
			float2 uv0_MaskMap = i.uv_texcoord * _MaskMap_ST.xy + _MaskMap_ST.zw;
			float2 panner49 = ( _Time.y * float2( 0,0 ) + uv0_MaskMap);
			float4 tex2DNode50 = tex2D( _MaskMap, panner49 );
			o.Emission = ( ( _BaseColor * i.vertexColor ) * tex2DNode54 * i.vertexColor * tex2DNode50 ).rgb;
		}

		ENDCG
	}
	CustomEditor "ASEMaterialInspector"
}
/*ASEBEGIN
Version=16400
329;444;1906;804;2762.62;1841.587;1;True;False
Node;AmplifyShaderEditor.RangedFloatNode;105;-2462.047,-1391.142;Float;False;Constant;_Speed;Speed;10;0;Create;True;0;0;False;0;3;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleTimeNode;48;-2110.362,-884.8597;Float;False;1;0;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.Vector2Node;46;-2102.566,-1027.959;Float;False;Constant;_MaskSpeed;MaskSpeed;1;0;Create;True;0;0;False;0;0,0;0,0;0;3;FLOAT2;0;FLOAT;1;FLOAT;2
Node;AmplifyShaderEditor.TextureCoordinatesNode;47;-2118.625,-1192.001;Float;False;0;50;2;3;2;SAMPLER2D;;False;0;FLOAT2;1,1;False;1;FLOAT2;0,0;False;5;FLOAT2;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleTimeNode;104;-2474.71,-1292.824;Float;False;1;0;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.TextureCoordinatesNode;99;-2517.378,-1682.514;Float;False;0;-1;2;3;2;SAMPLER2D;;False;0;FLOAT2;1,1;False;1;FLOAT2;0,0;False;5;FLOAT2;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RangedFloatNode;101;-2475.378,-1479.514;Float;False;Property;_Y;Y;4;0;Create;True;0;0;False;0;4;4;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;100;-2456.378,-1555.514;Float;False;Property;_X;X;5;0;Create;True;0;0;False;0;4;4;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.TFHCFlipBookUVAnimation;98;-2127.508,-1678.521;Float;False;0;0;6;0;FLOAT2;0,0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;4;FLOAT;0;False;5;FLOAT;0;False;3;FLOAT2;0;FLOAT;1;FLOAT;2
Node;AmplifyShaderEditor.PannerNode;49;-1780.942,-1077.812;Float;False;3;0;FLOAT2;0,0;False;2;FLOAT2;0,0;False;1;FLOAT;1;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SamplerNode;50;-1542.995,-1116.785;Float;True;Property;_MaskMap;MaskMap;0;0;Create;True;0;0;False;0;None;95e93a31eb312334f930a2e29b8fe0d1;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;6;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.ColorNode;81;-1409.52,-1902.678;Float;False;Property;_BaseColor;BaseColor;2;1;[HDR];Create;True;0;0;False;0;1,1,1,1;2,2,2,1;False;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SamplerNode;54;-1816.484,-1721.116;Float;True;Property;_BaseMap;BaseMap;1;0;Create;True;0;0;False;0;None;7e80656f043bd82409fdcc72a33840cc;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;6;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.VertexColorNode;83;-1451.23,-1401.733;Float;False;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;87;-869.2252,-1068.718;Float;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;84;-952.2669,-1372.834;Float;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;82;-998.0167,-1773.558;Float;False;2;2;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;67;-597.2474,-1142.288;Float;True;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.WireNode;106;-1429.116,-1550.662;Float;False;1;0;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.RangedFloatNode;96;-578.1759,-888.796;Float;False;Property;_Glow;Glow;3;0;Create;True;0;0;False;0;1;2;0;4;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;97;-275.4655,-983.9125;Float;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;85;-579.9029,-1525.337;Float;True;4;4;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;2;COLOR;0,0,0,0;False;3;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.StandardSurfaceOutputNode;0;-16.81488,-1354.438;Float;False;True;2;Float;ASEMaterialInspector;0;0;CustomLighting;E3DEffect/C2/Flipbook-blend;False;False;False;False;False;False;True;True;True;False;False;True;False;False;True;False;False;False;False;False;False;Off;0;False;-1;0;False;-1;False;0;False;-1;0;False;-1;False;0;Transparent;0.5;True;False;0;False;Transparent;;Transparent;All;True;True;True;True;True;True;True;False;False;False;False;False;False;True;True;True;True;0;False;-1;False;0;False;-1;255;False;-1;255;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;False;2;15;10;25;False;0.5;False;2;5;False;-1;10;False;-1;0;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;0;0,0,0,0;VertexOffset;True;False;Cylindrical;False;Relative;0;;-1;-1;-1;-1;0;False;0;0;False;-1;-1;0;False;-1;0;0;0;False;0.1;False;-1;0;False;-1;15;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;2;FLOAT3;0,0,0;False;3;FLOAT3;0,0,0;False;4;FLOAT;0;False;6;FLOAT3;0,0,0;False;7;FLOAT3;0,0,0;False;8;FLOAT;0;False;9;FLOAT;0;False;10;FLOAT;0;False;13;FLOAT3;0,0,0;False;11;FLOAT3;0,0,0;False;12;FLOAT3;0,0,0;False;14;FLOAT4;0,0,0,0;False;15;FLOAT3;0,0,0;False;0
WireConnection;98;0;99;0
WireConnection;98;1;100;0
WireConnection;98;2;101;0
WireConnection;98;3;105;0
WireConnection;98;5;104;0
WireConnection;49;0;47;0
WireConnection;49;2;46;0
WireConnection;49;1;48;0
WireConnection;50;1;49;0
WireConnection;54;1;98;0
WireConnection;87;0;54;4
WireConnection;87;1;50;4
WireConnection;84;0;81;4
WireConnection;84;1;83;4
WireConnection;82;0;81;0
WireConnection;82;1;83;0
WireConnection;67;0;84;0
WireConnection;67;1;87;0
WireConnection;106;0;54;0
WireConnection;97;0;67;0
WireConnection;97;1;96;0
WireConnection;85;0;82;0
WireConnection;85;1;106;0
WireConnection;85;2;83;0
WireConnection;85;3;50;0
WireConnection;0;2;85;0
WireConnection;0;9;97;0
ASEEND*/
//CHKSM=8A2D20514E5A860B6E858F747E35D03E1AE144C6