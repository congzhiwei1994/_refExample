Shader "ImageEffect/BloomEffect" {

	Properties
	{
		_MainTex("Base (RGB)", 2D) = "white" {}
		_BlurTex("Blur", 2D) = "white"{}
	}

	CGINCLUDE
	#include "UnityCG.cginc"

	//用于阈值提取高亮部分
	struct v2f_Mask
	{
		fixed4 pos : SV_POSITION;
		fixed2 uv : TEXCOORD0;
	};

	//用于阈值提取高亮部分
	struct v2f_threshold
	{
		fixed4 pos : SV_POSITION;
		fixed2 uv : TEXCOORD0;
	};

	//用于blur
	struct v2f_blur
	{
		fixed4 pos : SV_POSITION;
		half2 uv  : TEXCOORD0;
		fixed4 texcoord : TEXCOORD1;
	};

	//用于bloom
	struct v2f_bloom
	{
		float4 pos : SV_POSITION;
		float2 uv  : TEXCOORD0;
		float2 uv1 : TEXCOORD1;
	};

	sampler2D _MainTex;
	fixed4 _MainTex_TexelSize;
	sampler2D _BlurTex;
	sampler2D DisTex;
	fixed _samplerScale;
	fixed4 _colorThreshold;
	fixed4 _bloomColor;
	fixed _bloomFactor;
	fixed4 _BattleEffectColor;

	sampler2D _BlurTexTemp;

	v2f_Mask vert_Addblur(appdata_img v)
	{
		v2f_Mask o;
		o.pos = UnityObjectToClipPos(v.vertex);
		o.uv = v.texcoord.xy;
#if UNITY_UV_STARTS_AT_TOP
		if (_MainTex_TexelSize.y < 0)
			o.uv.y = 1 - o.uv.y;
#endif	
		return o;
	}

	fixed4 frag_Addblur(v2f_Mask i) : SV_Target
	{
		fixed4 color = tex2D(_MainTex, i.uv);
		fixed4 color2 = tex2D(_BlurTexTemp, i.uv);
		return (fixed4(color.rgb, 0.4) + fixed4(color2.rgb, 0.6));
	}

	//高亮部分提取shader
	v2f_threshold vert_threshold(appdata_img v)
	{
		v2f_threshold o;
		o.pos = UnityObjectToClipPos(v.vertex);
		o.uv = v.texcoord.xy;
		//dx中纹理从左上角为初始坐标，需要反向
#if UNITY_UV_STARTS_AT_TOP
		if (_MainTex_TexelSize.y < 0)
			o.uv.y = 1 - o.uv.y;
#endif	
		return o;
	}

	fixed4 frag_threshold(v2f_threshold i) : SV_Target
	{
		fixed4 color = tex2D(_MainTex, i.uv);

		float alpha = color.a;

		color.rgb = color.rgb * (1-alpha) * 3;
		//仅当color大于设置的阈值的时候才输出
		return saturate(color - _colorThreshold);
	}

	v2f_blur vert_blur(appdata_img v)
	{
		v2f_blur o;
		o.pos = UnityObjectToClipPos(v.vertex);
		o.uv = v.texcoord.xy;
		o.texcoord = v.texcoord.xyxy;


		return o;
	}

	fixed4 CalBlur(v2f_blur i, fixed4 offsets)
	{
		offsets *= _MainTex_TexelSize.xyxy;
		fixed4 uv01 = i.texcoord + offsets.xyxy * fixed4(1, 1, -1, -1);
		fixed4 uv23 = i.texcoord + offsets.xyxy * fixed4(1, 1, -1, -1) * 2.0;
		fixed4 uv45 = i.texcoord + offsets.xyxy * fixed4(1, 1, -1, -1) * 3.0;
		fixed4 color = fixed4(0, 0, 0, 0);
		color += 0.40 * tex2D(_MainTex, i.uv);
		color += 0.15 * tex2D(_MainTex, uv01.xy);
		color += 0.15 * tex2D(_MainTex, uv01.zw);
		color += 0.10 * tex2D(_MainTex, uv23.xy);
		color += 0.10 * tex2D(_MainTex, uv23.zw);
		color += 0.05 * tex2D(_MainTex, uv45.xy);
		color += 0.05 * tex2D(_MainTex, uv45.zw);
		return color;
	}

	fixed4 frag_blur(v2f_blur i) : SV_Target
	{
		return CalBlur(i, fixed4(_samplerScale,0,0,0))*0.5 + CalBlur(i, fixed4(0, _samplerScale, 0, 0))*0.5;;
	}

	//Bloom效果 vertex shader
	v2f_bloom vert_bloom(appdata_img v)
	{
		v2f_bloom o;
		//mvp矩阵变换
		o.pos = UnityObjectToClipPos(v.vertex);
		//uv坐标传递
		o.uv.xy = v.texcoord.xy;
		o.uv1.xy = o.uv.xy;
#if UNITY_UV_STARTS_AT_TOP
		if (_MainTex_TexelSize.y < 0)
			o.uv.y = 1 - o.uv.y;
#endif	
		return o;
	}

	fixed4 frag_bloom(v2f_bloom i) : SV_Target
	{
		//取原始清晰图片进行uv采样
		fixed4 ori = tex2D(_MainTex, i.uv1);
		//取模糊普片进行uv采样
		fixed4 blur = tex2D(_BlurTex, i.uv);
		//输出= 原始图像，叠加bloom权值*bloom颜色*泛光颜色
		fixed a = step(0, ori.a);
		fixed4 final = ori + _bloomFactor * blur * _bloomColor * a;// -(1 - temp)*0.3;
		return final;
	}

	ENDCG

	SubShader
	{
		//pass 0: 提取高亮部分
		Pass
		{
			ZTest Off
			Cull Off
			ZWrite Off
			Fog{ Mode Off }

			CGPROGRAM
#pragma vertex vert_threshold
#pragma fragment frag_threshold
			ENDCG
		}

		//pass 1: 高斯模糊
		Pass
		{
			ZTest Off
			Cull Off
			ZWrite Off
			Fog{ Mode Off }

			CGPROGRAM
#pragma vertex vert_blur
#pragma fragment frag_blur
			ENDCG
		}

		//pass 2: Bloom效果
		Pass
		{

			ZTest Off
			Cull Off
			ZWrite Off
			Fog{ Mode Off }

			CGPROGRAM
#pragma vertex vert_bloom
#pragma fragment frag_bloom
			ENDCG
		}

		//pass 3 模糊图叠加
		Pass
		{
			ZTest Off
			Cull Off
			ZWrite Off
			Fog{ Mode Off }
			Blend SrcAlpha OneMinusSrcAlpha
			CGPROGRAM
#pragma vertex vert_Addblur
#pragma fragment frag_Addblur
			ENDCG
		}
	}
}
