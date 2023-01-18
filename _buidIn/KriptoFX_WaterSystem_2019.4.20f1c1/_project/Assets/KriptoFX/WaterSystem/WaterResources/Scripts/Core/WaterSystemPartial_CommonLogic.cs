using System;
using System.Threading.Tasks;
using UnityEngine;
using static KWS.KW_Extensions;
using static KWS.KWS_ShaderConstants;

namespace KWS
{
    public partial class WaterSystem
    {

        #region Initialization


        //If you press ctrl+z after deleting the water gameobject, unity returns all objects without links and save all objects until you close the editor. Not sure how to fix that =/ 
        void ClearUndoObjects(Transform parent)
        {
            if (parent.childCount > 0)
            {
                KW_Extensions.SafeDestroy(parent.GetChild(0).gameObject);
            }
        }

        GameObject CreateTempGameobject(string name, Transform parent)
        {
            ClearUndoObjects(parent);
#if KWS_DEBUG
            var tempGameObject = new GameObject(name) { hideFlags = HideFlags.DontSave };
#else
            var tempGameObject = new GameObject(name) { hideFlags = HideFlags.HideAndDontSave };
#endif
            tempGameObject.transform.parent = parent;
            tempGameObject.transform.localPosition = Vector3.zero;
            tempGameObject.transform.localRotation = new Quaternion();
            return tempGameObject;
        }

        GameObject InitializeWaterMeshGameObject(string name, Transform parent)
        {
            var go = new GameObject(name);
            go.hideFlags = HideFlags.DontSave;
            go.layer = KWS_Settings.Water.WaterLayer;
            go.transform.parent = parent;
            go.transform.localPosition = Vector3.zero;
            return go;
        }

        Mesh InitializeInfiniteMesh(int meshQuality, float domainSize, float meshSize)
        {
            int quadsPerStartSize = (meshQuality + 1) * 4;
            meshSize = Mathf.Max(100, meshSize);

            var currentWaterMesh  = KW_MeshGenerator.GenerateOceanPlane(domainSize * 2, quadsPerStartSize, meshSize);
            _lastInfiniteMeshSize = meshSize;
            return currentWaterMesh;
        }

        private float _InfiniteMeshUpdateTime;
        private float _InfiniteMeshUpdateEachTime = 2f;
        void CheckEditorCameraFarDistanceAndUpdateInfiniteMesh()
        {
            if (Application.isPlaying || _currentCamera.cameraType != CameraType.SceneView) return;

            _InfiniteMeshUpdateTime += KW_Extensions.DeltaTime();
            if (Math.Abs(_lastInfiniteMeshSize - _currentCamera.farClipPlane) > 1)
            {
                if (_InfiniteMeshUpdateTime > _InfiniteMeshUpdateEachTime)
                {
                    _InfiniteMeshUpdateTime = 0;

                    if (UseTesselation) WaterMesh = InitializeInfiniteMesh(KWS_Settings.Water.TesselationInfiniteMeshQuality, KWS_Settings.Water.TesselationMeshChunkSize, _currentCamera.farClipPlane);
                    else WaterMesh                = InitializeInfiniteMesh((int)InfiniteMeshQuality,                          KWS_Settings.Water.MeshChunkSize, _currentCamera.farClipPlane);

                    if (_waterMeshFilter != null) _waterMeshFilter.sharedMesh = WaterMesh;
                }
            }
        }


        public Mesh InitializeFiniteMesh(int meshQuality, Vector3 size)
        {
            int quadsPerStartSize = (meshQuality + 1) * 4;
            var currentWaterMesh = KW_MeshGenerator.GenerateFinitePlane(quadsPerStartSize, size);
            return currentWaterMesh;
        }

        public async Task<Mesh> InitializeRiverMesh()
        {
            await splineMesh.CreateMeshFromSpline(WaterGUID);
            return splineMesh.CurrentMesh;
        }

        public async void InitializeOrUpdateMesh()
        {
            if (WaterMesh != null && WaterMeshType != WaterMeshTypeEnum.CustomMesh && WaterMesh != CustomMesh) KW_Extensions.SafeDestroy(WaterMesh);

            if (WaterMeshType == WaterMeshTypeEnum.InfiniteOcean)
            {
                var mainCam = Camera.main;
                var meshSize =  mainCam != null ?  mainCam.farClipPlane : 2000;
                if (UseTesselation) WaterMesh = InitializeInfiniteMesh(KWS_Settings.Water.TesselationInfiniteMeshQuality, KWS_Settings.Water.TesselationMeshChunkSize, meshSize);
                else WaterMesh = InitializeInfiniteMesh((int) InfiniteMeshQuality, KWS_Settings.Water.MeshChunkSize, meshSize);
            }
            else if (WaterMeshType == WaterMeshTypeEnum.FiniteBox)
            {
                if (UseTesselation)
                {
                    var tessRange = KWS_Settings.Water.TesselationFiniteMeshQualityRange;
                    var sizeRange = Mathf.Clamp((MeshSize.x + MeshSize.z) / 2, 1, tessRange) / tessRange;
                    var meshQuality = Mathf.Lerp(KWS_Settings.Water.TesselationFiniteMeshQualityMin, KWS_Settings.Water.TesselationFiniteMeshQualityMax, sizeRange);
                    WaterMesh = InitializeFiniteMesh((int)meshQuality, MeshSize);
                }
                else WaterMesh = InitializeFiniteMesh((int)FiniteMeshQuality, MeshSize);
            }
            else if (WaterMeshType == WaterMeshTypeEnum.River) WaterMesh = await InitializeRiverMesh();
            else if (WaterMeshType == WaterMeshTypeEnum.CustomMesh) WaterMesh = CustomMesh;


            if (WaterMeshTransform != null) WaterMeshTransform.localPosition = Vector3.zero;
            if (_waterMeshFilter != null) _waterMeshFilter.sharedMesh = WaterMesh;
        }

        public void InitializeOrUpdateCustomMesh()
        {
            if (CustomMesh != null)
            {
                WaterMesh = CustomMesh;
                if (WaterMeshTransform != null) WaterMeshTransform.localPosition = Vector3.zero;
                if (_waterMeshFilter != null) _waterMeshFilter.sharedMesh = WaterMesh;
            }
        }

        public void UpdateInfiniteWaterMeshPosition(Camera cam, Transform waterMeshTransform)
        {
            if (cam != null && waterMeshTransform != null)
            {
                if (!IsCanRendererForCurrentCamera()) return;
                var pos = waterMeshTransform.position;
                var camPos = cam.transform.position;

                var relativeToCamPos = new Vector3(camPos.x, pos.y, camPos.z);
                if (Vector3.Distance(pos, relativeToCamPos) >= KWS_Settings.Water.UpdatePositionEveryMeters)
                {
                    waterMeshTransform.position = relativeToCamPos;
                }
            }
        }

        void InitializeWaterCommonResources()
        {
            if (_tempGameObject == null) _tempGameObject = CreateTempGameobject("TemporaryWaterResources", _waterTransform);

            waterSharedMaterials.Clear();

            WaterMeshGameObject = InitializeWaterMeshGameObject("WaterMesh", _tempGameObject.transform);
            WaterMeshTransform = WaterMeshGameObject.transform;
            WaterMeshTransform.rotation = new Quaternion();
            _waterMeshRenderer = WaterMeshGameObject.AddComponent<MeshRenderer>();
            _waterMeshFilter = WaterMeshGameObject.AddComponent<MeshFilter>();
            InitializeWaterMaterial(UseTesselation);
            InitializeOrUpdateMesh();

            isWaterCommonResourcesInitialized = true;

        }

        public void InitializeWaterMaterial(bool useTesselation)
        {
            RemoveMaterialFromWaterRendering(WaterMaterial);
            KW_Extensions.SafeDestroy(WaterMaterial);

            var currentWaterShaderName = (useTesselation && SystemInfo.graphicsShaderLevel >= 46) ? ShaderNames.WaterTesselatedShaderName : ShaderNames.WaterShaderName;
            WaterMaterial = KWS_CoreUtils.CreateMaterial(currentWaterShaderName);

            AddMaterialToWaterRendering(WaterMaterial);
            if (_waterMeshRenderer != null) _waterMeshRenderer.sharedMaterial = WaterMaterial;
        }

        #endregion

        #region Render Logic 

        bool IsWaterVisibleForCamera(Camera cam)
        {
            var planes = GeometryUtility.CalculateFrustumPlanes(cam);
            var bounds = WorldSpaceBounds;
            return GeometryUtility.TestPlanesAABB(planes, bounds);
        }

        void UpdateActiveWaterInstancesInfo()
        {
            if (IsWaterVisible == _lastWaterVisible) return;
            _lastWaterVisible = IsWaterVisible;

            if (IsWaterVisible)
            {
                if (!ActiveWaterInstances.Contains(this)) ActiveWaterInstances.Add(this);
            }
            else
            {
                if (ActiveWaterInstances.Contains(this)) ActiveWaterInstances.Remove(this);
            }
        }

        async void RenderWater()
        {
            if (_currentCamera == null) return;

            _waterTransform.localScale = Vector3.one;
            if(WaterMeshType == WaterMeshTypeEnum.InfiniteOcean) _waterTransform.localRotation = Quaternion.identity;
          
            if (!isWaterCommonResourcesInitialized) InitializeWaterCommonResources();
            if (!isWaterPlatformSpecificResourcesInitialized) InitializeWaterPlatformSpecificResources(); 

            var currentDeltaTime = KW_Extensions.DeltaTime();
            //if (currentDeltaTime < 0.0001f) return;
           
            RenderPlatformSpecificFeatures(_currentCamera);

            if (WaterMeshType == WaterMeshTypeEnum.InfiniteOcean)
            {
#if UNITY_EDITOR
                CheckEditorCameraFarDistanceAndUpdateInfiniteMesh();
#endif
                UpdateInfiniteWaterMeshPosition(_currentCamera, WaterMeshTransform);
            }

            RenderFFT();

            if (KW_WaterDynamicScripts.IsRequiredBuoyancyRendering() || EnableWaterSurfaceDataComputation) UpdateFFT_HeightData();
            else isBuoyancyDataReadCompleted = false;
            

            if (UseShorelineRendering)
            {
                if (shoreLineInitializingStatus == AsyncInitializingStatusEnum.NonInitialized)
                {
                    shoreLineInitializingStatus = AsyncInitializingStatusEnum.StartedInitialize;
                    RenderShorelineWavesWithFoam();
                }
                UpdateShorelineLods();
            }
            else if (shoreLineInitializingStatus == AsyncInitializingStatusEnum.Initialized)
            {
                shorelineWaves.Release();
                shoreLineInitializingStatus = AsyncInitializingStatusEnum.NonInitialized;
            }

            if (UseFlowMap)
            {
                if (flowmapInitializingStatus == AsyncInitializingStatusEnum.NonInitialized)
                {
                    flowmapInitializingStatus = AsyncInitializingStatusEnum.StartedInitialize;
                    ReadFlowMap();
                }
            }
            else if (flowmapInitializingStatus == AsyncInitializingStatusEnum.Initialized)
            {
                flowMap.Release();
                flowmapInitializingStatus = AsyncInitializingStatusEnum.NonInitialized;
            }

            if (UseFlowMap && UseFluidsSimulation && fluidsSimInitializingStatus == AsyncInitializingStatusEnum.NonInitialized)
            {
                fluidsSimInitializingStatus = AsyncInitializingStatusEnum.StartedInitialize;
                await ReadPrebakedFluidsSimulation();
            }


            if (UseFlowMap && UseFluidsSimulation)
            {
                if (fixedUpdateFluids == null) fixedUpdateFluids = new KW_CustomFixedUpdate(RenderFluidsSimulation, 1);
                fixedUpdateFluids.Update(currentDeltaTime, 1.0f / FluidsSimulationFPS);
            }
            else if (fluidsSimInitializingStatus == AsyncInitializingStatusEnum.Initialized)
            {
                fluidsSimulation.Release();
                fluidsSimInitializingStatus = AsyncInitializingStatusEnum.NonInitialized;
            }
            // else dynamicWaves.Release();

            if (fluidsSimInitializingStatus == AsyncInitializingStatusEnum.BakingStarted)
            {
                if (fixedUpdateBakingFluids == null) fixedUpdateBakingFluids = new KW_CustomFixedUpdate(BakeFluidSimulationFrame, 2);
                fixedUpdateBakingFluids.Update(currentDeltaTime, 1.0f / 60f);
            }

            if (UseDynamicWaves)
            {
                if (fixedUpdateDynamicWaves == null) fixedUpdateDynamicWaves = new KW_CustomFixedUpdate(RenderDynamicWaves, 2);
                fixedUpdateDynamicWaves.Update(currentDeltaTime, 1.0f / DynamicWavesSimulationFPS);
            }

            //_waterMeshRenderer.enabled = !UseOffscreenRendering;

            UpdateShaderParameters();
        }

        void RenderFFT()
        {
            var time = UseNetworkTime ? NetworkTime : KW_Extensions.TotalTime();

            time *= TimeScale;
            //time = 0.001f;
            var windDir = Mathf.Lerp(0.05f, 0.5f, WindTurbulence);
            int fftSize = (int)FFT_SimulationSize;
            var timeScaleRelativeToFFTSize = (Mathf.RoundToInt(Mathf.Log(fftSize, 2)) - 5) / 4.0f;


            float lod0_Time = Mathf.Lerp(time, time, WindTurbulence);
            lod0_Time = Mathf.Lerp(lod0_Time, lod0_Time * 0.6f, timeScaleRelativeToFFTSize);


            fft_lod0.ComputeFFT(FFT_GPU.LodPrefix.LOD0, fftSize, UseAnisotropicFiltering ? KWS_Settings.Water.MaxNormalsAnisoLevel : 0, KWS_Settings.Water.DomainSize, windDir, Mathf.Clamp(WindSpeed, 0, 2), WindRotation * Mathf.Deg2Rad, lod0_Time, waterSharedMaterials);

            UseMultipleSimulations = WindSpeed > 1.2f;

            if (UseMultipleSimulations)
            {
                isMultipleFFTSimInitialized = true;
                var fftSizeLod = (FFT_SimulationSize == FFT_GPU.SizeSetting.Size_512) ? 128 : 64;

                fft_lod1.ComputeFFT(FFT_GPU.LodPrefix.LOD1, fftSizeLod, 0, KWS_Settings.Water.DomainSize_LOD1, windDir, Mathf.Clamp(WindSpeed, 0, 6), WindRotation * Mathf.Deg2Rad, time * 0.9f, waterSharedMaterials);
                fft_lod2.ComputeFFT(FFT_GPU.LodPrefix.LOD2, fftSizeLod, 0, KWS_Settings.Water.DomainSize_LOD2, windDir, Mathf.Clamp(WindSpeed, 0, 40), WindRotation * Mathf.Deg2Rad, time * 0.4f, waterSharedMaterials);
            }
            else if (isMultipleFFTSimInitialized)
            {
                KW_Extensions.SafeDestroy(fft_lod1, fft_lod2);
                isMultipleFFTSimInitialized = false;
            }
        }

        void UpdateFFT_HeightData()
        {
            var heightDataSize = UseMultipleSimulations ? 256 : 64;
            fft_HeightData.UpdateHeightData(heightDataSize, UseMultipleSimulations ? KWS_Settings.Water.DomainSize_LOD2 : KWS_Settings.Water.DomainSize, transform.position.y);
        }

        void RenderFluidsSimulation()
        {
            if (fluidsSimInitializingStatus != AsyncInitializingStatusEnum.Initialized) return;
            if (!IsCanRendererForCurrentCamera()) return;

            fluidsSimulation.AddMaterialsToWaterRendering(waterSharedMaterials);

            for (int i = 0; i < FluidsSimulationIterrations; i++)
            {
                fluidsSimulation.RenderFluids(_currentCamera, transform.position, FluidsAreaSize, FluidsTextureSize, FluidsSpeed, FluidsFoamStrength, WaterGUID);
            }
        }

        public async void RenderShorelineWavesWithFoam()
        {
            var isInitialized = await shorelineWaves.RenderShorelineWavesWithFoam(ShorelineAreaSize, ShorelineAreaPosition, WaterGUID);
            shoreLineInitializingStatus = isInitialized ? AsyncInitializingStatusEnum.Initialized : AsyncInitializingStatusEnum.Failed;
        }

        void RenderDynamicWaves()
        {
            if (!IsCanRendererForCurrentCamera()) return;
            dynamicWaves.RenderWaves(_currentCamera, DynamicWavesSimulationFPS, DynamicWavesAreaSize, DynamicWavesResolutionPerMeter, DynamicWavesPropagationSpeed, UseDynamicWavesRainEffect ? DynamicWavesRainStrength : 0);
        }

        public void UpdateShaderParameters()
        {
#if KWS_DEBUG
            Shader.SetGlobalVector("Test4", Test4);
#endif

            Shader.SetGlobalFloat("KW_CameraRotation", _currentCamera.transform.eulerAngles.y / 360f);
            // print(currentCamera.transform.eulerAngles.y / 360f);
            Shader.SetGlobalFloat(WaterID.KW_Time, UseNetworkTime ? NetworkTime : KW_Extensions.TotalTime());
            Shader.SetGlobalFloat(WaterID.KW_GlobalTimeScale, TimeScale);
            Shader.SetGlobalFloat(WaterID.KWS_SunMaxValue, KWS_Settings.Reflection.MaxSunStrength);

            var currentTessFactor = 0f;
            if (UseTesselation)
            {
                if (WaterMeshType == WaterMeshTypeEnum.FiniteBox)
                {
                    var tessRange = KWS_Settings.Water.TesselationFiniteMeshQualityRange;
                    var sizeRange = Mathf.Clamp((MeshSize.x + MeshSize.z) / 2, 1, tessRange) / tessRange;
                    currentTessFactor = Mathf.Lerp(KWS_Settings.Water.MaxTesselationFactorFiniteMin, KWS_Settings.Water.MaxTesselationFactorFiniteMax, sizeRange);
                }
                else if (WaterMeshType == WaterMeshTypeEnum.InfiniteOcean)
                    currentTessFactor = KWS_Settings.Water.MaxTesselationFactorInfinite;
                else if (WaterMeshType == WaterMeshTypeEnum.River) currentTessFactor = KWS_Settings.Water.MaxTesselationFactorRiver;
                else currentTessFactor                                               = KWS_Settings.Water.MaxTesselationFactorOther;

                currentTessFactor *= TesselationFactor;
            }
           

            var maxTessCullDisplace = Mathf.Max(WindSpeed, 2);

            var fftSize = (int)FFT_SimulationSize;
            var normalLodScale = Mathf.RoundToInt(Mathf.Log(fftSize, 2)) - 4;
            var scatterLod = Mathf.Lerp(normalLodScale / 2.0f + 0.5f, normalLodScale / 2.0f + 1.5f, Mathf.Clamp01(WindSpeed / 3f));

            var cameraProjectionMatrix = _currentCamera.projectionMatrix;
            var projToView = GL.GetGPUProjectionMatrix(cameraProjectionMatrix, true).inverse;
            projToView[1, 1] *= -1;

            var viewProjection = _currentCamera.nonJitteredProjectionMatrix * _currentCamera.transform.worldToLocalMatrix;
            var viewToWorld = _currentCamera.cameraToWorldMatrix;

            var waterPos = transform.position;

            float fftSizeNormalized = (Mathf.RoundToInt(Mathf.Log((int)FFT_SimulationSize, 2)) - 5) / 4.0f;

            Shader.SetGlobalMatrix(WaterID.KW_ViewToWorld, viewToWorld);
            Shader.SetGlobalMatrix(WaterID.KW_ProjToView, projToView);
            Shader.SetGlobalMatrix(WaterID.KW_CameraMatrix, viewProjection);
            Shader.SetGlobalMatrix(WaterID.KWS_CameraProjectionMatrix, cameraProjectionMatrix);

            var matrix_V = GL.GetGPUProjectionMatrix(cameraProjectionMatrix, true);
            var maitix_P = _currentCamera.worldToCameraMatrix;
            var maitix_VP = matrix_V * maitix_P;

            Shader.SetGlobalMatrix("KWS_MATRIX_VP", maitix_VP);
            Shader.SetGlobalMatrix("KWS_MATRIX_I_VP", maitix_VP.inverse);


            float fluidsSpeed = FlowMapSpeed;
            if (UseFluidsSimulation && !FlowMapInEditMode) fluidsSpeed = FluidsSpeed * Mathf.Lerp(0.125f, 1.0f, FluidsSimulationIterrations / 4.0f);
            var isFlowmapUsed = UseFlowMap && !UseFluidsSimulation && (flowmapInitializingStatus == AsyncInitializingStatusEnum.Initialized || flowmapInitializingStatus == AsyncInitializingStatusEnum.BakingStarted);
            var isFlowmapFluidsUsed = UseFlowMap && UseFluidsSimulation && (fluidsSimInitializingStatus == AsyncInitializingStatusEnum.Initialized || fluidsSimInitializingStatus == AsyncInitializingStatusEnum.BakingStarted);
            var isShorelineUsed = UseShorelineRendering && shoreLineInitializingStatus == AsyncInitializingStatusEnum.Initialized;

            var dispersionStr = RefractionDispersionStrength * KWS_Settings.Water.MaxRefractionDispersion;
            var tessMaxDistance = WaterMeshType == WaterMeshTypeEnum.InfiniteOcean ? TesselationInfiniteMeshMaxDistance : TesselationOtherMeshMaxDistance;

            int isCustomMesh = WaterMeshType == WaterMeshTypeEnum.CustomMesh ? 1 : 0;

            foreach (var mat in waterSharedMaterials)
            {
                if (mat == null) continue;
                
                mat.SetMatrix(WaterID.KW_ViewToWorld, viewToWorld);
                mat.SetMatrix(WaterID.KW_ProjToView, projToView);
                mat.SetMatrix(WaterID.KW_CameraMatrix, viewProjection);

                mat.SetVector(WaterID.KW_WaterPosition, waterPos);

                mat.SetColor(WaterID.KW_TurbidityColor, TurbidityColor);
                mat.SetColor(WaterID.KW_WaterColor, WaterColor);

                mat.SetFloat(WaterID.KW_FFT_Size_Normalized, fftSizeNormalized);
                mat.SetFloat(WaterID.KW_WindSpeed, WindSpeed);
                mat.SetFloat(WaterID.KW_NormalScattering_Lod, scatterLod);
                mat.SetFloat(WaterID.KW_WaterFarDistance, _lastInfiniteMeshSize);
                mat.SetFloat(WaterID.KW_Transparent, Transparent);
                mat.SetFloat(WaterID.KW_Turbidity, Turbidity);
                mat.SetFloat(WaterID.KWS_SunCloudiness, ReflectedSunCloudinessStrength);
                mat.SetFloat(WaterID.KWS_SunStrength, ReflectedSunStrength);
                mat.SetFloat(WaterID.KWS_RefractionAproximatedDepth, RefractionAproximatedDepth);
                mat.SetFloat(WaterID.KWS_RefractionSimpleStrength, RefractionSimpleStrength);
                mat.SetFloat(WaterID.KWS_RefractionDispersionStrength, dispersionStr);
                mat.SetFloat(WaterID._TesselationFactor, currentTessFactor);
                mat.SetFloat(WaterID._TesselationMaxDistance, tessMaxDistance);
                mat.SetFloat(WaterID._TesselationMaxDisplace, maxTessCullDisplace);

                mat.SetFloat(WaterID.KW_ReflectionClipOffset, ReflectionClipPlaneOffset);
                if (isFlowmapFluidsUsed) mat.SetFloat(WaterID.KW_FlowMapFluidsStrength, FluidsFoamStrength);
                if (UseFlowMap)
                {
                    mat.SetFloat(WaterID.KW_FlowMapSize, FlowMapAreaSize);
                    mat.SetVector(WaterID.KW_FlowMapOffset, FlowMapAreaPosition);
                    mat.SetFloat(WaterID.KW_FlowMapSpeed, fluidsSpeed);
                }

                mat.SetKeyword(WaterKeywords.REFLECT_SUN, ReflectSun);
                mat.SetKeyword(WaterKeywords.USE_VOLUMETRIC_LIGHT, UseVolumetricLight);
                mat.SetKeyword(WaterKeywords.USE_CAUSTIC, UseCausticEffect);
                mat.SetKeyword(WaterKeywords.USE_MULTIPLE_SIMULATIONS, UseMultipleSimulations);
                mat.SetKeyword(WaterKeywords.KW_FLOW_MAP_EDIT_MODE, FlowMapInEditMode);
                mat.SetKeyword(WaterKeywords.KW_FLOW_MAP, isFlowmapUsed);
                mat.SetKeyword(WaterKeywords.KW_FLOW_MAP_FLUIDS, isFlowmapFluidsUsed);
                mat.SetKeyword(WaterKeywords.KW_DYNAMIC_WAVES, UseDynamicWaves);
                mat.SetKeyword(WaterKeywords.USE_SHORELINE, isShorelineUsed);
                mat.SetKeyword(WaterKeywords.PLANAR_REFLECTION, ReflectionMode == ReflectionModeEnum.PlanarReflection);
                mat.SetKeyword(WaterKeywords.SSPR_REFLECTION, ReflectionMode == ReflectionModeEnum.ScreenSpaceReflection);
                mat.SetKeyword(WaterKeywords.USE_FILTERING, UseFiltering);
                mat.SetKeyword(WaterKeywords.USE_REFRACTION_IOR, RefractionMode == RefractionModeEnum.PhysicalAproximationIOR);
                mat.SetKeyword(WaterKeywords.USE_REFRACTION_DISPERSION, UseRefractionDispersion);

                mat.SetInt(WaterID.KWS_IsCustomMesh, isCustomMesh);
            }

        }


        #endregion

        void ReleaseCommonResources()
        {
            if (_fft_lod0 != null) _fft_lod0.Release();
            if (_fft_lod1 != null) _fft_lod1.Release();
            if (_fft_lod2 != null) _fft_lod2.Release();
            if (_fft_HeightData != null) _fft_HeightData.Release();

            if (_shorelineWaves != null) _shorelineWaves.Release();
            if (_flowMap != null) _flowMap.Release();
            if (_fluidsSimulation != null) _fluidsSimulation.Release();
            if (_dynamicWaves != null) _dynamicWaves.Release();

            KW_Extensions.SafeDestroy(WaterMaterial);
            if (WaterMeshType != WaterMeshTypeEnum.CustomMesh) KW_Extensions.SafeDestroy(WaterMesh);
            KW_Extensions.SafeDestroy(WaterMeshGameObject);
            KW_Extensions.SafeDestroy(_tempGameObject);

            waterSharedMaterials.Clear();

            shoreLineInitializingStatus = AsyncInitializingStatusEnum.NonInitialized;
            flowmapInitializingStatus = AsyncInitializingStatusEnum.NonInitialized;
            fluidsSimInitializingStatus = AsyncInitializingStatusEnum.NonInitialized;

            isWaterCommonResourcesInitialized = false;
            Resources.UnloadUnusedAssets();
        }
    }

}