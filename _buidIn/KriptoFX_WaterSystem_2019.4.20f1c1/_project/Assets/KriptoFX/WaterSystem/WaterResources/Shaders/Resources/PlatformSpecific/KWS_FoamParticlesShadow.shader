﻿Shader "Hidden/KriptoFX/KWS/FoamParticlesShadow"
{
    Properties
    {   _Color("Color", Color) = (0.9, 0.9, 0.9, 0.2)
        _MainTex("Texture", 2D) = "white" {}
        KW_VAT_Position("Position texture", 2D) = "white" {}
        KW_VAT_Alpha("Alpha texture", 2D) = "white" {}
        KW_VAT_Offset("Height Offset", 2D) = "black" {}
        KW_VAT_RangeLookup("Range Lookup texture", 2D) = "white" {}
        _FPS("FPS", Float) = 6.66666
        _Size("Size", Float) = 0.09
        _Scale("AABB Scale", Vector) = (26.3, 4.8, 30.5)
        _NoiseOffset("Noise Offset", Vector) = (0, 0, 0)
        _Offset("Offset", Vector) = (-9.35, -2.025, -15.6, 0)
        _Test("Test", Float) = 0.1
    }
        SubShader
        { 
            Tags {  "RenderType" = "Geometry" "Queue" = "Transparent"}
            Pass
            {
             Tags {"LightMode" = "ShadowCaster"}
             Blend SrcAlpha OneMinusSrcAlpha
             ZWrite On
             Cull Off

                HLSLPROGRAM
                #pragma vertex vert_foam
                #pragma fragment frag_foam
                #pragma multi_compile_shadowcaster
                #pragma multi_compile_instancing

                #pragma multi_compile _ FOAM_COMPUTE_WATER_OFFSET
                #pragma multi_compile _ USE_MULTIPLE_SIMULATIONS

                #include "UnityCG.cginc"


                #include "../Common/KWS_WaterVariables.cginc"
                #include "../Common/KWS_WaterPassHelpers.cginc"
                #include "../Common/KWS_CommonHelpers.cginc"
                #include "KWS_PlatformSpecificHelpers.cginc"

                #include "../Common/Shoreline/KWS_Shoreline_Common.cginc"
                #include "../Common/KWS_WaterVertPass.cginc"
                #include "../Common/Shoreline/KWS_FoamParticles_Core.cginc"
     

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

                    UNITY_INITIALIZE_OUTPUT(v2f_foam, o);
                    UNITY_SETUP_INSTANCE_ID(v);
                    UNITY_TRANSFER_INSTANCE_ID(v, o);
                    UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);


                    float particleID = v.uv.z;
                    float4 particleData = DecodeParticleData(particleID); //xyz - position, w - alpha
                    float depth;
                    float3 localPos = ParticleDataToLocalPosition(particleData.xyz, -0.05, depth);
                    v.vertex.xyz = CreateBillboardParticleRelativeToAlpha(0.65, v.uv.xy, localPos.xyz, particleData.w);
                    o.alpha = particleData.a * saturate(depth);
                    o.uv = GetParticleUV(v.uv.xy);
                    o.worldPos = mul(unity_ObjectToWorld, v.vertex);

                    o.pos = UnityObjectToClipPos(v.vertex);

                    TRANSFER_SHADOW_CASTER(o)
                    return o;
                }

                half4 frag_foam(v2f_foam i) : SV_Target
                {
                    half alpha = GetParticleAlphaShadow(i.alpha, _Color.a, i.uv);
                    if (alpha < 0.02) discard;

                    UNITY_SETUP_INSTANCE_ID(i);
                    SHADOW_CASTER_FRAGMENT(i)
                    return 0;
                }

                ENDHLSL
            }
        }
}
