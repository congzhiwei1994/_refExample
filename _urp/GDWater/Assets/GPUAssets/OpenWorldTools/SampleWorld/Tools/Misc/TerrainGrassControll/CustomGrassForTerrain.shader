// Made with Amplify Shader Editor
// Available at the Unity Asset Store - http://u3d.as/y3X 
Shader "Hidden/TerrainEngine/Details/WavingDoublePass"
{
	Properties
	{
		_Cutoff( "Mask Clip Value", Float ) = 0.5
		[HideInInspector] _texcoord( "", 2D ) = "white" {}
		[HideInInspector] __dirty( "", Int ) = 1
	}

	SubShader
	{
		Tags{ "RenderType" = "Opaque"  "Queue" = "Geometry+0" }
		Cull Off
		CGINCLUDE
		#include "UnityShaderVariables.cginc"
		#include "UnityPBSLighting.cginc"
		#include "Lighting.cginc"
		#pragma target 3.0
		struct Input
		{
			float3 worldPos;
			float2 uv_texcoord;
			float3 worldNormal;
		};

		uniform sampler2D WindNoise;
		uniform float4 WaveControl;
		uniform float WinsSpeedX;
		uniform float WindStrength;
		uniform float WinsSpeedZ;
		uniform float ActorRadius;
		uniform float4 ActorPos;
		uniform float PushStrength;
		uniform float4 BaseColor;
		uniform float4 RootColor;
		uniform float RootOffset;
		uniform float4 FresnelColor;
		uniform float FresnelScale;
		uniform float Smoothness;
		uniform float DistanceFade;
		uniform float _Cutoff = 0.5;

		void vertexDataFunc( inout appdata_full v, out Input o )
		{
			UNITY_INITIALIZE_OUTPUT( Input, o );
			float3 ase_worldPos = mul( unity_ObjectToWorld, v.vertex );
			float4 WaveControl42 = WaveControl;
			float4 tex2DNode32 = tex2Dlod( WindNoise, float4( ( ( (ase_worldPos).xz / (WaveControl42).w ) + ( _Time.y * -(WaveControl42).xy ) ), 0, 0.0) );
			float WindStrength51 = WindStrength;
			float3 appendResult54 = (float3(( ase_worldPos.x + ( sin( ( tex2DNode32.r * UNITY_PI * WinsSpeedX ) ) * (WaveControl42).x * WindStrength51 * v.texcoord.xy.y ) ) , ase_worldPos.y , ( ase_worldPos.z + ( sin( ( tex2DNode32.r * UNITY_PI * WinsSpeedZ ) ) * (WaveControl42).z * WindStrength51 * v.texcoord.xy.y ) )));
			float ActorRadius104 = ActorRadius;
			float4 ActorPos102 = ActorPos;
			float4 normalizeResult149 = normalize( ( float4( appendResult54 , 0.0 ) - ActorPos102 ) );
			float ActorPush106 = PushStrength;
			float2 temp_output_151_0 = ( ( ( ActorRadius104 - min( ActorRadius104 , distance( (appendResult54).xz , (ActorPos102).xz ) ) ) / ( ActorRadius104 + 0.001 ) ) * (normalizeResult149).xz * ActorPush106 * v.texcoord.xy.y );
			float3 appendResult155 = (float3((temp_output_151_0).x , 0.0 , (temp_output_151_0).y));
			float3 worldToObj55 = mul( unity_WorldToObject, float4( ( appendResult54 + appendResult155 ), 1 ) ).xyz;
			float3 ase_vertex3Pos = v.vertex.xyz;
			v.vertex.xyz += ( worldToObj55 - ase_vertex3Pos );
		}

		void surf( Input i , inout SurfaceOutputStandard o )
		{
			float4 lerpResult59 = lerp( BaseColor , RootColor , ( RootOffset - i.uv_texcoord.y ));
			float3 ase_worldPos = i.worldPos;
			float3 ase_worldViewDir = normalize( UnityWorldSpaceViewDir( ase_worldPos ) );
			float3 ase_worldNormal = i.worldNormal;
			float fresnelNdotV160 = dot( ase_worldNormal, ase_worldViewDir );
			float fresnelNode160 = ( 0.0 + 1.0 * pow( 1.0 - fresnelNdotV160, FresnelScale ) );
			float4 lerpResult182 = lerp( lerpResult59 , FresnelColor , fresnelNode160);
			o.Albedo = lerpResult182.rgb;
			o.Metallic = 0.0;
			o.Smoothness = Smoothness;
			o.Alpha = 1;
			clip( ( 1.0 - ( distance( ase_worldPos , _WorldSpaceCameraPos ) / DistanceFade ) ) - _Cutoff );
		}

		ENDCG
		CGPROGRAM
		#pragma surface surf Standard keepalpha fullforwardshadows vertex:vertexDataFunc 

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
			#if ( SHADER_API_D3D11 || SHADER_API_GLCORE || SHADER_API_GLES || SHADER_API_GLES3 || SHADER_API_METAL || SHADER_API_VULKAN )
				#define CAN_SKIP_VPOS
			#endif
			#include "UnityCG.cginc"
			#include "Lighting.cginc"
			#include "UnityPBSLighting.cginc"
			struct v2f
			{
				V2F_SHADOW_CASTER;
				float2 customPack1 : TEXCOORD1;
				float3 worldPos : TEXCOORD2;
				float3 worldNormal : TEXCOORD3;
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
				vertexDataFunc( v, customInputData );
				float3 worldPos = mul( unity_ObjectToWorld, v.vertex ).xyz;
				half3 worldNormal = UnityObjectToWorldNormal( v.normal );
				o.worldNormal = worldNormal;
				o.customPack1.xy = customInputData.uv_texcoord;
				o.customPack1.xy = v.texcoord;
				o.worldPos = worldPos;
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
				float3 worldPos = IN.worldPos;
				half3 worldViewDir = normalize( UnityWorldSpaceViewDir( worldPos ) );
				surfIN.worldPos = worldPos;
				surfIN.worldNormal = IN.worldNormal;
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
Version=17800
1920;543;1211;456;-3540.156;498.1954;1.3;True;False
Node;AmplifyShaderEditor.Vector4Node;38;-2300.914,585.192;Inherit;False;Global;WaveControl;WaveControl;4;0;Create;True;0;0;False;0;0.1,0.1,0,10;0.1,0.1,1,10;0;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RegisterLocalVarNode;42;-2118.717,614.0315;Inherit;False;WaveControl;-1;True;1;0;FLOAT4;0,0,0,0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.GetLocalVarNode;43;-1826.782,609.2944;Inherit;False;42;WaveControl;1;0;OBJECT;;False;1;FLOAT4;0
Node;AmplifyShaderEditor.SwizzleNode;39;-1649.35,606.4467;Inherit;False;FLOAT2;0;1;2;3;1;0;FLOAT4;0,0,0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.GetLocalVarNode;44;-1847.346,276.0397;Inherit;False;42;WaveControl;1;0;OBJECT;;False;1;FLOAT4;0
Node;AmplifyShaderEditor.WorldPosInputsNode;23;-1921.598,52.5253;Inherit;False;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.SwizzleNode;45;-1649.346,277.0397;Inherit;False;FLOAT;3;1;2;3;1;0;FLOAT4;0,0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SwizzleNode;24;-1663.932,178.9768;Inherit;False;FLOAT2;0;2;2;3;1;0;FLOAT3;0,0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.TimeNode;29;-1605.377,420.8577;Inherit;False;0;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.NegateNode;40;-1494.35,600.4467;Inherit;False;1;0;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;30;-1319.377,482.8577;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleDivideOpNode;27;-1398.932,214.9768;Inherit;True;2;0;FLOAT2;0,0;False;1;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleAddOpNode;28;-1108.941,420.603;Inherit;False;2;2;0;FLOAT2;0,0;False;1;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.PiNode;37;-833.4919,597.1464;Inherit;False;1;0;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.SamplerNode;32;-898.9407,316.603;Inherit;True;Global;WindNoise;WindNoise;1;0;Create;True;0;0;False;0;-1;None;e28dc97a9541e3642a48c0e3886688c5;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;6;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RangedFloatNode;50;-2439.096,809.0247;Inherit;False;Global;WindStrength;WindStrength;3;0;Create;True;0;0;False;0;0.5;0.3;0;5;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;35;-1107.869,657.6041;Inherit;False;Global;WinsSpeedX;WinsSpeedX;4;0;Create;True;0;0;False;0;0.5176471;0.08;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;76;-860.4309,1063.727;Inherit;False;Global;WinsSpeedZ;WinsSpeedZ;0;0;Create;True;0;0;False;0;0;0.08;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;51;-2118.096,807.0247;Inherit;False;WindStrength;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;34;-541.4921,572.1464;Inherit;True;3;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;70;-578.0983,1284.047;Inherit;False;42;WaveControl;1;0;OBJECT;;False;1;FLOAT4;0
Node;AmplifyShaderEditor.GetLocalVarNode;47;-515.7787,791.3816;Inherit;False;42;WaveControl;1;0;OBJECT;;False;1;FLOAT4;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;68;-545.8118,1030.812;Inherit;True;3;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SinOpNode;75;-297.7054,1095.49;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.TextureCoordinatesNode;53;-293.2874,952.7372;Inherit;False;0;-1;2;3;2;SAMPLER2D;;False;0;FLOAT2;1,1;False;1;FLOAT2;0,0;False;5;FLOAT2;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.GetLocalVarNode;52;-381.5947,897.6931;Inherit;False;51;WindStrength;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.SwizzleNode;71;-385.0984,1293.047;Inherit;False;FLOAT;2;1;2;3;1;0;FLOAT4;0,0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SinOpNode;33;-327.4922,573.1464;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SwizzleNode;48;-322.7787,800.3816;Inherit;False;FLOAT;0;1;2;3;1;0;FLOAT4;0,0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;72;-443.9144,1390.359;Inherit;False;51;WindStrength;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.Vector4Node;78;385.7032,861.4308;Inherit;False;Global;ActorPos;ActorPos;1;0;Create;True;0;0;False;0;0,0,0,0;-16.71931,2.222355,6.882703,0;0;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;73;158.9016,1092.047;Inherit;False;4;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;46;-85.77873,645.3816;Inherit;False;4;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;49;193.1267,88.9304;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;102;608.4024,858.9948;Inherit;False;ActorPos;-1;True;1;0;FLOAT4;0,0,0,0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.SimpleAddOpNode;77;227.9478,240.4292;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;141;772.8176,445.4517;Inherit;False;102;ActorPos;1;0;OBJECT;;False;1;FLOAT4;0
Node;AmplifyShaderEditor.RangedFloatNode;85;378.5439,1065.338;Inherit;False;Global;ActorRadius;ActorRadius;1;0;Create;True;0;0;False;0;0.5;1.25;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.DynamicAppendNode;54;535.2667,145.7764;Inherit;False;FLOAT3;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;104;580.4067,1084.497;Inherit;False;ActorRadius;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SwizzleNode;140;982.1176,440.2516;Inherit;False;FLOAT2;0;2;2;3;1;0;FLOAT4;0,0,0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SwizzleNode;139;985.7394,329.4735;Inherit;False;FLOAT2;0;2;2;3;1;0;FLOAT3;0,0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.DistanceOpNode;137;1267.217,351.0517;Inherit;False;2;0;FLOAT2;0,0;False;1;FLOAT2;0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;143;1402.817,265.3516;Inherit;False;104;ActorRadius;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleSubtractOpNode;148;1927.645,611.4279;Inherit;True;2;0;FLOAT3;0,0,0;False;1;FLOAT4;0,0,0,0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.RangedFloatNode;147;1831.799,520.3028;Inherit;False;Constant;_Float2;Float 2;1;0;Create;True;0;0;False;0;0.001;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;88;372.5642,730.898;Inherit;False;Global;PushStrength;PushStrength;1;0;Create;True;0;0;False;0;0.5;1.25;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMinOpNode;142;1604.018,326.4517;Inherit;True;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.NormalizeNode;149;2161.708,592.8472;Inherit;False;1;0;FLOAT4;0,0,0,0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.SimpleSubtractOpNode;144;1836.799,271.3028;Inherit;True;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;106;560.7634,730.6457;Inherit;False;ActorPush;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;146;2002.799,487.3028;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleDivideOpNode;145;2124.799,273.3028;Inherit;True;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.TextureCoordinatesNode;153;2305.425,749.3293;Inherit;False;0;-1;2;3;2;SAMPLER2D;;False;0;FLOAT2;1,1;False;1;FLOAT2;0,0;False;5;FLOAT2;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.GetLocalVarNode;152;2373.425,670.3293;Inherit;False;106;ActorPush;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.SwizzleNode;150;2344.612,578.8181;Inherit;False;FLOAT2;0;2;2;3;1;0;FLOAT4;0,0,0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;151;2624.062,524.0969;Inherit;False;4;4;0;FLOAT;0;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SwizzleNode;158;2821.902,643.4709;Inherit;False;FLOAT;2;1;2;3;1;0;FLOAT2;0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SwizzleNode;157;2810.902,407.4709;Inherit;False;FLOAT;0;1;2;3;1;0;FLOAT2;0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.TextureCoordinatesNode;61;141.5957,-163.288;Inherit;False;0;-1;2;3;2;SAMPLER2D;;False;0;FLOAT2;1,1;False;1;FLOAT2;0,0;False;5;FLOAT2;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RangedFloatNode;63;127.5957,-296.288;Inherit;False;Global;RootOffset;RootOffset;0;0;Create;True;0;0;False;0;0.28;0.546;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.DynamicAppendNode;155;2987.188,514.4867;Inherit;True;FLOAT3;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.WorldSpaceCameraPos;185;3667.112,-16.23999;Inherit;False;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.WorldPosInputsNode;183;3709.112,-167.24;Inherit;False;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.RangedFloatNode;162;2038.596,-127.3323;Inherit;True;Global;FresnelScale;FresnelScale;1;0;Create;True;0;0;False;0;0;15;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;168;3941.805,42.33926;Inherit;False;Global;DistanceFade;DistanceFade;2;0;Create;True;0;0;False;0;0;90;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.DistanceOpNode;184;3943.112,-176.24;Inherit;True;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleSubtractOpNode;62;538.5957,-234.288;Inherit;True;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;90;3075.571,157.262;Inherit;True;2;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.ColorNode;1;666.1634,-624.8256;Inherit;False;Global;BaseColor;BaseColor;0;0;Create;True;0;0;False;0;1,0.4558451,0.4,1;0,1,0,1;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.ColorNode;60;392.5957,-458.288;Inherit;False;Global;RootColor;RootColor;0;0;Create;True;0;0;False;0;1,0.4558451,0.4,1;0.6431373,0.4862745,0.282353,1;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleDivideOpNode;186;4220.112,-165.24;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.FresnelNode;160;2281.832,-201.7833;Inherit;True;Standard;WorldNormal;ViewDir;False;False;5;0;FLOAT3;0,0,1;False;4;FLOAT3;0,0,0;False;1;FLOAT;0;False;2;FLOAT;1;False;3;FLOAT;5;False;1;FLOAT;0
Node;AmplifyShaderEditor.LerpOp;59;2644.855,-620.583;Inherit;False;3;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;2;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.TransformPositionNode;55;3315.406,150.1514;Inherit;False;World;Object;False;Fast;True;1;0;FLOAT3;0,0,0;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.PosVertexDataNode;57;3330.111,356.1302;Inherit;False;0;0;5;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.ColorNode;159;2206.25,-375.524;Inherit;False;Global;FresnelColor;FresnelColor;1;0;Create;True;0;0;False;0;0,0,0,0;0.9528302,0,0,0;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RangedFloatNode;175;4051.653,135.4939;Inherit;False;Global;CameraPosW;CameraPosW;2;0;Create;True;0;0;False;0;0;34.9;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.LerpOp;182;2985.22,-461.7298;Inherit;False;3;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;2;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleSubtractOpNode;56;3584.797,161.3107;Inherit;False;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.TangentVertexDataNode;154;2348.425,971.3293;Inherit;False;0;0;5;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RangedFloatNode;58;1324.61,-246.2104;Inherit;False;Constant;_Float0;Float 0;5;0;Create;True;0;0;False;0;0;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;22;2844.514,-66.98631;Inherit;False;Global;Smoothness;Smoothness;2;0;Create;True;0;0;False;0;0.5;0.26;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.OneMinusNode;187;4451.456,-217.3954;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.StandardSurfaceOutputNode;0;4829.281,-530.1584;Float;False;True;-1;2;ASEMaterialInspector;0;0;Standard;Hidden/TerrainEngine/Details/WavingDoublePass;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;Off;0;False;-1;0;False;-1;False;0;False;-1;0;False;-1;False;0;Custom;0.5;True;True;0;False;Opaque;;Geometry;All;14;all;True;True;True;True;0;False;-1;False;0;False;-1;255;False;-1;255;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;False;2;15;10;25;False;0.5;True;0;0;False;-1;0;False;-1;0;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;0;0,0,0,0;VertexOffset;True;False;Cylindrical;False;Relative;0;;0;-1;-1;-1;0;False;0;0;False;-1;-1;0;False;-1;0;0;0;False;0.1;False;-1;0;False;-1;16;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;2;FLOAT3;0,0,0;False;3;FLOAT;0;False;4;FLOAT;0;False;5;FLOAT;0;False;6;FLOAT3;0,0,0;False;7;FLOAT3;0,0,0;False;8;FLOAT;0;False;9;FLOAT;0;False;10;FLOAT;0;False;13;FLOAT3;0,0,0;False;11;FLOAT3;0,0,0;False;12;FLOAT3;0,0,0;False;14;FLOAT4;0,0,0,0;False;15;FLOAT3;0,0,0;False;0
WireConnection;42;0;38;0
WireConnection;39;0;43;0
WireConnection;45;0;44;0
WireConnection;24;0;23;0
WireConnection;40;0;39;0
WireConnection;30;0;29;2
WireConnection;30;1;40;0
WireConnection;27;0;24;0
WireConnection;27;1;45;0
WireConnection;28;0;27;0
WireConnection;28;1;30;0
WireConnection;32;1;28;0
WireConnection;51;0;50;0
WireConnection;34;0;32;1
WireConnection;34;1;37;0
WireConnection;34;2;35;0
WireConnection;68;0;32;1
WireConnection;68;1;37;0
WireConnection;68;2;76;0
WireConnection;75;0;68;0
WireConnection;71;0;70;0
WireConnection;33;0;34;0
WireConnection;48;0;47;0
WireConnection;73;0;75;0
WireConnection;73;1;71;0
WireConnection;73;2;72;0
WireConnection;73;3;53;2
WireConnection;46;0;33;0
WireConnection;46;1;48;0
WireConnection;46;2;52;0
WireConnection;46;3;53;2
WireConnection;49;0;23;1
WireConnection;49;1;46;0
WireConnection;102;0;78;0
WireConnection;77;0;23;3
WireConnection;77;1;73;0
WireConnection;54;0;49;0
WireConnection;54;1;23;2
WireConnection;54;2;77;0
WireConnection;104;0;85;0
WireConnection;140;0;141;0
WireConnection;139;0;54;0
WireConnection;137;0;139;0
WireConnection;137;1;140;0
WireConnection;148;0;54;0
WireConnection;148;1;141;0
WireConnection;142;0;143;0
WireConnection;142;1;137;0
WireConnection;149;0;148;0
WireConnection;144;0;143;0
WireConnection;144;1;142;0
WireConnection;106;0;88;0
WireConnection;146;0;143;0
WireConnection;146;1;147;0
WireConnection;145;0;144;0
WireConnection;145;1;146;0
WireConnection;150;0;149;0
WireConnection;151;0;145;0
WireConnection;151;1;150;0
WireConnection;151;2;152;0
WireConnection;151;3;153;2
WireConnection;158;0;151;0
WireConnection;157;0;151;0
WireConnection;155;0;157;0
WireConnection;155;2;158;0
WireConnection;184;0;183;0
WireConnection;184;1;185;0
WireConnection;62;0;63;0
WireConnection;62;1;61;2
WireConnection;90;0;54;0
WireConnection;90;1;155;0
WireConnection;186;0;184;0
WireConnection;186;1;168;0
WireConnection;160;3;162;0
WireConnection;59;0;1;0
WireConnection;59;1;60;0
WireConnection;59;2;62;0
WireConnection;55;0;90;0
WireConnection;182;0;59;0
WireConnection;182;1;159;0
WireConnection;182;2;160;0
WireConnection;56;0;55;0
WireConnection;56;1;57;0
WireConnection;187;0;186;0
WireConnection;0;0;182;0
WireConnection;0;3;58;0
WireConnection;0;4;22;0
WireConnection;0;10;187;0
WireConnection;0;11;56;0
ASEEND*/
//CHKSM=D12FF4DC33BD9889BA4D8AEA104FE8A79890203A