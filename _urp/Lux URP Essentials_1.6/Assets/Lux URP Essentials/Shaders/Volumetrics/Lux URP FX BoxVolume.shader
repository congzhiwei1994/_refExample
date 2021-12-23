Shader "Lux URP/FX/Box Volume"
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
        _Color                      ("Color", Color) = (1,1,1,1)
        [Toggle(_ENABLEGRADIENT)]
        _EnableGradient             ("Enable Gradient", Float) = 0
        [NoScaleOffset]
        _MainTex                    ("     Vertical Gradient", 2D) = "white" {}

        [Header(Thickness Remap)]
        [Space(8)]
        _Lower                      ("     Lower", Range(0,1)) = 0
        _Upper                      ("     Upper", Range(0,4)) = 1
        //[Space(5)]
        //_SoftEdge                   ("     Soft Edge Factor", Float) = 2.0

        [Space(5)]
        [Toggle(_APPLYFOG)]
        _ApplyFog                   ("Enable Fog", Float) = 0.0
        [Toggle(_HQFOG)]
        _HQFog                      ("     HQ Fog", Float) = 0.0

    }
    SubShader
    {
        Tags
        {
            "RenderPipeline" = "UniversalPipeline"
            "RenderType"="Transparent"
            "Queue"="Transparent+50"
        }
        Pass
        {
            Name "StandardUnlit"
            Tags{"LightMode" = "UniversalForward"}

            Blend SrcAlpha OneMinusSrcAlpha

        //  As we want to be able to enter the volume we have to draw the back faces
            Cull [_Cull]
        //  We fully rely on the depth texture sample!
            ZTest [_ZTest]
            ZWrite Off

            HLSLPROGRAM
            // Required to compile gles 2.0 with standard srp library
            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x
            #pragma target 2.0

            #pragma shader_feature_local _ENABLEGRADIENT
            #pragma shader_feature_local _APPLYFOG
            #pragma shader_feature_local ORTHO_SUPPORT

            // -------------------------------------
            // Lightweight Pipeline keywords

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

            #if defined(_ENABLEGRADIENT)
                TEXTURE2D(_MainTex); SAMPLER(sampler_MainTex);
            #endif
            #if defined(SHADER_API_GLES)
                TEXTURE2D(_CameraDepthTexture); SAMPLER(sampler_CameraDepthTexture);
            #else
                TEXTURE2D_X_FLOAT(_CameraDepthTexture);
            #endif
            float4 _CameraDepthTexture_TexelSize;

            struct VertexInput
            {
                float4 vertex : POSITION;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct VertexOutput
            {
                float4 positionCS : POSITION;
                float3 positionWS : TEXCOORD1;
                float2 projectedPosition : TEXCOORD2;
                float3 cameraPositionOS : TEXCOORD3;
                float scale : TEXCOORD4;
                
                #if defined(_APPLYFOG)
                    half fogCoord : TEXCOORD5;
                #endif

                float4 viewRayOS : TEXCOORD6;

                UNITY_VERTEX_INPUT_INSTANCE_ID
                UNITY_VERTEX_OUTPUT_STEREO
            };


            float IntersectRayBox(float3 rayOrigin, float3 rayDirection,
                  out float tEntr, out float tExit)
            {
                // Could be precomputed. Clamp to avoid INF. clamp() is a single ALU on GCN.
                // rcp(FLT_EPS) = 16,777,216, which is large enough for our purposes,
                // yet doesn't cause a lot of numerical issues associated with FLT_MAX.
                float3 rayDirInv = clamp(rcp(rayDirection), -rcp(FLT_EPS), rcp(FLT_EPS));

                // Perform ray-slab intersection (component-wise).
                float3 boxMin = float3(-0.5, -0.5, -0.5);
                float3 boxMax = float3( 0.5,  0.5,  0.5);

                float3 t0 = boxMin * rayDirInv - (rayOrigin * rayDirInv);
                float3 t1 = boxMax * rayDirInv - (rayOrigin * rayDirInv);

                // Find the closest/farthest distance (component-wise).
                float3 tSlabEntr = min(t0, t1);
                float3 tSlabExit = max(t0, t1);

                // Find the farthest entry and the nearest exit.
                tEntr = Max3(tSlabEntr.x, tSlabEntr.y, tSlabEntr.z);
                tExit = Min3(tSlabExit.x, tSlabExit.y, tSlabExit.z);

            //  When the camera is inside the volume we may get negative values so the box from behind the camera gets "mirrored" into the view.
            //  Using max(0, ) suppresses these artifacts.
                tEntr = max(0.0f, tEntr);
                return tExit - tEntr;
            }


            VertexOutput vert (VertexInput v)
            {
                VertexOutput o = (VertexOutput)0;
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_TRANSFER_INSTANCE_ID(v, o);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

            //  
                VertexPositionInputs vertexInput = GetVertexPositionInputs(v.vertex.xyz);
                o.positionCS = vertexInput.positionCS;
                o.projectedPosition = vertexInput.positionNDC.xy;
                o.positionWS = vertexInput.positionWS;
                o.cameraPositionOS = mul(unity_WorldToObject, float4(_WorldSpaceCameraPos, 1)).xyz;

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

                float4 positionVS = mul(UNITY_MATRIX_MV, v.vertex);
                float3 viewRayVS = positionVS.xyz;
                //  NOTE: Fix direction of the viewRay
                float4x4 ViewToObjectMatrix = mul(GetWorldToObjectMatrix(), UNITY_MATRIX_I_V);
                o.viewRayOS.xyz = mul((float3x3)ViewToObjectMatrix, -viewRayVS).xyz;
                //  positionVS.z here acts as view space to object space ratio (negative)
                o.viewRayOS.w = positionVS.z; 

                return o;
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


            half4 frag (VertexOutput input ) : SV_Target
            {
                UNITY_SETUP_INSTANCE_ID(input);
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);
                
                half4 color = half4(1,1,1,0);
    
                float3 rayDir = input.viewRayOS.xyz / input.viewRayOS.w;
                float3 rayStart = input.cameraPositionOS;

                float2 screenUV = input.projectedPosition.xy / input.positionCS.w;

            //  Fix screenUV for Single Pass Stereo Rendering
                #if defined(UNITY_SINGLE_PASS_STEREO)
                    screenUV.x = screenUV.x * 0.5f + (float)unity_StereoEyeIndex * 0.5f;
                #endif

                #if defined(SHADER_API_GLES)
                    float sceneZ = SAMPLE_DEPTH_TEXTURE_LOD(_CameraDepthTexture, sampler_CameraDepthTexture, screenUV, 0);
                #else
                    float sceneZ = LOAD_TEXTURE2D_X(_CameraDepthTexture, _CameraDepthTexture_TexelSize.zw * screenUV).x;
                #endif
                sceneZ = GetProperEyeDepth(sceneZ);
            
                float near;
                float far;
                float thickness = IntersectRayBox(rayStart, rayDir, near, far);

            //  Entry point in object space
                float3 entryOS = rayStart + rayDir * near;
                float distanceToEntryOS = length(entryOS - input.cameraPositionOS);

                float sceneDistanceOS = length(sceneZ * rayDir);
                float sceneToEntry = sceneDistanceOS - distanceToEntryOS;

            //  Nothing to do if the scene is in front of the entry point
                clip(sceneToEntry);

            //  Exit point in object space
                float3 exitOS = rayStart + rayDir * far;

                float maxTravel = distance(exitOS, entryOS);
                float denom = min(sceneToEntry, maxTravel);
                float percentage = maxTravel / denom;

                percentage = rcp(percentage);

                float alpha = thickness * input.scale * percentage;

            //  Smooth falloff
                alpha =  smoothstep(_Lower, _Upper, alpha);
            //  Scene blending - as otherwise we may get 1px wide artifacts at the borders.
                //alpha *= saturate(sceneToEntry / _SoftEdge );

            //  saturate eliminates artifacts at grazing angles
                color.a = saturate(alpha);

                #if defined(_ENABLEGRADIENT)
                    color.rgb = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, float2(input.positionOS_scale.y, 0)).rgb;
                #endif

                color *= _Color;
                
            //  Here was a nasty bug!
                #if defined(_APPLYFOG)
                    #if defined(_HQFOG)
                        float3 exitFog = mul(GetObjectToWorldMatrix(), float4(rayStart + rayDir * far * sqrt(percentage), 1)).xyz;
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
