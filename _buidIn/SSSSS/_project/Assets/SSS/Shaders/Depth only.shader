Shader "Custom/Depth Texture Only"
{
   
 
    SubShader {
        Tags {"Queue"="AlphaTest" "IgnoreProjector"="True" "RenderType"="TransparentCutout"}
 
        Pass {
            Tags { "LightMode" = "Always" }
            ColorMask 0
 
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
 
            #include "UnityCG.cginc"
 
            float4 vert() : SV_POSITION
            {
                return float4(0,0,0,1);
            }
 
            void frag() {}
            ENDCG
        }
 
        Pass {
            Tags { "LightMode" = "ShadowCaster" }
 
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma target 2.0
            #pragma multi_compile_shadowcaster
            #include "UnityCG.cginc"
 
            struct v2f {
                V2F_SHADOW_CASTER;
                float2  uv : TEXCOORD1;
            };
 
          
 
            v2f vert( appdata_base v )
            {
                v2f o = (v2f)0;
                o.pos = float4(0,0,0,1);
               
            #ifdef SHADOWS_DEPTH
                // We're a camera depth pass
                if (UNITY_MATRIX_P[3][3] == 0.0)
                {
                    TRANSFER_SHADOW_CASTER_NORMALOFFSET(o)
                  
                }
            #endif
                return o;
            }
 
            float4 frag( v2f i ) : SV_Target
            {
                
                SHADOW_CASTER_FRAGMENT(i)
            }
            ENDCG
        }
    }
}