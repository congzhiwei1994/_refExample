// Made with Amplify Shader Editor
// Available at the Unity Asset Store - http://u3d.as/y3X 
Shader "SSS/RT viewers/Depth difference"
{
	Properties
	{
		[HideInInspector]_MainTex("MainTex", 2D) = "white" {}
		[Toggle(_RIGHTEYE1_ON)] _RightEye1("Right Eye", Float) = 0
		_Intensity("Intensity", Range( 0 , 1)) = 0.17
		[HideInInspector] _texcoord( "", 2D ) = "white" {}

	}
	
	SubShader
	{
		
		
		Tags { "RenderType"="Opaque" }
	LOD 100

		CGINCLUDE
		#pragma target 3.0
		ENDCG
		Blend Off
		AlphaToMask Off
		Cull Back
		ColorMask RGBA
		ZWrite On
		ZTest LEqual
		Offset 0 , 0
		
		
		
		Pass
		{
			Name "Unlit"
			Tags { "LightMode"="ForwardBase" }
			CGPROGRAM

			

			#ifndef UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX
			//only defining to not throw compilation error over Unity 5.5
			#define UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input)
			#endif
			#pragma vertex vert
			#pragma fragment frag
			#pragma multi_compile_instancing
			#include "UnityCG.cginc"
			#pragma shader_feature_local _RIGHTEYE1_ON


			struct appdata
			{
				float4 vertex : POSITION;
				float4 color : COLOR;
				float4 ase_texcoord : TEXCOORD0;
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};
			
			struct v2f
			{
				float4 vertex : SV_POSITION;
				#ifdef ASE_NEEDS_FRAG_WORLD_POSITION
				float3 worldPos : TEXCOORD0;
				#endif
				float4 ase_texcoord1 : TEXCOORD1;
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};

			uniform sampler2D SSS_TransparencyTex;
			uniform float4 SSS_TransparencyTex_ST;
			uniform sampler2D LightingTex;
			uniform float4 LightingTex_ST;
			uniform sampler2D SSS_TransparencyTexR;
			uniform float4 SSS_TransparencyTexR_ST;
			uniform sampler2D LightingTexR;
			uniform float4 LightingTexR_ST;
			uniform float _Intensity;
			uniform sampler2D _MainTex;
			uniform float4 _MainTex_ST;
			float MyCustomExpression13( float In0 )
			{
				return LinearEyeDepth(In0);
			}
			
			float MyCustomExpression12( float In0 )
			{
				return LinearEyeDepth(In0);
			}
			
			float MyCustomExpression22( float In0 )
			{
				return LinearEyeDepth(In0);
			}
			
			float MyCustomExpression24( float In0 )
			{
				return LinearEyeDepth(In0);
			}
			

			
			v2f vert ( appdata v )
			{
				v2f o;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
				UNITY_TRANSFER_INSTANCE_ID(v, o);

				o.ase_texcoord1.xy = v.ase_texcoord.xy;
				
				//setting value to unused interpolator channels and avoid initialization warnings
				o.ase_texcoord1.zw = 0;
				float3 vertexValue = float3(0, 0, 0);
				#if ASE_ABSOLUTE_VERTEX_POS
				vertexValue = v.vertex.xyz;
				#endif
				vertexValue = vertexValue;
				#if ASE_ABSOLUTE_VERTEX_POS
				v.vertex.xyz = vertexValue;
				#else
				v.vertex.xyz += vertexValue;
				#endif
				o.vertex = UnityObjectToClipPos(v.vertex);

				#ifdef ASE_NEEDS_FRAG_WORLD_POSITION
				o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
				#endif
				return o;
			}
			
			fixed4 frag (v2f i ) : SV_Target
			{
				UNITY_SETUP_INSTANCE_ID(i);
				UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i);
				fixed4 finalColor;
				#ifdef ASE_NEEDS_FRAG_WORLD_POSITION
				float3 WorldPosition = i.worldPos;
				#endif
				float2 uvSSS_TransparencyTex = i.ase_texcoord1.xy * SSS_TransparencyTex_ST.xy + SSS_TransparencyTex_ST.zw;
				float In013 = tex2D( SSS_TransparencyTex, uvSSS_TransparencyTex ).a;
				float localMyCustomExpression13 = MyCustomExpression13( In013 );
				float2 uvLightingTex = i.ase_texcoord1.xy * LightingTex_ST.xy + LightingTex_ST.zw;
				float In012 = tex2D( LightingTex, uvLightingTex ).a;
				float localMyCustomExpression12 = MyCustomExpression12( In012 );
				float2 uvSSS_TransparencyTexR = i.ase_texcoord1.xy * SSS_TransparencyTexR_ST.xy + SSS_TransparencyTexR_ST.zw;
				float In022 = tex2D( SSS_TransparencyTexR, uvSSS_TransparencyTexR ).a;
				float localMyCustomExpression22 = MyCustomExpression22( In022 );
				float2 uvLightingTexR = i.ase_texcoord1.xy * LightingTexR_ST.xy + LightingTexR_ST.zw;
				float In024 = tex2D( LightingTexR, uvLightingTexR ).a;
				float localMyCustomExpression24 = MyCustomExpression24( In024 );
				#ifdef _RIGHTEYE1_ON
				float staticSwitch17 = ( localMyCustomExpression22 - localMyCustomExpression24 );
				#else
				float staticSwitch17 = ( localMyCustomExpression13 - localMyCustomExpression12 );
				#endif
				float2 uv_MainTex = i.ase_texcoord1.xy * _MainTex_ST.xy + _MainTex_ST.zw;
				float4 temp_cast_0 = (( staticSwitch17 * _Intensity * tex2D( _MainTex, uv_MainTex ).a )).xxxx;
				
				
				finalColor = temp_cast_0;
				return finalColor;
			}
			ENDCG
		}
	}
	CustomEditor "ASEMaterialInspector"
	
	
}
/*ASEBEGIN
Version=18800
-1667;57;1559;905;1778.277;1110.536;2.593451;True;True
Node;AmplifyShaderEditor.TexturePropertyNode;18;-969.6954,-90.60325;Inherit;True;Global;LightingTexR;LightingTexR;3;0;Create;True;0;0;0;False;0;False;None;;False;white;Auto;Texture2D;-1;0;2;SAMPLER2D;0;SAMPLERSTATE;1
Node;AmplifyShaderEditor.TexturePropertyNode;8;-949.1151,-560.2804;Inherit;True;Global;LightingTex;LightingTex;2;0;Create;True;0;0;0;False;0;False;None;;False;white;Auto;Texture2D;-1;0;2;SAMPLER2D;0;SAMPLERSTATE;1
Node;AmplifyShaderEditor.TexturePropertyNode;9;-944.1151,-337.2804;Inherit;True;Global;SSS_TransparencyTex;SSS_TransparencyTex;0;0;Create;True;0;0;0;False;0;False;None;;False;white;Auto;Texture2D;-1;0;2;SAMPLER2D;0;SAMPLERSTATE;1
Node;AmplifyShaderEditor.TexturePropertyNode;19;-964.6954,132.3968;Inherit;True;Global;SSS_TransparencyTexR;SSS_TransparencyTexR;1;0;Create;True;0;0;0;False;0;False;None;;False;white;Auto;Texture2D;-1;0;2;SAMPLER2D;0;SAMPLERSTATE;1
Node;AmplifyShaderEditor.SamplerNode;21;-701.6954,124.8968;Inherit;True;Property;_TextureSample3;Texture Sample 0;0;0;Create;True;0;0;0;False;0;False;-1;None;None;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SamplerNode;20;-697.6954,-111.6033;Inherit;True;Property;_TextureSample2;Texture Sample 1;5;0;Create;True;0;0;0;False;0;False;-1;None;None;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SamplerNode;10;-677.1151,-581.2804;Inherit;True;Property;_TextureSample1;Texture Sample 1;5;0;Create;True;0;0;0;False;0;False;-1;None;None;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SamplerNode;2;-681.1151,-344.7804;Inherit;True;Property;_TextureSample0;Texture Sample 0;0;0;Create;True;0;0;0;False;0;False;-1;None;None;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.CustomExpressionNode;13;-191.1151,-523.2804;Inherit;False;return LinearEyeDepth(In0)@;1;False;1;True;In0;FLOAT;0;In;;Inherit;False;My Custom Expression;True;False;0;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.CustomExpressionNode;12;-191.1151,-613.2805;Inherit;False;return LinearEyeDepth(In0)@;1;False;1;True;In0;FLOAT;0;In;;Inherit;False;My Custom Expression;True;False;0;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.CustomExpressionNode;22;-211.6954,-53.60324;Inherit;False;return LinearEyeDepth(In0)@;1;False;1;True;In0;FLOAT;0;In;;Inherit;False;My Custom Expression;True;False;0;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.CustomExpressionNode;24;-211.6954,-143.6034;Inherit;False;return LinearEyeDepth(In0)@;1;False;1;True;In0;FLOAT;0;In;;Inherit;False;My Custom Expression;True;False;0;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleSubtractOpNode;23;93.30458,-51.60324;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleSubtractOpNode;11;113.8849,-521.2804;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.StaticSwitch;17;425.7033,-432.7838;Inherit;False;Property;_RightEye1;Right Eye;5;0;Create;True;0;0;0;False;0;False;0;0;0;True;;Toggle;2;Key0;Key1;Create;True;True;9;1;FLOAT;0;False;0;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;4;FLOAT;0;False;5;FLOAT;0;False;6;FLOAT;0;False;7;FLOAT;0;False;8;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;16;270,203;Inherit;False;Property;_Intensity;Intensity;6;0;Create;True;0;0;0;False;0;False;0.17;0.1647059;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.SamplerNode;4;-703,400.5;Inherit;True;Property;_MainTex;MainTex;4;1;[HideInInspector];Create;True;0;0;0;False;0;False;-1;None;None;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;15;655,111;Inherit;False;3;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;6;876,53;Float;False;True;-1;2;ASEMaterialInspector;100;1;SSS/RT viewers/Depth difference;0770190933193b94aaa3065e307002fa;True;Unlit;0;0;Unlit;2;True;0;1;False;-1;0;False;-1;0;1;False;-1;0;False;-1;True;0;False;-1;0;False;-1;False;False;False;False;False;False;True;0;False;-1;True;0;False;-1;True;True;True;True;True;0;False;-1;False;False;False;True;False;255;False;-1;255;False;-1;255;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;True;1;False;-1;True;3;False;-1;True;True;0;False;-1;0;False;-1;True;1;RenderType=Opaque=RenderType;True;2;0;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;1;LightMode=ForwardBase;False;0;;0;0;Standard;1;Vertex Position,InvertActionOnDeselection;1;0;1;True;False;;False;0
WireConnection;21;0;19;0
WireConnection;20;0;18;0
WireConnection;10;0;8;0
WireConnection;2;0;9;0
WireConnection;13;0;2;4
WireConnection;12;0;10;4
WireConnection;22;0;21;4
WireConnection;24;0;20;4
WireConnection;23;0;22;0
WireConnection;23;1;24;0
WireConnection;11;0;13;0
WireConnection;11;1;12;0
WireConnection;17;1;11;0
WireConnection;17;0;23;0
WireConnection;15;0;17;0
WireConnection;15;1;16;0
WireConnection;15;2;4;4
WireConnection;6;0;15;0
ASEEND*/
//CHKSM=F395B28F6FFA8BD6EF750AC069D765CB155E83CF