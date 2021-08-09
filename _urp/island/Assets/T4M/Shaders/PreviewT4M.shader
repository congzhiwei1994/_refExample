Shader "Hidden/PreviewT4M" 
{
	Properties 
	{ 
		_Transp ("Transparency", Range(0,1)) = 1
		_MainTex ("Texture", 2D) = "" {}
		_MaskTex ("Mask (RGB) Trans (A)", 2D) = ""{ TexGen ObjectLinear }
	}
	SubShader 
	{
		Pass 
		{
			Blend SrcAlpha OneMinusSrcAlpha  
			SetTexture [_MainTex]  
			SetTexture [_MaskTex] 
			{
				constantColor (1,1,1,[_Transp]) 
				combine previous , texture* constant
				Matrix [_Projector]
			}
		}
	}
}