Shader "SSS/Samples/SSS Deferred" {
	Properties {
		_Color ("Color", Color) = (1,1,1,1)
		_MainTex ("Albedo (RGB)", 2D) = "white" {}
		_Glossiness ("Smoothness", Range(0,1)) = 0.5
		_SpecColor("Specular Color", Color) = (0.2,0.2,0.2)
		[NoScaleOffset] _SpecGlossMap("Specular", 2D) = "white" {}

		[NoScaleOffset]_ProfileTex ("Profile", 2D) = "white" {}
		_ProfileColor("Profile Color", Color) = (1.0,1.0,1.0)
        [NoScaleOffset] _OcclusionMap("Occlusion", 2D) = "white" {}
        [NoScaleOffset] _OcclusionStrength("_OcclusionStrength", Range(0,1)) = 1
		[NoScaleOffset]_BumpMap("Normal Map", 2D) = "bump" {}
        [hideininspector]SSS_shader("", float)=1
	}
	SubShader {
		//Tags { "RenderType"="SSS" }
		Tags { "RenderType"="Opaque" "Queue" = "Geometry+0"}
		LOD 200

		CGPROGRAM
		// Physically based Standard lighting model, and enable shadows on all light types
		#pragma surface surf StandardSpecular fullforwardshadows
		#pragma multi_compile _ SCENE_VIEW
        #include "../Resources/SSS_Common.hlsl"

		// Use shader model 3.0 target, to get nicer looking lighting
		#pragma target 3.0

		struct Input {
			float2 uv_MainTex;
			float4 screenPos;
		};

		

	

		// Add instancing support for this shader. You need to check 'Enable Instancing' on materials that use the shader.
		// See https://docs.unity3d.com/Manual/GPUInstancing.html for more information about instancing.
		// #pragma instancing_options assumeuniformscaling
		UNITY_INSTANCING_BUFFER_START(Props)
			// put more per-instance properties here
		UNITY_INSTANCING_BUFFER_END(Props)

		void surf (Input IN, inout SurfaceOutputStandardSpecular o) {
			// Albedo comes from a texture tinted by color
			half2 uv = IN.uv_MainTex;
			fixed4 Albedo = tex2D (_MainTex, IN.uv_MainTex);
            o.Normal = UnpackNormal(tex2D(_BumpMap, uv));
			o.Occlusion = lerp(1.0, tex2D(_OcclusionMap, uv).r, _OcclusionStrength);
			#ifdef SCENE_VIEW
			o.Albedo = Albedo * o.Occlusion * _Color;
            #else
            o.Albedo = 0;
            #endif
			// Metallic and smoothness come from slider variables
            float4 Specular = float4(_SpecColor.rgb, _Glossiness) * tex2D(_SpecGlossMap, uv);

			o.Specular = Specular.rgb;
			o.Smoothness = Specular.a;
			o.Alpha = Albedo.a;

			//Convolved buffer
             #if !defined(SCENE_VIEW)
            half3 LightingPass = 0;
            float4 coords = 0;
			coords = UNITY_PROJ_COORD(IN.screenPos);
            coords.w += .0001;
			float2 screenUV = coords.xy / coords.w;
            
               #ifdef UNITY_SINGLE_PASS_STEREO
				float4 scaleOffset = unity_StereoScaleOffset[unity_StereoEyeIndex];
			    screenUV = (screenUV - scaleOffset.zw) / scaleOffset.xy;
               #endif
            if (unity_StereoEyeIndex == 0)
                LightingPass = tex2D(LightingTexBlurred, screenUV).rgb;
            else
                LightingPass = tex2D(LightingTexBlurredR, screenUV).rgb;

            o.Emission = Albedo * LightingPass;
            #endif
		}
		ENDCG
	}
	FallBack "Diffuse"
	

}
