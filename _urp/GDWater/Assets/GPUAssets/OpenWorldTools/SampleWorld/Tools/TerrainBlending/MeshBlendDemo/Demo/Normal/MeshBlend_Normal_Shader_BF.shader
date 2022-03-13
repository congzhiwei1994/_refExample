// Made with Amplify Shader Editor
// Available at the Unity Asset Store - http://u3d.as/y3X 
Shader "Cl/Demo/MeshBlend_Normal_BF"
{
	Properties
	{
		_Albedo("Albedo", Color) = (0.4980392,0.4980392,0.4980392,0.003921569)
		_GlobalWN("GlobalWN", 2D) = "white" {}
		_GlobalDis("GlobalDis", 2D) = "white" {}
		_GlobalDisScale("GlobalDisScale", Float) = 1
		_Smoothness("Smoothness", Range( 0 , 1)) = 0
		_Metallic("Metallic", Range( 0 , 1)) = 0
		_GlobalDisY("GlobalDisY", Float) = 1
		_BlendThickness("BlendThickness", Float) = 0
		_TerrainPos("TerrainPos", Vector) = (0,0,0,0)
		_TerrainSize("TerrainSize", Vector) = (0,0,0,0)
		[Toggle(_BLENDNORMALTYPE_ON)] _BlendNormalType("BlendNormalType", Float) = 0
		[Toggle(_OPENBLEND_ON)] _OpenBlend("OpenBlend", Float) = 0
		_BlendNor("BlendNor", 2D) = "bump" {}
		_BlendNormal("BlendNormal", Range( 0 , 10)) = 0
		_TerrainAlbedo("TerrainAlbedo", 2D) = "white" {}
		[HideInInspector] _texcoord( "", 2D ) = "white" {}
		[HideInInspector] __dirty( "", Int ) = 1
	}

	SubShader
	{
		Tags{ "RenderType" = "Opaque"  "Queue" = "Geometry+0" }
		Cull Back
		CGINCLUDE
		#include "UnityStandardUtils.cginc"
		#include "UnityPBSLighting.cginc"
		#include "Lighting.cginc"
		#pragma target 3.0
		#pragma shader_feature _OPENBLEND_ON
		#pragma shader_feature _BLENDNORMALTYPE_ON
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
			float3 worldNormal;
			INTERNAL_DATA
			float3 worldPos;
			float2 uv_texcoord;
		};

		uniform sampler2D _GlobalWN;
		uniform float2 _TerrainPos;
		uniform float2 _TerrainSize;
		uniform sampler2D _GlobalDis;
		uniform float _GlobalDisScale;
		uniform float _GlobalDisY;
		uniform float _BlendThickness;
		uniform float _BlendNormal;
		uniform sampler2D _BlendNor;
		uniform sampler2D _TerrainAlbedo;
		uniform float4 _TerrainAlbedo_ST;
		uniform float4 _Albedo;
		uniform float _Metallic;
		uniform float _Smoothness;

		void surf( Input i , inout SurfaceOutputStandard o )
		{
			float3 ase_worldNormal = WorldNormalVector( i, float3( 0, 0, 1 ) );
			float3 ase_worldTangent = WorldNormalVector( i, float3( 1, 0, 0 ) );
			float3 ase_worldBitangent = WorldNormalVector( i, float3( 0, 1, 0 ) );
			float3x3 ase_worldToTangent = float3x3( ase_worldTangent, ase_worldBitangent, ase_worldNormal );
			float3 ase_normWorldNormal = normalize( ase_worldNormal );
			float3 temp_output_66_0 = mul( ase_worldToTangent, ase_normWorldNormal );
			float3 ase_worldPos = i.worldPos;
			float2 appendResult2 = (float2(ase_worldPos.x , ase_worldPos.z));
			float2 appendResult3 = (float2(_TerrainPos.x , _TerrainPos.y));
			float2 temp_output_7_0 = ( ( appendResult2 - appendResult3 ) / _TerrainSize );
			float4 temp_cast_1 = (0.5).xxxx;
			float4 temp_output_17_0 = float4( mul( ase_worldToTangent, ( ( tex2D( _GlobalWN, temp_output_7_0 ) - temp_cast_1 ) * 2.0 ).rgb ) , 0.0 );
			float clampResult31 = clamp( ( ( ( ase_worldPos.y - ( tex2D( _GlobalDis, temp_output_7_0 ).r * _GlobalDisScale ) ) - ( _GlobalDisY - _GlobalDisScale ) ) / _BlendThickness ) , 0.0 , 1.0 );
			float4 lerpResult18 = lerp( temp_output_17_0 , float4( temp_output_66_0 , 0.0 ) , clampResult31);
			float4 temp_cast_5 = (0.5).xxxx;
			float3 lerpResult72 = lerp( BlendNormals( temp_output_17_0.rgb , UnpackScaleNormal( tex2D( _BlendNor, temp_output_7_0 ), _BlendNormal ) ) , temp_output_66_0 , clampResult31);
			#ifdef _BLENDNORMALTYPE_ON
				float4 staticSwitch73 = float4( lerpResult72 , 0.0 );
			#else
				float4 staticSwitch73 = lerpResult18;
			#endif
			#ifdef _OPENBLEND_ON
				float4 staticSwitch57 = staticSwitch73;
			#else
				float4 staticSwitch57 = float4( temp_output_66_0 , 0.0 );
			#endif
			o.Normal = staticSwitch57.rgb;
			float2 uv_TerrainAlbedo = i.uv_texcoord * _TerrainAlbedo_ST.xy + _TerrainAlbedo_ST.zw;
			float4 temp_output_58_0 = ( tex2D( _TerrainAlbedo, uv_TerrainAlbedo ) * _Albedo );
			float4 lerpResult74 = lerp( ( _Albedo * tex2D( _TerrainAlbedo, temp_output_7_0 ) ) , temp_output_58_0 , clampResult31);
			#ifdef _BLENDNORMALTYPE_ON
				float4 staticSwitch80 = lerpResult74;
			#else
				float4 staticSwitch80 = temp_output_58_0;
			#endif
			o.Albedo = staticSwitch80.rgb;
			o.Metallic = _Metallic;
			o.Smoothness = _Smoothness;
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
1920;682;905;460;-116.1112;-271.2795;2.110335;True;False
Node;AmplifyShaderEditor.Vector2Node;44;-1167.845,404.6642;Inherit;False;Property;_TerrainPos;TerrainPos;8;0;Create;True;0;0;False;0;0,0;0,0;0;3;FLOAT2;0;FLOAT;1;FLOAT;2
Node;AmplifyShaderEditor.WorldPosInputsNode;1;-1240.653,38.14693;Inherit;False;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.DynamicAppendNode;3;-917.0627,253.0582;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.DynamicAppendNode;2;-979.0627,68.05821;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.Vector2Node;45;-715.3055,320.8949;Inherit;False;Property;_TerrainSize;TerrainSize;9;0;Create;True;0;0;False;0;0,0;20,20;0;3;FLOAT2;0;FLOAT;1;FLOAT;2
Node;AmplifyShaderEditor.SimpleSubtractOpNode;6;-635.023,36.13666;Inherit;True;2;0;FLOAT2;0,0;False;1;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleDivideOpNode;7;-495.3168,348.4573;Inherit;True;2;0;FLOAT2;0,0;False;1;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RangedFloatNode;23;22.53247,668.455;Inherit;False;Property;_GlobalDisScale;GlobalDisScale;3;0;Create;True;0;0;False;0;1;-0.65;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SamplerNode;20;-114.2292,446.7458;Inherit;True;Property;_GlobalDis;GlobalDis;2;0;Create;True;0;0;False;0;-1;None;e60b263c3aa73834bb81716d464e5ac5;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;6;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SamplerNode;11;-182.8221,-5.912941;Inherit;True;Property;_GlobalWN;GlobalWN;1;0;Create;True;0;0;False;0;-1;None;dc2b38b7405c1d043b9e787c085eacb3;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;6;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RangedFloatNode;25;20.53247,818.455;Inherit;False;Property;_GlobalDisY;GlobalDisY;6;0;Create;True;0;0;False;0;1;0.45;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;13;141.5547,72.98187;Inherit;False;Constant;_Float1;Float 1;0;0;Create;True;0;0;False;0;0.5;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;21;294.2119,656.5433;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleSubtractOpNode;12;299.4709,-1.842267;Inherit;False;2;0;COLOR;0,0,0,0;False;1;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleSubtractOpNode;24;380.3082,826.322;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleSubtractOpNode;26;546.2789,447.2617;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;15;269.2234,128.8361;Inherit;False;Constant;_Float2;Float 2;0;0;Create;True;0;0;False;0;2;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.WorldToTangentMatrix;16;530.5298,-25.81747;Inherit;False;0;1;FLOAT3x3;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;14;482.2233,111.8361;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.RangedFloatNode;71;804.9991,338.3266;Inherit;False;Property;_BlendNormal;BlendNormal;13;0;Create;True;0;0;False;0;0;1;0;10;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;30;915.5197,915.0641;Inherit;False;Property;_BlendThickness;BlendThickness;7;0;Create;True;0;0;False;0;0;0.6;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleSubtractOpNode;27;937.2949,798.1081;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SamplerNode;68;1095.06,254.1407;Inherit;True;Property;_BlendNor;BlendNor;12;0;Create;True;0;0;False;0;-1;None;f53512d44b91e954dae7bf028209df1a;True;0;True;bump;Auto;True;Object;-1;Auto;Texture2D;6;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;5;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.WorldNormalVector;64;1055.817,-182.7763;Inherit;False;True;1;0;FLOAT3;0,0,1;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;17;805.1724,-29.60548;Inherit;True;2;2;0;FLOAT3x3;0,0,0,1,1,1,1,0,1;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.TexturePropertyNode;76;1604.078,-535.2115;Inherit;True;Property;_TerrainAlbedo;TerrainAlbedo;14;0;Create;True;0;0;False;0;None;662d72b6ec210cf4cbeec2b4d3cb8b2a;False;white;Auto;Texture2D;-1;0;1;SAMPLER2D;0
Node;AmplifyShaderEditor.WorldToTangentMatrix;65;1051.368,-269.7859;Inherit;False;0;1;FLOAT3x3;0
Node;AmplifyShaderEditor.SimpleDivideOpNode;29;1227.879,870.7969;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.BlendNormalsNode;67;1430.34,226.0958;Inherit;True;0;3;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;2;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;66;1334.732,-280.574;Inherit;True;2;2;0;FLOAT3x3;0,0,0,1,1,1,1,0,1;False;1;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.ClampOpNode;31;1722.368,874.5346;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.ColorNode;34;2033.302,-620.6509;Inherit;False;Property;_Albedo;Albedo;0;0;Create;True;0;0;False;0;0.4980392,0.4980392,0.4980392,0.003921569;1,1,1,1;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SamplerNode;78;1981.601,-374.172;Inherit;True;Property;_TextureSample0;Texture Sample 0;10;0;Create;True;0;0;False;0;-1;None;662d72b6ec210cf4cbeec2b4d3cb8b2a;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;6;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SamplerNode;54;2003.849,-834.0972;Inherit;True;Property;_TerrainAlbedo1;TerrainAlbedo1;10;0;Create;True;0;0;False;0;-1;None;662d72b6ec210cf4cbeec2b4d3cb8b2a;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;6;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.LerpOp;18;1970.892,-55.06613;Inherit;False;3;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;2;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.LerpOp;72;1769.756,139.981;Inherit;False;3;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;2;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;79;2424.008,-451.69;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;58;2393.228,-729.4471;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.StaticSwitch;73;2229.024,-40.87519;Inherit;False;Property;_BlendNormalType;BlendNormalType;10;0;Create;True;0;0;False;0;0;0;0;True;;Toggle;2;Key0;Key1;Create;False;9;1;COLOR;0,0,0,0;False;0;COLOR;0,0,0,0;False;2;COLOR;0,0,0,0;False;3;COLOR;0,0,0,0;False;4;COLOR;0,0,0,0;False;5;COLOR;0,0,0,0;False;6;COLOR;0,0,0,0;False;7;COLOR;0,0,0,0;False;8;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.LerpOp;74;2738.823,-395.2487;Inherit;False;3;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;2;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.RangedFloatNode;33;2713.843,311.7562;Inherit;False;Property;_Smoothness;Smoothness;4;0;Create;True;0;0;False;0;0;0.7;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;36;3304.621,503.6287;Inherit;False;35;Debug;1;0;OBJECT;;False;1;COLOR;0
Node;AmplifyShaderEditor.RangedFloatNode;32;2711.15,184.5977;Inherit;False;Property;_Metallic;Metallic;5;0;Create;True;0;0;False;0;0;0;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;35;2374.771,202.3745;Inherit;False;Debug;-1;True;1;0;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.StaticSwitch;80;2953.495,-444.2738;Inherit;False;Property;_BlendNormalType;BlendNormalType;10;0;Create;True;0;0;False;0;0;0;0;True;;Toggle;2;Key0;Key1;Reference;73;False;9;1;COLOR;0,0,0,0;False;0;COLOR;0,0,0,0;False;2;COLOR;0,0,0,0;False;3;COLOR;0,0,0,0;False;4;COLOR;0,0,0,0;False;5;COLOR;0,0,0,0;False;6;COLOR;0,0,0,0;False;7;COLOR;0,0,0,0;False;8;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.StaticSwitch;57;2557.296,-90.94534;Inherit;False;Property;_OpenBlend;OpenBlend;11;0;Create;True;0;0;False;0;0;0;1;True;;Toggle;2;Key0;Key1;Create;False;9;1;COLOR;0,0,0,0;False;0;COLOR;0,0,0,0;False;2;COLOR;0,0,0,0;False;3;COLOR;0,0,0,0;False;4;COLOR;0,0,0,0;False;5;COLOR;0,0,0,0;False;6;COLOR;0,0,0,0;False;7;COLOR;0,0,0,0;False;8;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.StandardSurfaceOutputNode;0;3338.322,4.74652;Float;False;True;-1;2;ASEMaterialInspector;0;0;Standard;Cl/Demo/MeshBlend_Normal_BF;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;Back;0;False;-1;0;False;-1;False;0;False;-1;0;False;-1;False;0;Opaque;0.5;True;True;0;False;Opaque;;Geometry;All;14;all;True;True;True;True;0;False;-1;False;0;False;-1;255;False;-1;255;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;False;2;15;10;25;False;0.5;True;0;0;False;-1;0;False;-1;0;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;0;0,0,0,0;VertexOffset;True;False;Cylindrical;False;Relative;0;;-1;-1;-1;-1;0;False;0;0;False;-1;-1;0;False;-1;0;0;0;False;0.1;False;-1;0;False;-1;16;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;2;FLOAT3;0,0,0;False;3;FLOAT;0;False;4;FLOAT;0;False;5;FLOAT;0;False;6;FLOAT3;0,0,0;False;7;FLOAT3;0,0,0;False;8;FLOAT;0;False;9;FLOAT;0;False;10;FLOAT;0;False;13;FLOAT3;0,0,0;False;11;FLOAT3;0,0,0;False;12;FLOAT3;0,0,0;False;14;FLOAT4;0,0,0,0;False;15;FLOAT3;0,0,0;False;0
WireConnection;3;0;44;1
WireConnection;3;1;44;2
WireConnection;2;0;1;1
WireConnection;2;1;1;3
WireConnection;6;0;2;0
WireConnection;6;1;3;0
WireConnection;7;0;6;0
WireConnection;7;1;45;0
WireConnection;20;1;7;0
WireConnection;11;1;7;0
WireConnection;21;0;20;1
WireConnection;21;1;23;0
WireConnection;12;0;11;0
WireConnection;12;1;13;0
WireConnection;24;0;25;0
WireConnection;24;1;23;0
WireConnection;26;0;1;2
WireConnection;26;1;21;0
WireConnection;14;0;12;0
WireConnection;14;1;15;0
WireConnection;27;0;26;0
WireConnection;27;1;24;0
WireConnection;68;1;7;0
WireConnection;68;5;71;0
WireConnection;17;0;16;0
WireConnection;17;1;14;0
WireConnection;29;0;27;0
WireConnection;29;1;30;0
WireConnection;67;0;17;0
WireConnection;67;1;68;0
WireConnection;66;0;65;0
WireConnection;66;1;64;0
WireConnection;31;0;29;0
WireConnection;78;0;76;0
WireConnection;78;1;7;0
WireConnection;54;0;76;0
WireConnection;18;0;17;0
WireConnection;18;1;66;0
WireConnection;18;2;31;0
WireConnection;72;0;67;0
WireConnection;72;1;66;0
WireConnection;72;2;31;0
WireConnection;79;0;34;0
WireConnection;79;1;78;0
WireConnection;58;0;54;0
WireConnection;58;1;34;0
WireConnection;73;1;18;0
WireConnection;73;0;72;0
WireConnection;74;0;79;0
WireConnection;74;1;58;0
WireConnection;74;2;31;0
WireConnection;35;0;74;0
WireConnection;80;1;58;0
WireConnection;80;0;74;0
WireConnection;57;1;66;0
WireConnection;57;0;73;0
WireConnection;0;0;80;0
WireConnection;0;1;57;0
WireConnection;0;3;32;0
WireConnection;0;4;33;0
ASEEND*/
//CHKSM=2E58AAEE36FCEFA80D54A84742ABD96FEEF1560C