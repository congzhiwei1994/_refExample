Shader "Lux URP/FX/Sphere Volume"
{
	Properties
	{
		[HeaderHelpLuxURP_URL(t98mzd66fi0m)]

		[Header(Surface Options)]
        [Space(8)]
        [Enum(UnityEngine.Rendering.CompareFunction)]
        _ZTest                      ("ZTest", Int) = 8
        [Enum(UnityEngine.Rendering.CullMode)]
        _Cull                       ("Culling", Float) = 1
        [Toggle(ORTHO_SUPPORT)]
        _OrthoSpport                ("Enable Orthographic Support", Float) = 0

		[Header(Surface Inputs)]
        [Space(8)]
		_Color 						("Color", Color) = (1, 1, 1, 1)

		[Toggle(_ENABLEGRADIENT)]
		_EnableGradient 			("Enable Gradient", Float) = 0
		[NoScaleOffset]
		_MainTex 					("     Thickness Gradient", 2D) = "white" {}

		[Header(Thickness Remap)]
        [Space(8)]
        _Lower                      ("     Lower", Range(0,1)) = 0
        _Upper                      ("     Upper", Range(0,4)) = 1
        //[Space(5)]
		//_SoftEdge                   ("     Soft Edge Factor", Float) = 2.0

		[Space(5)]
		[Toggle(_APPLYFOG)]
		_ApplyFog 					("Enable Fog", Float) = 0.0
		[Toggle(_HQFOG)]
		_HQFog 						("     HQ Fog", Float) = 0.0


	}
	SubShader
	{
		
		Tags
        {
            "RenderPipeline" = "UniversalPipeline"
            "RenderType"="Opaque"
            "Queue"= "Transparent+50"
        }

		Pass
		{
			Name "StandardUnlit"
            Tags{"LightMode" = "UniversalForward"}
			Blend SrcAlpha OneMinusSrcAlpha
			
		//  As we want to be able to enter the volume we have to draw the back faces
			Cull [_Cull]
		//	We fully rely on the depth texture sample!
			ZTest [_ZTest]
			ZWrite Off
			ColorMask RGB

			HLSLPROGRAM
			// Required to compile gles 2.0 with standard srp library
            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x
            #pragma target 2.0

			#pragma shader_feature_local _ENABLEGRADIENT
			#pragma shader_feature_local _APPLYFOG
			#pragma shader_feature_local ORTHO_SUPPORT

			// -------------------------------------
            // Unity defined keywords
            #if defined(_APPLYFOG)
            	#pragma multi_compile_fog
            	#pragma shader_feature_local _HQFOG
            #endif

            //--------------------------------------
            // GPU Instancing
            #pragma multi_compile_instancing

			#pragma vertex vert
			#pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/Shaders/UnlitInput.hlsl"

            CBUFFER_START(UnityPerMaterial)
            	half4 _Color;
            	half _Lower;
            	half _Upper;
				//half _SoftEdge;
            CBUFFER_END

            // Stereo-related bits - backported to LWRP
            #if defined(UNITY_STEREO_INSTANCING_ENABLED) || defined(UNITY_STEREO_MULTIVIEW_ENABLED)
                #define LUX_SLICE_ARRAY_INDEX                                       unity_StereoEyeIndex
                #define LUX_TEXTURE2D_X                                             TEXTURE2D_ARRAY
                #define LUX_TEXTURE2D_X_FLOAT                                       TEXTURE2D_ARRAY_FLOAT
                #define LUX_LOAD_TEXTURE2D_X(textureName, unCoord2)                 LOAD_TEXTURE2D_ARRAY(textureName, unCoord2, LUX_SLICE_ARRAY_INDEX)
                #define LUX_SAMPLE_TEXTURE2D_X(textureName, samplerName, coord2)    SAMPLE_TEXTURE2D_ARRAY(textureName, samplerName, coord2, LUX_SLICE_ARRAY_INDEX)
            #else
                #define LUX_SLICE_ARRAY_INDEX                                       0
                #define LUX_TEXTURE2D_X                                             TEXTURE2D
                #define LUX_TEXTURE2D_X_FLOAT                                       TEXTURE2D_FLOAT
                #define LUX_LOAD_TEXTURE2D_X                                        LOAD_TEXTURE2D
                #define LUX_SAMPLE_TEXTURE2D_X                                      SAMPLE_TEXTURE2D
            #endif

            #if defined(_ENABLEGRADIENT)
            	TEXTURE2D(_MainTex); SAMPLER(sampler_MainTex);
            #endif
            #if defined(SHADER_API_GLES)
                TEXTURE2D(_CameraDepthTexture); SAMPLER(sampler_CameraDepthTexture);
            #else
                LUX_TEXTURE2D_X_FLOAT(_CameraDepthTexture);
            #endif
            float4 _CameraDepthTexture_TexelSize;
			
			struct VertexInput
            {
                float4 vertex : POSITION;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

			struct VertexOutput
			{
				float4 positionCS : SV_POSITION;
				float3 positionWS : TEXCOORD1;
				float2 projectedPosition : TEXCOORD2;
				float3 cameraPositionOS	: TEXCOORD4;
				float  scale : TEXCOORD5;

				#if defined(_APPLYFOG)
            		half fogCoord : TEXCOORD0;
            	#endif

				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};

			VertexOutput vert (VertexInput input)
			{
				VertexOutput o = (VertexOutput)0;
				UNITY_SETUP_INSTANCE_ID(input);
				UNITY_TRANSFER_INSTANCE_ID(input, o);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

				VertexPositionInputs vertexInput = GetVertexPositionInputs(input.vertex.xyz);
                o.positionCS = vertexInput.positionCS;
				o.positionWS = vertexInput.positionWS;
				o.projectedPosition = vertexInput.positionNDC.xy;
				o.cameraPositionOS	= mul(GetWorldToObjectMatrix(), float4(_WorldSpaceCameraPos, 1)).xyz;

				float4x4 ObjectToWorldMatrix = GetObjectToWorldMatrix();
				float3 worldScale = float3(
                    length(ObjectToWorldMatrix._m00_m10_m20), // scale x axis
                    length(ObjectToWorldMatrix._m01_m11_m21), // scale y axis
                    length(ObjectToWorldMatrix._m02_m12_m22)  // scale z axis
                );
                o.scale  = 1.0f / max(worldScale.x, max(worldScale.y, worldScale.z));

				#if defined(_APPLYFOG)
                    o.fogCoord = ComputeFogFactor(o.positionCS.z);
                #endif

				return o;
			}

		//	Ray-sphere intersection.
		//	Returns the distance to the first and second intersection.
			bool IntersectRaySphere (float3 rayStart, float3 rayDir, float3 sc, float radius, out float2 intersections)
			{
				rayStart -= sc;
				float a = dot(rayDir, rayDir);
				float b = dot(rayStart, rayDir) * 2.0f;
				float c = dot(rayStart, rayStart) - radius * radius; // radius is fixed: 0.5, should be optimized by the compiler
				float discriminant = b * b - 4.0f * a * c;
				if (discriminant < 0.0f) {
					return false;
				}
				else {
					discriminant = sqrt(discriminant);
					intersections = float2(-b - discriminant, -b + discriminant) / (2.0f * a);
				//  When the camera is inside the volume we may get negative values so the sphere from behind the camera gets "mirrored" into the view.
					intersections.x = max(intersections.x, 0);
					return true;
				}
			}


			real LuxComputeFogFactor(float z)
            {
                float clipZ_01 = UNITY_Z_0_FAR_FROM_CLIPSPACE(z);

            #if defined(FOG_LINEAR)
                // factor = (end-z)/(end-start) = z * (-1/(end-start)) + (end/(end-start))
                float fogFactor = saturate(clipZ_01 * unity_FogParams.z + unity_FogParams.w);
                return real(fogFactor);
            #elif defined(FOG_EXP) || defined(FOG_EXP2)
                // factor = exp(-(density*z)^2)
                // -density * z computed at vertex
                return real(unity_FogParams.x * clipZ_01);
            #else
                return 0.0h;
            #endif
            }


		//  ------------------------------------------------------------------
        //  Helper functions to handle orthographic / perspective projection  

            inline float GetOrthoDepthFromZBuffer (float rawDepth) {
                #if defined(UNITY_REVERSED_Z)
                //  Needed to handle openGL
                    #if UNITY_REVERSED_Z == 1
                        rawDepth = 1.0f - rawDepth;
                    #endif
                #endif
                return lerp(_ProjectionParams.y, _ProjectionParams.z, rawDepth);
            }

            inline float GetProperEyeDepth (float rawDepth) {
                #if defined(ORTHO_SUPPORT)
                    float perspectiveSceneDepth = LinearEyeDepth(rawDepth, _ZBufferParams);
                    float orthoSceneDepth = GetOrthoDepthFromZBuffer(rawDepth);
                    return lerp(perspectiveSceneDepth, orthoSceneDepth, unity_OrthoParams.w);
                #else
                    return LinearEyeDepth(rawDepth, _ZBufferParams);
                #endif
            }


			half4 frag (VertexOutput input) : SV_Target
			{
				UNITY_SETUP_INSTANCE_ID(input);
				UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);

				half4 color = half4(1,1,1,0);

				#if defined(ORTHO_SUPPORT)
                    input.positionCS.w = lerp(input.positionCS.w, 1.0f, unity_OrthoParams.w);
                #endif

				float2 screenUV = input.projectedPosition.xy / input.positionCS.w;

			//  Fix screenUV for Single Pass Stereo Rendering
                #if defined(UNITY_SINGLE_PASS_STEREO)
                    screenUV.x = screenUV.x * 0.5f + (float)unity_StereoEyeIndex * 0.5f;
                #endif 

				float3 viewDirWS = normalize(input.positionWS - _WorldSpaceCameraPos);

			//	Scene depth as linear eye depth
                #if defined(SHADER_API_GLES)
                    float sceneZ = SAMPLE_DEPTH_TEXTURE_LOD(_CameraDepthTexture, sampler_CameraDepthTexture, screenUV, 0);
                #else
                    float sceneZ = LUX_LOAD_TEXTURE2D_X(_CameraDepthTexture, _CameraDepthTexture_TexelSize.zw * screenUV).x;
                #endif
                sceneZ = GetProperEyeDepth(sceneZ);

			//	Convert linear eye depth to distance in world space
				float3 camForward = UNITY_MATRIX_V[2].xyz;
				float sceneDistance = sceneZ / dot(-viewDirWS, camForward);
				
				float3 rayDir = mul(GetWorldToObjectMatrix(), float4(viewDirWS, 0)).xyz;
				float3 rayStart = input.cameraPositionOS;
				float2 intersections = 0;
				bool intersect = IntersectRaySphere(rayStart , rayDir, float3(0, 0, 0), 0.5, intersections);

			//	Not needed if we use a sphere.
			//	UNITY_BRANCH
			//	if (intersect) {
					
				//	Entry point in world space
					float3 entry = mul(GetObjectToWorldMatrix(), float4(rayStart + rayDir * intersections.x, 1)).xyz;
				
					float distanceToEntry = length(entry - _WorldSpaceCameraPos);
					float sceneToEntry = sceneDistance - distanceToEntry;
					
				//  Nothing to do if the scene is in front of the entry point
                	clip(sceneToEntry);

                //  Exit point in world space
					float3 exit = mul(GetObjectToWorldMatrix(), float4(rayStart + rayDir * intersections.y, 1)).xyz;

					float maxTravel = distance(exit, entry);
					float denom = min(sceneToEntry, maxTravel);				
					float percentage = maxTravel / denom;
					percentage = rcp(percentage);

				//	This only attenuates alpha in object space :(
					float3 mid = rayStart + rayDir * (intersections.x + intersections.y) * 0.5;
					float alpha = 1 - length(mid) * 2.0;
				//	Smooth falloff - only the object space falloff
					alpha = smoothstep(_Lower, _Upper, alpha);

				//	In order to factor in object scale and dimensions we multiply alpha by maxTravel. / Not really correct 
					alpha *= maxTravel * input.scale * percentage;

				//	Smooth falloff
					//alpha = smoothstep(_Lower, _Upper, alpha);
				//	Scene blending
					//alpha *=  saturate(sceneToEntry / _SoftEdge);

				//	saturate eliminates artifacts at grazing angles
					color.a = saturate(alpha);
					
					#if defined(_ENABLEGRADIENT)
						color.rgb = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, float2(alpha, 0.5)).rgb;
					#endif
			//	}
				
				color *= _Color;

				#if defined(_APPLYFOG)
					#if defined(_HQFOG)
	                    float3 exitFog = mul(GetObjectToWorldMatrix(), float4(rayStart + rayDir * intersections.y * sqrt(percentage), 1)).xyz;
	                    float4 FogClipSpace = TransformWorldToHClip(exitFog);
	                    float fogFactor = LuxComputeFogFactor( FogClipSpace.z); 
	                    color.rgb = MixFog(color.rgb, fogFactor);
                   #else
						color.rgb = MixFog(color.rgb, input.fogCoord);
                   #endif
                #endif

				return color;
			}
			ENDHLSL
		}
	}
	FallBack "Hidden/InternalErrorShader"
}