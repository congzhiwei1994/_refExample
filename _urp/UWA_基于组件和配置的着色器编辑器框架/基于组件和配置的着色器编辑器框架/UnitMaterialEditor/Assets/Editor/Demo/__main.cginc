#include "UnityCG.cginc"

sampler2D _MainTex;
sampler2D _MainTex_Alpha;

fixed _Cutoff;
fixed4 _ColorKey;

fixed4 _Color;
fixed4 _Color2;
#if _CURRENT_COLOR_INDEX == 2
	#define _CURRENT_COLOR _Color2
#else
	#define _CURRENT_COLOR _Color
#endif

float3 _RimLightColor;
float _RimLightPower;
float _RimLightScale;

#include "__fog.cginc"

struct VertexInput {
	float4 vertex : POSITION;
	float3 normal : NORMAL;
#ifndef _VERTEXCOLORTINT_OFF
	float4 vertexColor : Color;
#endif
	float2 texcoord : TEXCOORD0;
};

struct VertexOutput {
	float4 pos : SV_POSITION;
	float2 uv : TEXCOORD0;
#ifdef _RIMLIGHT_ON
	float4 posWorld : TEXCOORD1;
	float3 normalDir : TEXCOORD2;
#endif
#if defined( _DOUBLECOLORTINT_ON ) || !defined( _VERTEXCOLORTINT_OFF )
	float4 color : TEXCOORD3;
#endif
	_FOG_COORDS_PACKED( 4 )
};

VertexOutput vert( VertexInput v ) {
	VertexOutput o = ( VertexOutput )0;
	o.uv = v.texcoord;
	o.pos = UnityObjectToClipPos( v.vertex );

#ifdef _RIMLIGHT_ON
	o.normalDir = UnityObjectToWorldNormal( v.normal );
	#ifdef _BACKFACE_RENDERING_ON
		o.normalDir = -o.normalDir;
	#endif
	o.posWorld = mul( unity_ObjectToWorld, v.vertex );
#endif

#if defined( _DOUBLECOLORTINT_ON ) || !defined( _VERTEXCOLORTINT_OFF )
	o.color = _CURRENT_COLOR;
#ifdef _DOUBLECOLORTINT_ON
	o.color.rgb *= 2;
#endif
#ifndef _VERTEXCOLORTINT_OFF
	o.color *= v.vertexColor;
#endif
#endif

	_TRANSFER_FOG( o, o.pos );
	return o;
}

inline void AlphaCutoff( fixed4 color ) {
#ifdef _ALPHATEST_ON
	clip( color.a - _Cutoff );
#endif
#ifdef _ALPHATEST_COLOR_KEY_ON
	fixed3 ckeyDir = color.rgb - _ColorKey;
	clip( dot( ckeyDir, ckeyDir ) - _ColorKey.a );
#endif
}

float4 frag( VertexOutput i ) : COLOR{
	float4 outColor = tex2D( _MainTex, i.uv );
	#if defined( _DOUBLECOLORTINT_ON ) || !defined( _VERTEXCOLORTINT_OFF )
		outColor *= i.color;
	#else
		outColor *= _CURRENT_COLOR;
	#endif
	#ifdef _USE_EXTERNAL_ALPHA
		outColor.a *= tex2D( _MainTex_Alpha, i.uv ).r;
	#endif

	AlphaCutoff( outColor );

	#ifdef _RIMLIGHT_ON
		float3 worldNormal = normalize( i.normalDir );
		float3 viewDirection = normalize( _WorldSpaceCameraPos.xyz - i.posWorld.xyz );
		//计算视线方向与法线方向的夹角，夹角越大，dot值越接近0，说明视线方向越偏离该点，也就是平视，该点越接近边缘
		float rim = 1 - max( 0, dot( viewDirection, worldNormal ) );
		float3 rimColor = _RimLightColor * ( pow( rim, _RimLightPower ) * 4 );
		outColor.rgb += rimColor * _RimLightScale;
	#endif

	_APPLY_FOG( i.fogCoord, outColor );
	return outColor;
}
//EOF
