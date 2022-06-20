Shader "CustomRP/Lit"
{
    Properties
    {
	   _BaseMap("Texture", 2D) = "white" {}
	   _BaseColor("Color", Color) = (0.5, 0.5, 0.5, 1.0)
	   //透明度测试的阈值
	   _Cutoff("Alpha Cutoff", Range(0.0, 1.0)) = 0.5
	   [Toggle(_CLIPPING)] _Clipping("Alpha Clipping", Float) = 0
	   //阴影模式
	   [KeywordEnum(On, Clip, Dither, Off)] _Shadows ("Shadows", Float) = 0
	   //是否接受阴影
	   [Toggle(_RECEIVE_SHADOWS)] _ReceiveShadows ("Receive Shadows", Float) = 1
       //透明通道预乘
	   [Toggle(_PREMULTIPLY_ALPHA)] _PremulAlpha("Premultiply Alpha", Float) = 0
       //金属度和光滑度
	   _Metallic("Metallic", Range(0, 1)) = 0
	   _Smoothness("Smoothness", Range(0, 1)) = 0.5
	   //设置混合模式
	  [Enum(UnityEngine.Rendering.BlendMode)] _SrcBlend("Src Blend", Float) = 1
	  [Enum(UnityEngine.Rendering.BlendMode)] _DstBlend("Dst Blend", Float) = 0
	  //默认写入深度缓冲区
	  [Enum(Off, 0, On, 1)] _ZWrite("Z Write", Float) = 1
    }
    SubShader
    {     

        Pass
        {
		   Tags {
				"LightMode" = "CustomLit"
			}

		   //定义混合模式
		   Blend[_SrcBlend][_DstBlend]
		   //是否写入深度
		   ZWrite[_ZWrite]
           HLSLPROGRAM
		   #pragma target 3.5
		   #pragma shader_feature _ _SHADOWS_CLIP _SHADOWS_DITHER
		   #pragma shader_feature _RECEIVE_SHADOWS
		   //是否透明通道预乘
		   #pragma shader_feature _PREMULTIPLY_ALPHA
		   #pragma multi_compile _ _DIRECTIONAL_PCF3 _DIRECTIONAL_PCF5 _DIRECTIONAL_PCF7
		   #pragma multi_compile _ _CASCADE_BLEND_SOFT _CASCADE_BLEND_DITHER
           #pragma multi_compile_instancing
           #pragma vertex LitPassVertex
           #pragma fragment LitPassFragment
		   //插入相关hlsl代码
           #include"LitPass.hlsl"
           ENDHLSL
        }

		Pass
        {
		   Tags {
				"LightMode" = "ShadowCaster"
			}
		    ColorMask 0

            HLSLPROGRAM
			#pragma target 3.5
			#pragma shader_feature _CLIPPING
			#pragma multi_compile_instancing
			#pragma vertex ShadowCasterPassVertex
			#pragma fragment ShadowCasterPassFragment
			#include "ShadowCasterPass.hlsl"
			ENDHLSL
        }
    }
		   CustomEditor "CustomShaderGUI"
}
