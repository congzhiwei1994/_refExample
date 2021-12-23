float Dither32(float2 Pos) {
    float Ret = dot( float3(Pos.xy, 0.5f), float3(0.40625f, 0.15625f, 0.46875f ) );
    return frac(Ret);
}

void CameraFade_float(
//  Base inputs
    float4 positionSS,
    float3 positionWS,
    float  CameraInversFadeRange,
    float  CameraFadeDist,
    half  AlphaIN,

    out half Alpha

) {
	
    float dither = Dither32(positionSS.xy / positionSS.w * _ScreenParams.xy );
//  URP 10.1: We have to somehow identify the shadowcaster pass.
//  float4x4 projection = GetViewToHClipMatrix(); //UNITY_MATRIX_P;
//  projection._m11 = -1 * projection._m00!
//  We use a little threshold here
    //if( (projection._m00 + projection._m11) < 0.001 )  {
//  URP 10.2
    #if (SHADERPASS == SHADERPASS_SHADOWCASTER)
        #if defined(FADESHADOWS_ON)
            float distanceToCam = distance(positionWS, GetCameraPositionWS() );
            Alpha = AlphaIN * saturate( (distanceToCam - CameraFadeDist) * CameraInversFadeRange - dither );
        #else
            Alpha = AlphaIN;
        #endif
    #else
        Alpha = AlphaIN * saturate( (positionSS.w - CameraFadeDist) * CameraInversFadeRange - dither );
    #endif
}