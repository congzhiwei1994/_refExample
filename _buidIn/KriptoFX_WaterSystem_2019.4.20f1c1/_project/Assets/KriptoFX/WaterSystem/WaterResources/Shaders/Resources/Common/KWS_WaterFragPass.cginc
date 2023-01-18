half4 frag(v2fWater i, float facing : VFACE) : SV_Target
{
	float2 uv = i.worldPos.xz / KW_FFTDomainSize;
	float2 screenUV = i.screenPos.xy / i.screenPos.w;

	float3 worldMeshNormal = GetWorldSpaceNormal(i.normal);
	float3 viewDir = GetWorldSpaceViewDirNorm(i.worldPosRefracted);
	
	//float surfaceDepthZ = GetSurfaceDepth(i.screenPos.z); //todo check why UNITY_Z_0_FAR_FROM_CLIPSPACE doesn't work with editor camera
	float surfaceDepthZ = i.screenPos.w;
	half surfaceMask = i.surfaceMask.x > 0.999;

	half3 fogColor;
	half3 fogOpacity;
	GetInternalFogVariables(i.pos, viewDir, surfaceDepthZ, i.screenPos.z, fogColor, fogOpacity);
	half exposure = GetExposure();
	
	float3 tangentNormal;

	//return float4(surfaceMask, i.surfaceMask.y, 0, 1);
	/////////////////////////////////////////////////////////////  NORMAL  ////////////////////////////////////////////////////////////////////////////////////////////////////////

	#if USE_FILTERING
		float normalFilteringMask;
		tangentNormal = GetFilteredNormal_lod0(uv, surfaceDepthZ, normalFilteringMask);
	#else
		tangentNormal = GetNormal_lod0(uv);
	#endif
	
	#ifdef USE_MULTIPLE_SIMULATIONS
		tangentNormal = GetNormal_lod1_lod2(i.worldPos, tangentNormal);
	#endif

	tangentNormal = normalize(tangentNormal);
	
	#if defined(KW_FLOW_MAP) || defined(KW_FLOW_MAP_EDIT_MODE)
		tangentNormal = GetFlowmapNormal(i.worldPos, uv, tangentNormal);
	#endif
	#if defined(KW_FLOW_MAP_FLUIDS) && !defined(KW_FLOW_MAP_EDIT_MODE)
		half fluidsFoam;
		tangentNormal = GetFluidsNormal(i.worldPos, uv, tangentNormal, fluidsFoam);
	#endif


	#ifdef KW_FLOW_MAP_EDIT_MODE
		return GetFlowmapEditor(i.worldPos, tangentNormal);
	#endif

	#if USE_SHORELINE
		tangentNormal = ComputeShorelineNormal(tangentNormal, i.worldPos, i.shorelineUVAnim1, i.shorelineUVAnim2, i.shorelineWaveData1, i.shorelineWaveData2);
	#endif

	
	#if KW_DYNAMIC_WAVES
		tangentNormal = GetDynamicWaves(i.worldPos, tangentNormal);
	#endif

	#if USE_FILTERING
		tangentNormal.xz *= normalFilteringMask;
	#endif

	tangentNormal = lerp(float3(0, 1, 0), tangentNormal, surfaceMask);
	float3 worldNormal = KWS_BlendNormals(tangentNormal, worldMeshNormal);
	/////////////////////////////////////////////////////////////  end normal  ////////////////////////////////////////////////////////////////////////////////////////////////////////
	

	float sceneZ = GetSceneDepth(screenUV);
	half surfaceTensionFade = GetSurfaceTension(sceneZ, i.screenPos.w);
	

	/////////////////////////////////////////////////////////////////////  REFRACTION  ///////////////////////////////////////////////////////////////////
	float2 refractionUV;

	#if defined(USE_REFRACTION_IOR)
		refractionUV = GetRefractedUV_IOR(viewDir, worldNormal, GetCameraRelativeWorldPos(i.worldPos), surfaceTensionFade);
	#else
		refractionUV = GetRefractedUV_Simple(screenUV, tangentNormal);
		refractionUV = lerp(screenUV, refractionUV, surfaceMask);
	#endif
	
	#if defined(USE_REFRACTION_DISPERSION)
		half3 refraction = GetSceneColorWithDispersion(refractionUV, KWS_RefractionDispersionStrength);
	#else
		half3 refraction = GetSceneColor(refractionUV);
	#endif
	/////////////////////////////////////////////////////////////  end refraction  ////////////////////////////////////////////////////////////////////////////////////////////////////////
	


	/////////////////////////////////////////////////////////////  REFLECTION  ////////////////////////////////////////////////////////////////////////////////////////////////////////
	half3 planarReflection = 0;
	half3 skyReflection = 0;
	half4 ssrReflection = 0;
	
	float3 reflDir = reflect(-viewDir, worldNormal);

	#if defined(PLANAR_REFLECTION) || defined(SSPR_REFLECTION)
		float2 refl_uv = GetScreenSpaceReflectionUV(worldNormal, viewDir, KWS_CameraProjectionMatrix);
	#endif

	#if PLANAR_REFLECTION
		planarReflection = GetPlanarReflectionWithClipOffset(refl_uv);
	#else
		skyReflection = GetCubemapReflection(reflDir);
		
		#if SSPR_REFLECTION
			ssrReflection = GetScreenSpaceReflectionWithStretchingMask(refl_uv);
		#endif

	#endif
	skyReflection *= exposure;
	planarReflection *= exposure;

	half3 finalReflection = 0;
	#if PLANAR_REFLECTION
		finalReflection = planarReflection;
	#else
		finalReflection = skyReflection;
	#endif
	
	finalReflection = ComputeInternalFog(finalReflection, fogColor, fogOpacity);
	finalReflection = lerp(finalReflection.xyz, ssrReflection.xyz, ssrReflection.a);
	finalReflection *= surfaceMask;
	/////////////////////////////////////////////////////////////  end reflection  ////////////////////////////////////////////////////////////////////////////////////////////////////////


	
	/////////////////////////////////////////////////////////////////////  UNDERWATER  ///////////////////////////////////////////////////////////////////
	#if USE_VOLUMETRIC_LIGHT
		half4 volumeScattering = GetVolumetricLight(refractionUV);
	#else
		half4 volumeScattering = half4(GetAmbientColor(), 1.0);
	#endif
	
	float depthAngleFix;
	
	float refractedSceneZ = GetSceneDepth(refractionUV);
	float fade = GetWaterRawFade(i.worldPos, surfaceDepthZ, refractedSceneZ, surfaceMask, depthAngleFix);
	FixAboveWaterRendering(refractionUV, refractedSceneZ, i.worldPos, sceneZ, surfaceDepthZ, depthAngleFix, screenUV, surfaceMask, fade, refraction, volumeScattering);
	
	half3 underwaterColor = ComputeUnderwaterColor(refraction.xyz, volumeScattering.rgb, fade, KW_Transparent, KW_WaterColor.xyz, KW_Turbidity, KW_TurbidityColor.xyz, fogOpacity, fogColor);

	#if defined(KW_FLOW_MAP_FLUIDS) && !defined(KW_FLOW_MAP_EDIT_MODE)
		underwaterColor = GetFluidsColor(underwaterColor, volumeScattering, fluidsFoam);
	#endif
	underwaterColor += ComputeSSS(screenUV, underwaterColor, volumeScattering.a > 0.5, KW_Transparent) * 2.5;
	/////////////////////////////////////////////////////////////  end underwater  ////////////////////////////////////////////////////////////////////////////////////////////////////////
	


	#if USE_SHORELINE
		finalReflection = ApplyShorelineWavesReflectionFix(reflDir, finalReflection, underwaterColor);
	#endif
	
	half waterFresnel = ComputeWaterFresnel(worldNormal, viewDir);
	waterFresnel *= surfaceMask;
	half3 finalColor = lerp(underwaterColor, finalReflection, waterFresnel);
	
	#if REFLECT_SUN
		half3 sunReflection = ComputeSunlight(worldNormal, viewDir, GetMainLightDir(), GetMainLightColor() * exposure, volumeScattering.a > 0.5, surfaceDepthZ, KW_WaterFarDistance, KW_Transparent);
		finalColor += sunReflection * (1 - fogOpacity);
	#endif
	
	finalColor = ComputeThirdPartyFog(finalColor, i.worldPos, screenUV, i.screenPos.z);
	
	return float4(finalColor, surfaceTensionFade);
}

half4 fragDepth(v2fDepth i, float facing : VFACE) : SV_Target
{
	//FragmentOutput o;
	float3 worldPos = i.worldPos_LocalHeight.xyz;
	float waveLocalHeight = i.worldPos_LocalHeight.w;
	float2 uv = worldPos.xz / KW_FFTDomainSize;
	
	half3 norm = KW_NormTex.Sample(sampler_linear_repeat, uv).xyz;
	half3 normScater = KW_NormTex.SampleLevel(sampler_linear_repeat, uv, 3).xyz;
	
	#ifdef USE_MULTIPLE_SIMULATIONS
		half3 normScater_lod1 = KW_NormTex_LOD1.SampleLevel(sampler_linear_repeat, worldPos.xz / KW_FFTDomainSize_LOD1, 2).xyz;
		half3 normScater_lod2 = KW_NormTex_LOD2.SampleLevel(sampler_linear_repeat, worldPos.xz / KW_FFTDomainSize_LOD2, 1).xyz;
		normScater = normalize(half3(normScater.xz + normScater_lod1.xz + normScater_lod2.xz, normScater.y * normScater_lod1.y * normScater_lod2.y)).xzy;

		half3 norm_lod1 = KW_NormTex_LOD1.Sample(sampler_linear_repeat, worldPos.xz / KW_FFTDomainSize_LOD1).xyz;
		half3 norm_lod2 = KW_NormTex_LOD2.Sample(sampler_linear_repeat, worldPos.xz / KW_FFTDomainSize_LOD2).xyz;
		norm = normalize(half3(norm.xz + norm_lod1.xz + norm_lod2.xz, norm.y * norm_lod1.y * norm_lod2.y)).xzy;
	#endif



	int idx;
	half sss = 0;
	half windLimit = clamp((KW_WindSpeed - 1), 0, 1);
	windLimit = lerp(windLimit, windLimit * 0.25, saturate(KW_WindSpeed / 15.0));

	float3 viewDir = GetWorldSpaceViewDirNorm(worldPos);
	float3 lightDir = GetMainLightDir();
	float distanceToCamera = 1-saturate(GetWorldToCameraDistance(worldPos) * 0.002);
	
	half zeroScattering = saturate(dot(viewDir, - (lightDir + float3(0, 1, 0))));

	float3 H = (lightDir + normScater * float3(-1, 1, -1));
	float scattering = pow(saturate(dot(viewDir, -H)), 3);
	sss += windLimit * (scattering - zeroScattering * 0.95);

	float surfaceMask = i.surfaceMask.x > 0.999;
	norm.xz *= surfaceMask;

	return half4(0.75 - facing * 0.25, saturate(scattering * waveLocalHeight * distanceToCamera * windLimit), norm.xz * 0.5 + 0.5);
}