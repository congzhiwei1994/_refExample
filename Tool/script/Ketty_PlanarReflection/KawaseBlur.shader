Shader "Hidden/KawaseBlur"
{
	Properties
    {
        _MainTex("", 2D) = "white" {}
    }

    CGINCLUDE

    #include "UnityCG.cginc"

    sampler2D _MainTex;
    float4 _MainTex_TexelSize;

	uniform half _Offset;
	
	half4 KawaseBlur(float2 uv, half pixelOffset)
	{
		half4 o = 0;
		o += tex2D(_MainTex, uv + float2(pixelOffset +0.5, pixelOffset +0.5) * _MainTex_TexelSize.xy); 
		o += tex2D(_MainTex, uv + float2(-pixelOffset -0.5, pixelOffset +0.5) * _MainTex_TexelSize.xy); 
		o += tex2D(_MainTex, uv + float2(-pixelOffset -0.5, -pixelOffset -0.5) * _MainTex_TexelSize.xy); 
		o += tex2D(_MainTex, uv + float2(pixelOffset +0.5, -pixelOffset -0.5) * _MainTex_TexelSize.xy); 
		return o * 0.25;
	}
			
	half4 Frag(v2f_img i): SV_Target
	{
		return KawaseBlur(i.uv,_Offset);
	}
    ENDCG

	SubShader
	{	
		Pass
		{
			Cull Off ZWrite Off ZTest Always
			CGPROGRAM
			#pragma vertex vert_img
			#pragma fragment Frag
			ENDCG
		}
	}
}


