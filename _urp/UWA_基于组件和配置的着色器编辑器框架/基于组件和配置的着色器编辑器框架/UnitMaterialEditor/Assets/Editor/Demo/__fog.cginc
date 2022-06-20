	
uniform fixed _Fog_DensityBalance; // [-1, 1]

#if ( defined( FOG_LINEAR ) || defined( FOG_EXP ) || defined( FOG_EXP2 ) || defined( _FOG_SIMPLE ) || defined( _FOG_COMPLEX ) ) && !defined( _FOG_ON )
	#define _FOG_ON
#endif

#define _UNITY_FOG_LERP_COLOR( col, fogCol, fogFac ) col.rgb = lerp( ( fogCol ).rgb, ( col ).rgb, fogFac )

#ifdef _FOG_ON
	#define _FOG_COORDS_PACKED( n ) UNITY_FOG_COORDS_PACKED( n, float1 )
	#ifdef _FOG_DENSITY_BALANCE_ON
		#define _FOG_FACTOR saturate( saturate( unityFogFactor ) - _Fog_DensityBalance )
	#else
		#define _FOG_FACTOR saturate( unityFogFactor )
	#endif
	#if ( SHADER_TARGET < 30 ) || defined( SHADER_API_MOBILE )
		#define _UNITY_TRANSFER_FOG( o, outpos ) UNITY_CALC_FOG_FACTOR( ( outpos ).z ); o.fogCoord.x = _FOG_FACTOR
		#define _UNITY_APPLY_FOG_COLOR( coord, col, fogCol ) _UNITY_FOG_LERP_COLOR( col, fogCol, ( coord ).x )
	#else
		#define _UNITY_TRANSFER_FOG( o, outpos ) o.fogCoord.x = ( outpos ).z
		#define _UNITY_APPLY_FOG_COLOR( coord, col, fogCol ) UNITY_CALC_FOG_FACTOR( ( coord ).x ); _UNITY_FOG_LERP_COLOR( col, fogCol, _FOG_FACTOR )
	#endif
#else
	#define _FOG_COORDS_PACKED( n )
	#define _UNITY_FOG_COORDS( idx )
	#define _UNITY_TRANSFER_FOG( o, outpos )
	#define _UNITY_APPLY_FOG_COLOR( coord, col, fogCol )
#endif

// 叠加混合模式下，注意不要额外叠加多余的雾色，这种情况下，越远处的物体渲染输出的颜色倾向于0
#if defined( UNITY_PASS_FORWARDADD ) || defined( _BLEND_ADDITIVE_SERIES )
	#define _UNITY_APPLY_FOG( coord, col ) _UNITY_APPLY_FOG_COLOR( coord, col, fixed4( 0, 0, 0, 0 ) )
#else
	#define _UNITY_APPLY_FOG( coord, col ) _UNITY_APPLY_FOG_COLOR( coord, col, unity_FogColor )
#endif

#if defined( _FOG_ON )
	#define _TRANSFER_FOG( o,  projPos ) _UNITY_TRANSFER_FOG( o, projPos )
	#define _APPLY_FOG( fogCoord, color ) _UNITY_APPLY_FOG( fogCoord, color )
#else
	#define _TRANSFER_FOG( o, projPos )
	#define _APPLY_FOG( fogCoord, color )
#endif
