// https://api.unrealengine.com/udk/Three/VolumetricLightbeamTutorial.html
// https://www.gamedev.net/forums/topic/692224-udk-volumetric-light-beam/

Shader "Lux URP/FX/Lightbeam"
{
    Properties
    {
        [HeaderHelpLuxURP_URL(m12h3vad3enc)]
        
        [Header(Surface Options)]
        [Space(8)]
        [Enum(UnityEngine.Rendering.CompareFunction)]
        _ZTest                                      ("ZTest", Int) = 4
        [Enum(UnityEngine.Rendering.CullMode)]
        _Cull                                       ("Culling", Float) = 2
        [Toggle(ORTHO_SUPPORT)]
        _OrthoSpport                                ("Enable Orthographic Support", Float) = 0

        [Header(Surface Inputs)]
        [Space(8)]
        [HDR] _Color                                ("Color", Color) = (1,1,1,1)
        [NoScaleOffset] _MainTex                    ("Fall Off (G)", 2D) = "white" {}
        [NoScaleOffset] _SpotTex                    ("Spot Mask (G)", 2D) = "white" {}

        _ConeWidth                                  ("Cone Width", Range(1.0, 10.0)) = 8.0              // 8.0 from UDK
        _SpotFade                                   ("Spot Mask Intensity", Range(0.51, 1.0)) = 0.6     // 0.6 from UDK

        [Header(Detail Noise)]
        [Space(8)]
        [Toggle(_MASKMAP)]
        _SpecGlossEnabled                           ("Enable detail noise", Float) = 0
        _DetailTex                                  ("     Detail Noise (G)", 2D) = "white" {}
        _DetailStrength                             ("     Strength", Range(0.0, 1.0)) = 1.0
        _DetailScrollSpeed                          ("     Scroll Speed 1:(XY) 2:(ZW)", Vector) = (0,0,0,0)


        [Header(Scene Fade)]
        [Space(8)]
        _near                                       ("     Near", Float) = 0.0
        _far                                        ("     Soft Edge Factor", Float) = 2.0

        [Header(Camera Fade)]
        [Space(8)]
        [LuxURPCameraFadeDrawer]
        _CameraFadeDistances                        ("Camera Fade Distances", Vector) = (0.3,1,0.3,1) // !!! x + y are used, z + w are displayed

        [Space(5)]
        _LimitLength                                ("Limit Length", Float) = 50.0

    }
    SubShader
    {
        Tags
        {
            "RenderPipeline" = "UniversalPipeline"
            "RenderType"="Opaque"
            "Queue"= "Transparent+50"       // Make it fit built in transparent shaders' queue
        }
        Pass
        {
            Name "StandardUnlit"
            Tags{"LightMode" = "UniversalForward"}


            Blend SrcAlpha OneMinusSrcAlpha
            ColorMask RGB

            Cull [_Cull]
            ZTest [_ZTest]
            ZWrite Off

            HLSLPROGRAM
            // Required to compile gles 2.0 with standard srp library
            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x
            #pragma target 2.0

            #pragma shader_feature_local _MASKMAP
            #pragma shader_feature_local ORTHO_SUPPORT

            // -------------------------------------
            // Lightweight Pipeline keywords

            // -------------------------------------
            // Unity defined keywords
            #pragma multi_compile_fog

            //--------------------------------------
            // GPU Instancing
            #pragma multi_compile_instancing
            
            #pragma vertex vert
            #pragma fragment frag

            // Lighting include is needed because of GI
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/Shaders/UnlitInput.hlsl"

            CBUFFER_START(UnityPerMaterial)
                half4 _Color;

                half _SpotFade;
                half _ConeWidth;

                float _near;
                float _far;
                float2 _CameraFadeDistances;
                float _LimitLength;

                //#if defined(_MASKMAP)
                    half _DetailStrength;
                    float4 _DetailScrollSpeed;
                    float4 _DetailTex_ST;
                //#endif

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

            TEXTURE2D(_MainTex); SAMPLER(sampler_MainTex);
            TEXTURE2D(_SpotTex); SAMPLER(sampler_SpotTex);
            #if defined(SHADER_API_GLES)
                TEXTURE2D(_CameraDepthTexture); SAMPLER(sampler_CameraDepthTexture);
            #else
                LUX_TEXTURE2D_X_FLOAT(_CameraDepthTexture);
            #endif
            float4 _CameraDepthTexture_TexelSize;

            #if defined(_MASKMAP)
                TEXTURE2D(_DetailTex); SAMPLER(sampler_DetailTex);
            #endif

            struct VertexInput
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float4 tangent : TANGENT;
                float2 texcoord : TEXCOORD0;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };


            struct VertexOutput
            {
                float4 positionCS : POSITION;
                float fogCoord : TEXCOORD0;
                float4 uv : TEXCOORD1;
                float2 projectedPosition : TEXCOORD2;
                float distFade : TEXCOORD3;

                #if defined(_MASKMAP)
                    float4 detail_texcoord : TEXCOORD4;
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
                
                o.fogCoord = ComputeFogFactor(o.positionCS.z);

                #if defined(_MASKMAP)
                    o.detail_texcoord.xy = TRANSFORM_TEX(input.texcoord, _DetailTex);
                    o.detail_texcoord.zw = o.detail_texcoord.xy * 2;
                    _DetailScrollSpeed *= _Time.x;
                    o.detail_texcoord.xy += _DetailScrollSpeed.xy;
                    o.detail_texcoord.zw += _DetailScrollSpeed.zw;
                #endif

                o.uv.y = input.texcoord.y;
            
            //  Calculate Tangent Space viewDir
            //  ObjSpaceViewDir
                float3 objSpaceCameraPos = mul(unity_WorldToObject, float4(_WorldSpaceCameraPos.xyz, 1)).xyz;
                float3 ObjSpaceViewDir = objSpaceCameraPos - input.vertex.xyz;
            //  TANGENT_SPACE_ROTATION
                float3 binormal = cross( normalize(input.normal), normalize(input.tangent.xyz) ) * input.tangent.w;
                float3x3 tangentSpaceRotation = float3x3(input.tangent.xyz, binormal, input.normal );
            //  Reflect Vector
                float3 rVec = mul(tangentSpaceRotation, normalize(ObjSpaceViewDir));
            //  Needed by back faces
                rVec.z = abs(rVec.z);

                rVec.z = sqrt( (rVec.z + _SpotFade) * _ConeWidth);

                rVec.x = rVec.x / rVec.z + 0.5f;
                rVec.y = rVec.y / rVec.z + 0.5f;
                o.uv.x = rVec.x;
                o.uv.zw = rVec.xy;

                o.projectedPosition = vertexInput.positionNDC.xy;
                o.distFade = saturate(_LimitLength - length(input.vertex.xyz));
                return o;
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

                half4 col = _Color;
                half mask01 = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, input.uv.xy).g;
                half mask02 = SAMPLE_TEXTURE2D(_SpotTex, sampler_SpotTex, input.uv.zw).g;

                #if defined(_MASKMAP)
                    half detailTex = SAMPLE_TEXTURE2D(_DetailTex, sampler_DetailTex, input.detail_texcoord.xy).g;
                    detailTex *= SAMPLE_TEXTURE2D(_DetailTex, sampler_DetailTex, input.detail_texcoord.zw).g;
                    col *= lerp(1, detailTex, _DetailStrength);
                #endif

                #if defined(ORTHO_SUPPORT)
                    input.positionCS.w = lerp(input.positionCS.w, 1.0f, unity_OrthoParams.w);
                    float thisZ = GetProperEyeDepth(input.positionCS.z);
                #else
                    float thisZ = input.positionCS.w;
                #endif

                float2 screenUV = (input.projectedPosition.xy / input.positionCS.w);
            //  Fix screenUV for Single Pass Stereo Rendering
                #if defined(UNITY_SINGLE_PASS_STEREO)
                    screenUV.x = screenUV.x * 0.5f + (float)unity_StereoEyeIndex * 0.5f;
                #endif 

            //  Get scene depth
                #if defined(SHADER_API_GLES)
                    float sceneZ = SAMPLE_DEPTH_TEXTURE_LOD(_CameraDepthTexture, sampler_CameraDepthTexture, screenUV, 0);
                #else
                    float sceneZ = LUX_LOAD_TEXTURE2D_X(_CameraDepthTexture, _CameraDepthTexture_TexelSize.zw * screenUV).x;
                #endif
                sceneZ = GetProperEyeDepth(sceneZ);

            //  Surface fade
                float fade = saturate (_far * ((sceneZ - _near) - thisZ));
            //  Camera fade
                fade *= saturate( (thisZ - _CameraFadeDistances.x) * _CameraFadeDistances.y);
            //  Combine
                col.a *= mask01 * mask02 * fade * input.distFade;
                col.rgb = MixFog(_Color.rgb, input.fogCoord);
                return half4(col);
            }
            ENDHLSL
        }
    }
    FallBack "Hidden/InternalErrorShader"
}

