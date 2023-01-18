Shader "Hidden/KriptoFX/KWS/FoamParticles"
{
    Properties
    {
        _Color ("Color", Color) = (0.9, 0.9, 0.9, 0.2)
        _MainTex ("Texture", 2D) = "white" { }
        KW_VAT_Position ("Position texture", 2D) = "white" { }
        KW_VAT_Alpha ("Alpha texture", 2D) = "white" { }
        KW_VAT_Offset ("Height Offset", 2D) = "black" { }
        KW_VAT_RangeLookup ("Range Lookup texture", 2D) = "white" { }
        _FPS ("FPS", Float) = 6.66666
        _Size ("Size", Float) = 0.09
        _Scale ("AABB Scale", Vector) = (26.3, 4.8, 30.5)
        _NoiseOffset ("Noise Offset", Vector) = (0, 0, 0)
        _Offset ("Offset", Vector) = (-9.35, -2.025, -15.6, 0)
        _Test ("Test", Float) = 0.1
    }
    SubShader
    {
        Tags { "RenderType" = "Geometry" "Queue" = "Transparent" }
        Pass
        {
            Blend SrcAlpha OneMinusSrcAlpha
            ZWrite Off
            Cull Off

            CGPROGRAM

            #define FORWARD_BASE_PASS
            //#define KWS_USE_SOFT_SHADOWS
            #define KWS_DISABLE_POINT_SPOT_SHADOWS

            #pragma vertex vert_foam
            #pragma fragment frag_foam
            
            #pragma multi_compile_fog

            #pragma multi_compile _ FOAM_RECEIVE_SHADOWS
            #pragma multi_compile _ FOAM_COMPUTE_WATER_OFFSET
            #pragma multi_compile KWS_USE_STANDARD_DIR KWS_USE_DIR_LIGHT KWS_USE_DIR_LIGHT_SINGLE KWS_USE_DIR_LIGHT_SPLIT KWS_USE_DIR_LIGHT_SINGLE_SPLIT //It looks terrible, but it is necessary to optimize shaders variants.
            //#pragma multi_compile _ KWS_USE_POINT_LIGHTS
            //#pragma multi_compile _ KWS_USE_SHADOW_POINT_LIGHTS
            //#pragma multi_compile _ KWS_USE_SPOT_LIGHTS
            //#pragma multi_compile _ KWS_USE_SHADOW_SPOT_LIGHTS

            #pragma multi_compile _ USE_MULTIPLE_SIMULATIONS

            #include "UnityCG.cginc"


            #include "../Common/KWS_WaterVariables.cginc"
            #include "../Common/KWS_WaterPassHelpers.cginc"
            #include "../Common/KWS_CommonHelpers.cginc"
            #include "KWS_PlatformSpecificHelpers.cginc"

            #include "../Common/Shoreline/KWS_Shoreline_Common.cginc"
            #include "../Common/KWS_WaterVertPass.cginc"
            #include "../PlatformSpecific/KWS_Lighting.cginc"
            #include "../Common/Shoreline/KWS_FoamParticles_Core.cginc"

            
            #if defined(KWS_USE_STANDARD_DIR)
                #define GetMainLight(worldPos) GetStandardMainLight(worldPos)
            #else
                #define GetMainLight(worldPos) GetCustomMainLight(worldPos)
            #endif

            inline half3 GetCustomMainLight(float3 worldPos)
            {
                half3 lightColor = 0;
                half atten = 1.0;
                #if defined(KWS_USE_DIR_LIGHT) || defined(KWS_USE_DIR_LIGHT_SINGLE) || defined(KWS_USE_DIR_LIGHT_SPLIT) || defined(KWS_USE_DIR_LIGHT_SINGLE_SPLIT)
                    ShadowLightData light = KWS_DirLightsBuffer[0];
                    #if defined(FOAM_RECEIVE_SHADOWS)
                        atten = DirLightRealtimeShadow(0, worldPos.xyz);
                    #endif
                    #ifdef UNITY_COLORSPACE_GAMMA
                        lightColor.rgb = saturate(GetAmbientColor()) * 0.5 + saturate(light.color.rgb) * lerp(0.35, 1, atten);
                    #else
                        lightColor.rgb = saturate(GetAmbientColor()) * 0.5 + saturate(light.color.rgb) * lerp(0.1, 1, atten);
                    #endif
                #else
                    lightColor.rgb = GetAmbientColor();
                #endif
                return clamp(lightColor, 0, 0.95);
            }

            inline half3 GetStandardMainLight(float3 worldPos)
            {
                return clamp(GetMainLightColor() + GetAmbientColor(), 0, 0.95);
            }

            inline half3 GetCustomAdditionalLights(float3 worldPos)
            {
                half3 lightColor = 0;
                half atten = 1.0;

                #if defined(KWS_USE_POINT_LIGHTS)
                    [loop]
                    for (uint pointIdx = 0; pointIdx < KWS_PointLightsCount; pointIdx++)
                    {
                        LightData light = KWS_PointLightsBuffer[pointIdx];
                        atten = PointLightAttenuation(pointIdx, worldPos.xyz);
                        lightColor.rgb += light.color.rgb * atten;
                    }
                #endif

                #if defined(KWS_USE_SHADOW_POINT_LIGHTS)
                    [loop]
                    for (uint shadowPointIdx = 0; shadowPointIdx < KWS_ShadowPointLightsCount; shadowPointIdx++)
                    {
                        ShadowLightData light = KWS_ShadowPointLightsBuffer[shadowPointIdx];
                        atten = PointLightAttenuationShadow(shadowPointIdx, worldPos.xyz);
                        lightColor.rgb += light.color.rgb * atten;
                    }
                #endif

                #if defined(KWS_USE_SPOT_LIGHTS)
                    [loop]
                    for (uint spotIdx = 0; spotIdx < KWS_SpotLightsCount; spotIdx++)
                    {
                        LightData light = KWS_SpotLightsBuffer[spotIdx];
                        atten = SpotLightAttenuation(spotIdx, worldPos.xyz);
                        lightColor.rgb += light.color.rgb * atten;
                    }
                #endif

                #if defined(KWS_USE_SHADOW_SPOT_LIGHTS)

                    [loop]
                    for (uint shadowSpotIdx = 0; shadowSpotIdx < KWS_ShadowSpotLightsCount; shadowSpotIdx++)
                    {
                        ShadowLightData light = KWS_ShadowSpotLightsBuffer[shadowSpotIdx];
                        atten = SpotLightAttenuationShadow(shadowSpotIdx, worldPos.xyz);
                        lightColor.rgb += light.color.rgb * atten;
                    }
                #endif
                return lightColor;
            }


            struct v2f_foam
            {
                float4 pos : SV_POSITION;
                float2 uv : TEXCOORD0;
                float alpha : TEXCOORD1;
                float3 worldPos : TEXCOORD2;
            };

            v2f_foam vert_foam(appdata_foam v)
            {
                v2f_foam o;

                float particleID = v.uv.z;
                float4 particleData = DecodeParticleData(particleID); //xyz - position, w - alpha
                float depth;
                float3 localPos = ParticleDataToLocalPosition(particleData.xyz, 0.0, depth);
                v.vertex.xyz = CreateBillboardParticle(0.65, v.uv.xy, localPos.xyz);
                o.alpha = particleData.a;
                o.uv = GetParticleUV(v.uv.xy);
                o.worldPos = LocalToWorldPos(v.vertex.xyz);
                o.pos = ObjectToClipPos(v.vertex);
                return o;
            }

            half4 frag_foam(v2f_foam i) : SV_Target
            {
                
                half4 result;
                result.a = GetParticleAlpha(i.alpha, _Color.a, i.uv);
                
                UNITY_BRANCH if (result.a < 0.02) return 0;

                result.rgb = GetMainLight(i.worldPos.xyz);
                
                half3 fogColor;
                half3 fogOpacity;
                float distanceToCamera = GetWorldToCameraDistance(i.worldPos);
                GetInternalFogVariables(i.pos, 0, distanceToCamera, 0, fogColor, fogOpacity);
                result.rgb = ComputeInternalFog(result.rgb, fogColor, fogOpacity);

                result.rgb = ComputeThirdPartyFog(result.rgb, i.worldPos.xyz, i.uv, i.pos.z);
                
                return result;
            }

            ENDCG
        }
    }
}
