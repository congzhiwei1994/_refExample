// Unity built-in shader source. Copyright (c) 2016 Unity Technologies. MIT license (see license.txt)

// Simplified Additive Particle shader. Differences from regular Additive Particle one:
// - no Tint color
// - no Smooth particle support
// - no AlphaTest
// - no ColorMask

Shader "Effect/Particles/Mobile/Additive" {
Properties {
    _MainTex ("Particle Texture", 2D) = "white" {}
	_BloomFactor("Bloom Factor", Range(0,0.9)) = 0
}

Category {
    Tags { "Queue"="Transparent" "IgnoreProjector"="True" "PreviewType"="Plane" "RenderType" = "Effect" }

    Cull Off Lighting Off ZWrite Off Fog { Mode Off }

    BindChannels {
        Bind "Color", color
        Bind "Vertex", vertex
        Bind "TexCoord", texcoord
    }

    SubShader {
        Pass 
		{
			Blend SrcAlpha One
			ColorMask RGB
            SetTexture [_MainTex] {
                combine texture * primary
            }
        }
	Pass
{
	ColorMask A
	Blend SrcAlpha  OneMinusSrcAlpha
	CGPROGRAM
#pragma vertex vert
#pragma fragment frag
#pragma fragmentoption ARB_precision_hint_fastest 
#include "UnityCG.cginc"
	sampler2D _MainTex;
half4 _MainTex_ST;
float _BloomFactor;

struct v2f {
	half4 pos : SV_POSITION;
	half2 uv : TEXCOORD0;
	fixed4 vertexColor : COLOR;
};

v2f vert(appdata_full v) {
	v2f o;

	o.pos = UnityObjectToClipPos(v.vertex);
	o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
	o.vertexColor = v.color;

	return o;
}

float4 frag(v2f i) : COLOR
{
	float4 color = tex2D(_MainTex, i.uv.xy);
	color.w = clamp(color.w * step(0.01, color.r + color.g + color.b) * _BloomFactor, 0, 1);
	color.w =  color.w * 0.5;
	return color;
}

ENDCG
}
    }
}
}
