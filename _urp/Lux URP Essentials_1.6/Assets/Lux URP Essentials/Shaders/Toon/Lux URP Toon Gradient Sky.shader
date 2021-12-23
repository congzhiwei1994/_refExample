//https://github.com/keijiro/UnitySkyboxShaders/
Shader "Lux URP/Gradient Sky"
{
    Properties
    {
        [Header(Surface Inputs)]
        [Space(8)]
        [HDR] _GroundColor  ("Base Color", Color) = (1,1,1,1)
        [HDR] _TopColor     ("Top Color", Color) = (1,1,1,1)
        _Intensity ("Intensity", Range (0, 1)) = 1

        [Space(5)]
        _FallOff ("Fall Off", Range (0, 16)) = 1.0
        _Yaw ("Yaw", Range (-3.14159, 3.14159)) = 0
        _Pitch ("Pitch", Range (-3.14159, 3.14159)) = 0
        
    }

    SubShader
    {
        Tags
        {
            "RenderPipeline" = "UniversalPipeline"
            "RenderType" = "Background"
            "Queue" = "Background"
        }
        Pass
        {
            Name "Unlit"
            //Tags{"LightMode" = "UniversalForward"}

            //Blend SrcAlpha OneMinusSrcAlpha

            Cull Back
            ZWrite Off

            HLSLPROGRAM
            // Required to compile gles 2.0 with standard srp library
            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x
            #pragma target 2.0

            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            
            CBUFFER_START(UnityPerMaterial)
                half4 _GroundColor;
                half4 _TopColor;
                half  _FallOff;
                half _Yaw;
                half _Pitch;
                half _Intensity;
            CBUFFER_END

            struct VertexInput
            {
                float4 vertex : POSITION;
                float3 uv : TEXCOORD0;
            };

            struct VertexOutput
            {
                float4 positionCS : SV_POSITION;
                UNITY_VERTEX_OUTPUT_STEREO
                float3 uv : TEXCOORD0;
                float3 dir : TEXCOORD1;
            };

            VertexOutput vert (VertexInput v)
            {
                VertexOutput output = (VertexOutput)0;
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);
                output.positionCS = TransformObjectToHClip(v.vertex.xyz);
                output.uv = v.uv;
                half sinPitch, cosPitch, sinYaw, cosYaw;
                sincos (_Pitch, sinPitch, cosPitch);
                sincos (_Yaw, sinYaw, cosYaw);
                output.dir = half3(sinPitch * sinYaw, cosPitch, sinPitch * cosYaw);

                return output;
            }


            half4 frag (VertexOutput input ) : SV_Target
            {
                half gradient = dot( normalize(float3(input.uv.xyz)), input.dir) * 0.5h + 0.5h;
                half4 col = lerp(_GroundColor, _TopColor, pow(gradient, _FallOff)) * _Intensity;
                return half4(col.xyz, 1.0h);
            }
            ENDHLSL
        }
    }
    FallBack "Hidden/InternalErrorShader"
    CustomEditor "LuxURPUniversalCustomShaderGUI"
}