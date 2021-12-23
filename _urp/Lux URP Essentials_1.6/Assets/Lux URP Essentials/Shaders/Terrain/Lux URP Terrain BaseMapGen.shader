Shader "Hidden/Lux URP/Terrain/Lit (Basemap Gen)"
{
    Properties
    {
        // Layer count is passed down to guide height-blend enable/disable, due
        // to the fact that heigh-based blend will be broken with multipass.
        [HideInInspector] [PerRendererData] _NumLayersCount ("Total Layer Count", Float) = 1.0
        [HideInInspector] _Control("AlphaMap", 2D) = "" {}
        
        [HideInInspector] _Splat0 ("Layer 0 (R)", 2D) = "white" {}
        [HideInInspector] _Splat1 ("Layer 1 (G)", 2D) = "white" {}
        [HideInInspector] _Splat2 ("Layer 2 (B)", 2D) = "white" {}
        [HideInInspector] _Splat3 ("Layer 3 (A)", 2D) = "white" {}
        [HideInInspector] _Mask3("Mask 3 (A)", 2D) = "grey" {}
        [HideInInspector] _Mask2("Mask 2 (B)", 2D) = "grey" {}
        [HideInInspector] _Mask1("Mask 1 (G)", 2D) = "grey" {}
        [HideInInspector] _Mask0("Mask 0 (R)", 2D) = "grey" {}        
        [HideInInspector] [Gamma] _Metallic0 ("Metallic 0", Range(0.0, 1.0)) = 0.0
        [HideInInspector] [Gamma] _Metallic1 ("Metallic 1", Range(0.0, 1.0)) = 0.0
        [HideInInspector] [Gamma] _Metallic2 ("Metallic 2", Range(0.0, 1.0)) = 0.0
        [HideInInspector] [Gamma] _Metallic3 ("Metallic 3", Range(0.0, 1.0)) = 0.0
        [HideInInspector] _Smoothness0 ("Smoothness 0", Range(0.0, 1.0)) = 1.0
        [HideInInspector] _Smoothness1 ("Smoothness 1", Range(0.0, 1.0)) = 1.0
        [HideInInspector] _Smoothness2 ("Smoothness 2", Range(0.0, 1.0)) = 1.0
        [HideInInspector] _Smoothness3 ("Smoothness 3", Range(0.0, 1.0)) = 1.0

[NoScaleOffset] _HeightMaps             ("     Height Maps (RGBA)", 2D) = "grey" {}

        [HideInInspector] _DstBlend("DstBlend", Float) = 0.0
    }
    
    Subshader
    {
        HLSLINCLUDE
        // Required to compile gles 2.0 with standard srp library
        #pragma prefer_hlslcc gles
        #pragma exclude_renderers d3d11_9x
        #pragma target 3.0
        
//        #define _METALLICSPECGLOSSMAP 1
        #define _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A 1
        #define _TERRAIN_BASEMAP_GEN

        #pragma shader_feature_local _TERRAIN_BLEND_HEIGHT
        #pragma shader_feature_local _MASKMAP
        
        #include "Includes/TerrainLitInput.hlsl"
        #include "Includes/TerrainLitPasses.hlsl"
       
        ENDHLSL
        
        Pass
        {
            Tags
            {
                "Name" = "_MainTex"
                "Format" = "ARGB32"
                "Size" = "1"
            }

            ZTest Always Cull Off ZWrite Off
            Blend One [_DstBlend]     
            HLSLPROGRAM

            #pragma vertex Vert
            #pragma fragment Frag
            
            Varyings Vert(Attributes IN)
            {
                Varyings output = (Varyings)0;
                output.clipPos = TransformWorldToHClip(IN.positionOS.xyz);
                output.uvMainAndLM.xy = IN.texcoord;
                output.uvSplat01.xy = TRANSFORM_TEX(IN.texcoord, _Splat0);
                output.uvSplat01.zw = TRANSFORM_TEX(IN.texcoord, _Splat1);
                output.uvSplat23.xy = TRANSFORM_TEX(IN.texcoord, _Splat2);
                output.uvSplat23.zw = TRANSFORM_TEX(IN.texcoord, _Splat3);

                return output;
            }
            
            half4 Frag(Varyings IN) : SV_Target
            {
                half3 normalTS = half3(0.0h, 0.0h, 1.0h);
                half4 splatControl;
                half weight;
                half4 mixedDiffuse = 0.0h;
                half4 defaultSmoothness = 0.0h;
    
                half4 masks[4];
                float2 splatUV = (IN.uvMainAndLM.xy * (_Control_TexelSize.zw - 1.0f) + 0.5f) * _Control_TexelSize.xy;
                splatControl = SAMPLE_TEXTURE2D(_Control, sampler_Control, splatUV);
                
                #ifdef _TERRAIN_BLEND_HEIGHT
                    half4 heights;
                    heights.x = SAMPLE_TEXTURE2D(_HeightMaps, sampler_Splat0, IN.uvSplat01.xy).r;
                    heights.y = SAMPLE_TEXTURE2D(_HeightMaps, sampler_Splat0, IN.uvSplat01.zw).g;
                    heights.z = SAMPLE_TEXTURE2D(_HeightMaps, sampler_Splat0, IN.uvSplat23.xy).b;
                    heights.w = SAMPLE_TEXTURE2D(_HeightMaps, sampler_Splat0, IN.uvSplat23.zw).a;

                    half height;
                    HeightBasedSplatModifyCombined(splatControl, heights, height);
                #endif
          
                SplatmapMix(IN.uvMainAndLM, IN.uvSplat01, IN.uvSplat23, splatControl, weight, mixedDiffuse, defaultSmoothness, normalTS);
                half smoothness = dot(splatControl, defaultSmoothness);
                return half4(mixedDiffuse.rgb, smoothness);
            }

            ENDHLSL
        }
       

//  Not used, not tweaked...
        Pass
        {
            Tags
            {
                "Name" = "_MetallicTex"
                "Format" = "R8"
                "Size" = "1/4"
                "EmptyColor" = "FF000000"
            }

            ZTest Always Cull Off ZWrite Off
            Blend One [_DstBlend]     

            HLSLPROGRAM

            #pragma vertex Vert
            #pragma fragment Frag
            
            Varyings Vert(Attributes IN)
            {
                Varyings output = (Varyings)0;
                
                output.clipPos = TransformWorldToHClip(IN.positionOS.xyz);
                
                // This is just like the other in that it is from TerrainLitPasses
                output.uvMainAndLM.xy = IN.texcoord;
                output.uvSplat01.xy = TRANSFORM_TEX(IN.texcoord, _Splat0);
                output.uvSplat01.zw = TRANSFORM_TEX(IN.texcoord, _Splat1);
                output.uvSplat23.xy = TRANSFORM_TEX(IN.texcoord, _Splat2);
                output.uvSplat23.zw = TRANSFORM_TEX(IN.texcoord, _Splat3);
                
                return output;
            }
            
            half4 Frag(Varyings IN) : SV_Target
            {
                half3 normalTS = half3(0.0h, 0.0h, 1.0h);
                half4 splatControl;
                half weight;
                half4 mixedDiffuse;
                half4 defaultSmoothness;
    
                half4 masks[4];
                float2 splatUV = (IN.uvMainAndLM.xy * (_Control_TexelSize.zw - 1.0f) + 0.5f) * _Control_TexelSize.xy;                
                splatControl = SAMPLE_TEXTURE2D(_Control, sampler_Control, splatUV);
                
                SplatmapMix(IN.uvMainAndLM, IN.uvSplat01, IN.uvSplat23, splatControl, weight, mixedDiffuse, defaultSmoothness, normalTS);
                
                half4 defaultMetallic = half4(_Metallic0, _Metallic1, _Metallic2, _Metallic3);
                half metallic = dot(splatControl, defaultMetallic);
                
                return metallic;
            }
            
            ENDHLSL
        }
    }
}