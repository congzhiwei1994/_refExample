// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Hidden/LightingPass"
{
	Properties
	{
		_Color ("Main Color", Color) = (1,1,1,1)
		_MainTex ("Base (RGB)", 2D) = "white" {}
		_Cutoff("Mask Clip Value", Float) = 0.5
		[HideInInspector] __dirty("", Int) = 1

	}

	//SSS pass
	SubShader
	{
	//Tags { "RenderType" = "SSS" }
	Tags { "RenderType" = "Opaque" }
	LOD 100
	
	CGPROGRAM
	//SSS_LightingPass
	#pragma surface surf SSS_LightingPass vertex:vert fullforwardshadows nodynlightmap nodirlightmap nofog
	#pragma target 3.0
	#include "SSS_Common.hlsl"
	#pragma multi_compile _ TRANSMISSION
	#pragma multi_compile _ SUBSURFACE_ALBEDO
	#pragma multi_compile _ ENABLE_DETAIL_NORMALMAP
	#pragma multi_compile _ ENABLE_ALPHA_TEST
	#pragma multi_compile _ ENABLE_PARALLAX
	#pragma multi_compile _ WRAPPED_LIGHTING
	#pragma multi_compile _ PUPIL_DILATION


	half _Cutoff, IsWater;

	struct Input 
	{
		float2 uv_MainTex;
        float3 worldNormal;
		float4 screenPos;
		float3 viewDir;

        INTERNAL_DATA
	};

	struct DataStructure
    {
	    fixed3 Albedo;  // diffuse color
	    fixed3 Normal;  // tangent space normal, if written
	    fixed3 Emission;
	    fixed Alpha;
        fixed3 Occlusion;
        fixed Glossiness;
	    fixed3 Transmission;
		fixed2 screenUV;
    };

	void vert(inout appdata_full v, out Input o)
	{
	UNITY_INITIALIZE_OUTPUT(Input, o);	
	//experimental
	//v.vertex.xyz += v.normal * .0001;
	
	}
	half4 LightingSSS_LightingPass(DataStructure s, half3 lightDir, half3 viewDir, half atten)
	{
	#if defined (__INTELLISENSE__)
	#define TRANSMISSION
	#endif

	half NdotL = max(0.0, dot(lightDir, s.Normal));

	half3 Lighting = atten * _LightColor0.rgb;

	half3 Diffuse = Lighting * DiffuseLightingModel(NdotL) * s.Albedo;
        
	//return float4(Lighting, atten);
	#ifdef TRANSMISSION
	Diffuse += ADDITIVE_PASS_TRANSMISSION
	#endif
	//return saturate (dot(normalize(viewDir), normalize(-lightDir)));
	return float4(Diffuse, 1);
			
	}

	// Add instancing support for this shader. You need to check 'Enable Instancing' on materials that use the shader.
		// See https://docs.unity3d.com/Manual/GPUInstancing.html for more information about instancing.
		// #pragma instancing_options assumeuniformscaling
		UNITY_INSTANCING_BUFFER_START(Props)
			// put more per-instance properties here
		UNITY_INSTANCING_BUFFER_END(Props)

	void surf (Input IN, inout DataStructure o) 
	{
	//if (SSS_shader != 1)discard;
	#if defined (__INTELLISENSE__)
	#define TRANSMISSION
	#endif

	half2 uv = IN.uv_MainTex;
	
	#ifdef ENABLE_PARALLAX
	COMPUTE_PARALLAX			
	#endif			

	#ifdef PUPIL_DILATION		
		COMPUTE_EYE_DILATION
	#endif

	SSS_OCCLUSION

	#ifdef SUBSURFACE_ALBEDO
	//To be correct (PB) this should be multiplied by 1 - specular
	_Color.rgb *= lerp(1.0, tex2D(_SubsurfaceAlbedo, uv * _AlbedoTile).rgb, _SubsurfaceAlbedoOpacity);
	#endif
	float3 MainTex = 0, Final = 0;
	if (SSS_shader != 1)
	//Final = tex2D(_MainTex, IN.uv_MainTex).xyz;
	//Final = 0.5;
	Final = 0;
	else
	Final = _Color .rgb * OcclusionColored.rgb;
	
	#ifdef ENABLE_ALPHA_TEST
	clip(tex2D(_MainTex, IN.uv_MainTex).a - _Cutoff);
	#endif

	o.Albedo =  Final;
	o.Alpha = 1;

	[branch]
	if(IsWater == 0)
		o.Normal = BumpMap(uv);
	else
		o.Normal = float3(0, 0, 1);
		
	float3 Emission = 0;
	#ifdef TRANSMISSION
	BASE_TRANSMISSION
	#endif
	o.Emission = Emission;
	float4 coords = UNITY_PROJ_COORD(IN.screenPos);
	coords.w += 1e-9f;
	float2 screenUV = coords.xy / coords.w;
	o.screenUV = screenUV;
	}
	ENDCG


	}
	
	//Opaque pass
	SubShader
	{
		Tags{ "RenderType" = "Opaque" }
	Pass 
	{
		Name "ShadowCaster"
		Tags { "LightMode" = "ShadowCaster" }

		Fog {Mode Off}

		Offset 1, 1

		CGPROGRAM
		#pragma vertex vert
		#pragma fragment frag
		#pragma multi_compile_shadowcaster
		#include "UnityCG.cginc"

		struct v2f {
			V2F_SHADOW_CASTER;
		};

		v2f vert(appdata_base v)
		{
			v2f o;
			TRANSFER_SHADOW_CASTER(o)
			TRANSFER_SHADOW_CASTER_NORMALOFFSET(o)

			return o;
		}

		float4 frag(v2f i) : SV_Target
		{
			SHADOW_CASTER_FRAGMENT(i)
		}
		ENDCG

		}
	}
	/*
	//Cutout pass
	SubShader
	{
		Tags{ "RenderType" = "TransparentCutout" "LightMode" = "ShadowCaster"}

		CGPROGRAM
		#pragma target 3.0
		#pragma surface surf Unlit  addshadow fullforwardshadows noshadow noambient novertexlights nolightmap  nodynlightmap nodirlightmap nofog nometa noforwardadd 


		sampler2D _MainTex;
		fixed4 _Color;

		struct Input 
		{
			float2 uv_MainTex;
		};
		uniform float _Cutoff = 0.94;
		inline half4 LightingUnlit(SurfaceOutput s, half3 lightDir, half atten)
		{
			return half4 (0, 0, 0, s.Alpha);
		}
		void surf(Input i , inout SurfaceOutput o)
		{
			fixed4 c = tex2D(_MainTex, i.uv_MainTex) * _Color;
			o.Albedo = 0;
			o.Alpha = c.a;
			clip(c.a - _Cutoff);
		}

		ENDCG
		
		}
		*/

//Cutout shadow pass
SubShader
{
	Tags{ "RenderType" = "TransparentCutout"}


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

		#include "UnityCG.cginc"
		#include "Lighting.cginc"
		#include "UnityPBSLighting.cginc"
	
		float _Cutoff;
		struct v2f
		{
			V2F_SHADOW_CASTER;
			float2 customPack1 : TEXCOORD1;

			UNITY_VERTEX_INPUT_INSTANCE_ID
		};
		struct Input
		{
		float2 uv_MainTex;

		};

		v2f vert(appdata_full v)
		{
			v2f o;
			UNITY_SETUP_INSTANCE_ID(v);
			UNITY_INITIALIZE_OUTPUT(v2f, o);
			UNITY_TRANSFER_INSTANCE_ID(v, o);
			Input customInputData;
			o.customPack1.xy = customInputData.uv_MainTex;
			o.customPack1.xy = v.texcoord;

			TRANSFER_SHADOW_CASTER_NORMALOFFSET(o)
			return o;
		}

		sampler2D _MainTex;
		uniform float4 _MainTex_ST;
		fixed4 _Color;
		
		void surf(Input i , inout SurfaceOutputStandard o)
		{
		fixed4 c = tex2D(_MainTex, i.uv_MainTex* _MainTex_ST.xy + _MainTex_ST.zw) * _Color;
		o.Albedo = c.rgb;
		o.Alpha = c.a;
			clip(o.Alpha - _Cutoff);

		}

		half4 frag(v2f IN) : SV_Target
		{
			UNITY_SETUP_INSTANCE_ID(IN);
			Input surfIN;
			UNITY_INITIALIZE_OUTPUT(Input, surfIN);
			surfIN.uv_MainTex = IN.customPack1.xy;
			
			SurfaceOutputStandard o;
			UNITY_INITIALIZE_OUTPUT(SurfaceOutputStandard, o)
			surf(surfIN, o);
			
			clip(o.Alpha - _Cutoff);
			SHADOW_CASTER_FRAGMENT(IN)
		}
		ENDCG

		}
	}
	//Transparent Shadows pass
	SubShader
{
	Tags{ "RenderType" = "Transparent" }


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
		sampler3D _DitherMaskLOD;
		struct v2f
		{
			V2F_SHADOW_CASTER;
			float2 customPack1 : TEXCOORD1;
			float3 worldPos : TEXCOORD2;
			UNITY_VERTEX_INPUT_INSTANCE_ID
		};
		struct Input
		{
		float2 uv_MainTex;

		};

		v2f vert(appdata_full v)
		{
			v2f o;
			UNITY_SETUP_INSTANCE_ID(v);
			UNITY_INITIALIZE_OUTPUT(v2f, o);
			UNITY_TRANSFER_INSTANCE_ID(v, o);
			Input customInputData;
			float3 worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
			half3 worldNormal = UnityObjectToWorldNormal(v.normal);
			o.customPack1.xy = customInputData.uv_MainTex;
			o.customPack1.xy = v.texcoord;
			o.worldPos = worldPos;
			TRANSFER_SHADOW_CASTER_NORMALOFFSET(o)
			return o;
		}

		sampler2D _MainTex;
		uniform float4 _MainTex_ST;
		fixed4 _Color;
		
		void surf(Input i , inout SurfaceOutputStandard o)
		{
		fixed4 c = tex2D(_MainTex, i.uv_MainTex* _MainTex_ST.xy + _MainTex_ST.zw) * _Color;
		o.Albedo = c.rgb;
		o.Alpha = c.a;

		}

		half4 frag(v2f IN
		#if !defined( CAN_SKIP_VPOS )
		, UNITY_VPOS_TYPE vpos : VPOS
		#endif
		) : SV_Target
		{
			UNITY_SETUP_INSTANCE_ID(IN);
			Input surfIN;
			UNITY_INITIALIZE_OUTPUT(Input, surfIN);
			surfIN.uv_MainTex = IN.customPack1.xy;
			float3 worldPos = IN.worldPos;
			half3 worldViewDir = normalize(UnityWorldSpaceViewDir(worldPos));
			SurfaceOutputStandard o;
			UNITY_INITIALIZE_OUTPUT(SurfaceOutputStandard, o)
			surf(surfIN, o);
			#if defined( CAN_SKIP_VPOS )
			float2 vpos = IN.pos;
			#endif
			half alphaRef = tex3D(_DitherMaskLOD, float3(vpos.xy * 0.25, o.Alpha * 0.9375)).a;
			clip(alphaRef - 0.01);
			SHADOW_CASTER_FRAGMENT(IN)
		}
		ENDCG
	}
}

Fallback "Legacy Shaders/Diffuse"

	
}
