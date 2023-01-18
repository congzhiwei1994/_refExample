using System;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Profiling;
#if UNITY_EDITOR
using UnityEditor;

#endif

namespace KWS
{
    [ExecuteAlways]
    [Serializable]
    public partial class WaterSystem : MonoBehaviour
    {
        //todo add KWS_STANDARD/KWS_HDRP/KWS_URP

        #region public variables

        //Color settings
        public bool ShowColorSettings = true;
        public bool ShowExpertColorSettings = false;
        public float Transparent = 5;
        public Color WaterColor = new Color(175 / 255.0f, 225 / 255.0f, 240 / 255.0f);
        public Color TurbidityColor = new Color(10 / 255.0f, 110 / 255.0f, 100 / 255.0f);
        public float Turbidity = 0.25f;


        //Waves settings
        public bool ShowWaves = true;
        public bool ShowExpertWavesSettings = false;
        public FFT_GPU.SizeSetting FFT_SimulationSize = FFT_GPU.SizeSetting.Size_256;
        public bool UseMultipleSimulations = false;
        public float WindSpeed = 1.0f;
        public float WindRotation = 0;
        public float WindTurbulence = 0.75f;
        public float TimeScale = 1;


        //Reflection settings
        public WaterProfileEnum ReflectionProfile = WaterProfileEnum.High;
        public bool ShowReflectionSettings = false;
        public bool ShowExpertReflectionSettings = false;
        public ReflectionModeEnum ReflectionMode = ReflectionModeEnum.ScreenSpaceReflection;
        public float CubemapUpdateInterval = 6;
        public int CubemapCullingMask = KWS_Settings.Water.DefaultCubemapCullingMask;
        public CubemapReflectionResolutionQualityEnum CubemapReflectionResolutionQuality = CubemapReflectionResolutionQualityEnum.Medium;
        public PlanarReflectionResolutionQualityEnum PlanarReflectionResolutionQuality = PlanarReflectionResolutionQualityEnum.Medium;
        public ScreenSpaceReflectionResolutionQualityEnum ScreenSpaceReflectionResolutionQuality = ScreenSpaceReflectionResolutionQualityEnum.High;
        public bool UsePlanarCubemapReflection = true;
        //public ReflectionClearFlagEnum ReflectionClearFlag = ReflectionClearFlagEnum.Skybox;
        //public Color ReflectionClearColor = Color.black;
        public float ReflectionClipPlaneOffset = 0.0075f;
        public int ReflectioDepthHolesFillDistance = 3;

        public bool UseAnisotropicReflections = true;
        public bool AnisotropicReflectionsHighQuality = false;
        public float AnisotropicReflectionsScale = 0.75f;

        public bool ReflectSun = true;
        public float ReflectedSunCloudinessStrength = 0.04f;
        public float ReflectedSunStrength = 1.0f;

        //Refraction settings
        public WaterProfileEnum RefractionProfile = WaterProfileEnum.High;
        public bool ShowRefractionSettings = false;
        public bool ShowExpertRefractionSettings = false;
        public RefractionModeEnum RefractionMode = RefractionModeEnum.PhysicalAproximationIOR;
        public float RefractionAproximatedDepth = 2f;
        public float RefractionSimpleStrength = 0.25f;
        public bool UseRefractionDispersion = true;
        public float RefractionDispersionStrength = 0.35f;

        //Volumetric settings
        public WaterProfileEnum VolumetricLightProfile = WaterProfileEnum.High;
        public bool UseVolumetricLight = true;
        public bool ShowVolumetricLightSettings = false;
        public bool ShowExpertVolumetricLightSettings = false;
        public VolumetricLightResolutionQualityEnum VolumetricLightResolutionQuality = VolumetricLightResolutionQualityEnum.High;
        public int VolumetricLightIteration = 6;
        public float VolumetricLightBlurRadius = 2.0f;
        public VolumetricLightFilterEnum VolumetricLightFilter = VolumetricLightFilterEnum.Bilateral;


        //FlowMap settings
        public WaterProfileEnum FlowmapProfile = WaterProfileEnum.High;
        public bool UseFlowMap = false;
        public bool ShowFlowMap = false;
        public bool ShowExpertFlowmapSettings = false;
        public bool FlowMapInEditMode = false;
        public Vector3 FlowMapAreaPosition = new Vector3(0, 0, 0);
        public int FlowMapAreaSize = 200;
        public FlowmapTextureResolutionEnum FlowMapTextureResolution = FlowmapTextureResolutionEnum._2048;
        public float FlowMapBrushStrength = 0.75f;
        public float FlowMapSpeed = 1;

        public bool UseFluidsSimulation = false;
        public int FluidsAreaSize = 40;
        public int FluidsSimulationIterrations = 2;
        public int FluidsTextureSize = 1024;
        public int FluidsSimulationFPS = 60;
        public float FluidsSpeed = 1;
        public float FluidsFoamStrength = 0.5f;


        //Dynamic waves settings
        public WaterProfileEnum DynamicWavesProfile = WaterProfileEnum.High;
        public bool UseDynamicWaves = false;
        public bool ShowDynamicWaves = false;
        public bool ShowExpertDynamicWavesSettings = false;
        public int DynamicWavesAreaSize = 25;
        public int DynamicWavesSimulationFPS = 60;
        public int DynamicWavesResolutionPerMeter = 40;
        public float DynamicWavesPropagationSpeed = 1.0f;
        public bool UseDynamicWavesRainEffect;
        public float DynamicWavesRainStrength = 0.2f;


        //Shoreline settings
        public WaterProfileEnum ShorelineProfile = WaterProfileEnum.High;
        public bool UseShorelineRendering = false;
        public bool ShowShorelineMap = false;
        public bool ShowExpertShorelineSettings = false;
        public QualityEnum FoamLodQuality = QualityEnum.Medium;
        public bool FoamCastShadows = true;
        public bool FoamReceiveShadows = false;
        public bool ShorelineInEditMode = false;
        public Vector3 ShorelineAreaPosition;
        public int ShorelineAreaSize = 512;
        public QualityEnum ShorelineCurvedSurfacesQuality = QualityEnum.Medium;


        //Caustic settings
        public WaterProfileEnum CausticProfile = WaterProfileEnum.High;
        public bool UseCausticEffect = true;
        public bool ShowCausticEffectSettings = false;
        public bool ShowExpertCausticEffectSettings = false;
        public bool UseCausticBicubicInterpolation = true;
        public bool UseCausticDispersion = true;
        public int CausticTextureSize = 768;
        public int CausticMeshResolution = 320;
        public int CausticActiveLods = 3;
        public float CausticStrength = 1;
        public bool UseDepthCausticScale = false;
        public bool CausticDepthScaleInEditMode = false;
        public float CausticDepthScale = 1;
        public Vector3 CausticOrthoDepthPosition = Vector3.positiveInfinity;
        public int CausticOrthoDepthAreaSize = 512;
        public int CausticOrthoDepthTextureResolution = 2048;


        //Underwater settings
        public bool UseUnderwaterEffect = true;
        public bool ShowUnderwaterEffectSettings = false;
        public bool UseUnderwaterBlur = false;
        public float UnderwaterBlurRadius = 1.5f;

        //Mesh settings
        public WaterProfileEnum MeshProfile = WaterProfileEnum.High;
        public bool ShowMeshSettings = false;
        public bool ShowExpertMeshSettings = false;
        public bool SplineMeshInEditMode = false;
        public WaterMeshTypeEnum WaterMeshType;
        public float RiverSplineNormalOffset = 1;
        public int RiverSplineVertexCountBetweenPoints = 20;
        public Mesh              CustomMesh;
        public WaterInfiniteMeshQualityEnum  InfiniteMeshQuality = WaterInfiniteMeshQualityEnum._100k;
        public WaterFiniteMeshQualityEnum FiniteMeshQuality = WaterFiniteMeshQualityEnum._50k;
        public Vector3 MeshSize               = new Vector3(10, 10, 10);
        public bool    UseTesselation         = true;
        public float   TesselationFactor      = 0.6f;
        public float TesselationInfiniteMeshMaxDistance = 2000f;
        public float TesselationOtherMeshMaxDistance = 200f;

        //Rendering settings
        public WaterProfileEnum RenderingProfile = WaterProfileEnum.High;
        public bool ShowRendering = false;
        public bool ShowExpertRenderingSettings = false;
        public bool UseFiltering = true;
        public bool UseAnisotropicFiltering = false;
        //public bool UseOffscreenRendering;
        //public AntialiasingEnum OffscreenRenderingAntialiasing = AntialiasingEnum.None;
        //public OffscreenResolutionQualityEnum OffscreenResolutionQuality = OffscreenResolutionQualityEnum.High;
        public bool DrawToPosteffectsDepth;

        internal static int SelectedThirdPartyFogMethod = -1;
        public class ThirdPartyAssetDescription
        {
            public string EditorName;
            public string ShaderDefine;
            public string ShaderInclude;
            public bool   DrawToDepth;
            public bool OverrideQueue;
            public int  CustomQueue;
        }

        #endregion

        #region public enums

        public enum WaterProfileEnum
        {
            Custom,
            Ultra,
            High,
            Medium,
            Low,
            PotatoPC
        }

        public enum QualityEnum
        {
            High = 0,
            Medium = 1,
            Low = 2,
        }

        public enum ReflectionModeEnum
        {
            CubemapReflection,
            PlanarReflection,
            ScreenSpaceReflection,
        }

        public enum PlanarReflectionResolutionQualityEnum
        {
            Ultra = 768,
            High = 512,
            Medium = 368,
            Low = 256,
            VeryLow = 128,
        }

        /// <summary>
        /// Resolution quality in percent relative to current screen size. For example Medium quality = 35, it's mean ScreenSize * (35 / 100)
        /// </summary>
        public enum ScreenSpaceReflectionResolutionQualityEnum
        {
            Ultra = 75,
            High = 50,
            Medium = 35,
            Low = 25,
            VeryLow = 20,
        }

        public enum CubemapReflectionResolutionQualityEnum
        {
            High = 512,
            Medium = 256,
            Low = 128,
        }

        public enum ReflectionClearFlagEnum
        {
            Skybox,
            Color,
        }


        public enum RefractionModeEnum
        {
            Simple,
            PhysicalAproximationIOR
        }

        public enum FoamShadowMode
        {
            None,
            CastOnly,
            CastAndReceive
        }

        public enum WaterMeshTypeEnum
        {
            InfiniteOcean,
            FiniteBox,
            River,
            CustomMesh
        }

        public enum WaterFiniteMeshQualityEnum
        {
            //_300k   = 100,
            //_200k    = 77,
            _100k  = 54,
            _50k     = 37,
            _25k = 26,
            _10k = 16,
            _5k = 10,
            _1k = 2,
        }

        public enum WaterInfiniteMeshQualityEnum
        {
            //_2_million = 96,
            //_1_million = 68,
            //_750k = 58,
            //_500k  = 47,
            _250k  = 33,
            _100k  = 21,
            _25k   = 10,
            _10k = 5,
        }

        public enum AntialiasingEnum
        {
            None = 1,
            MSAA2x = 2,
            MSAA4x = 4,
            //MSAA8x = 8
        }

        public enum VolumetricLightFilterEnum
        {
            Bilateral,
            Gaussian
        }

        public enum VolumetricLightResolutionQualityEnum
        {
            Ultra = 75,
            High = 50,
            Medium = 35,
            Low = 25,
            VeryLow = 15,
        }

        public enum FlowmapTextureResolutionEnum
        {
            _512 = 512,
            _1024 = 1024,
            _2048 = 2048,
            _4096 = 4096,
        }

        public enum OffscreenResolutionQualityEnum
        {
            Ultra = 100,
            High = 85,
            Medium = 75,
            Low = 60,
            VeryLow = 50,
        }


        #endregion

        #region public API methods

        public event Action OnWaterRelease;

        /// <summary>
        /// World space bounds of the rendered mesh (relative to the wind speed).
        /// </summary>
        /// <returns></returns>
        public Bounds WorldSpaceBounds
        {
            get
            {
                if(_waterMeshRenderer == null) return new Bounds(_waterTransform.position, Vector3.one);

                var bounds = _waterMeshRenderer.bounds;
                var currentHeight = CurrentMaxWaveHeight;
                bounds.size += new Vector3(0, currentHeight, 1);
                return bounds;
            } 
        }

        /// <summary>
        /// Enable this setting to get WaterSurfaceData
        /// </summary>
        public bool EnableWaterSurfaceDataComputation;

        /// <summary>
        /// Get world space water position/normal at point. Used for water physics. You need to enable EnableWaterSurfaceDataComputation! 
        /// </summary>
        /// <param name="worldPosition"></param>
        /// <returns></returns>
        public KW_WaterSurfaceData GetWaterSurfaceData(Vector3 worldPosition)
        {
            if (!isWaterCommonResourcesInitialized || !isBuoyancyDataReadCompleted) return new KW_WaterSurfaceData { IsActualDataReady = false, Position = worldPosition, Normal = Vector3.up };
            return fft_HeightData.GetWaterSurfaceData(worldPosition);
        }

        /// <summary>
        /// Activate this option if you want to manually synchronize the time for all clients over the network
        /// </summary>
        public bool UseNetworkTime;

        public float NetworkTime;

        #endregion

        #region internal variables

        public string WaterGUID
        {
            get
            {
#if UNITY_EDITOR
                if (string.IsNullOrEmpty(_waterGUID)) _waterGUID = UnityEditor.GUID.Generate().ToString();
                return _waterGUID;
#else
            if (string.IsNullOrEmpty(_waterGUID)) Debug.LogError("Water GUID is empty ");
            Debug.Log("Water GUID is empty " + _waterGUID);
            return _waterGUID;
#endif
            }
        }

        internal void AddMaterialToWaterRendering(Material additionalMaterial)
        {
            if (additionalMaterial == null || waterSharedMaterials.Contains(additionalMaterial)) return;
            waterSharedMaterials.Add(additionalMaterial);
        }

        internal void RemoveMaterialFromWaterRendering(Material additionalMaterial)
        {
            if (additionalMaterial == null || !waterSharedMaterials.Contains(additionalMaterial)) return;
            waterSharedMaterials.Remove(additionalMaterial);
        }

        internal List<Material> GetWaterRenderingMaterials()
        {
            return waterSharedMaterials;
        }

        internal Vector3 WaterMeshWorldPosition => WaterMeshTransform != null ? WaterMeshTransform.position : transform.position;
        internal Vector3 WaterWorldPosition => _waterTransform.position;
        internal Material WaterMaterial { get; private set; }
        internal Mesh WaterMesh { get; private set; }
        internal GameObject WaterMeshGameObject { get; private set; }
        internal Transform WaterMeshTransform { get; private set; }

        internal GameObject WaterTemporaryObject => _tempGameObject;

        internal static List<WaterSystem> ActiveWaterInstances { get; private set; } = new List<WaterSystem>();
        internal static bool IsRTHandleInitialized;

        internal bool IsWaterVisible { get; private set; }
        internal float CurrentMaxWaveHeight => (Mathf.Lerp(0, 10, WindSpeed / 15));


        #endregion

        #region private variables

        [SerializeField] string _waterGUID;

#if KWS_DEBUG
        public Vector4 Test4 = Vector4.zero;
#endif

        private Camera _currentCamera;
        private GameObject _tempGameObject;
        private Transform _waterTransform;
        private MeshRenderer _waterMeshRenderer;
        private MeshFilter _waterMeshFilter;

        private bool isWaterCommonResourcesInitialized;
        private bool isWaterPlatformSpecificResourcesInitialized;
        private bool isBuoyancyDataReadCompleted;
        private bool isMultipleFFTSimInitialized;

        List<Material> waterSharedMaterials = new List<Material>();

        #endregion

        #region properties

        private FFT_GPU _fft_lod0;

        private FFT_GPU fft_lod0
        {
            get
            {
                if (_fft_lod0 == null && _tempGameObject != null) _fft_lod0 = _tempGameObject.AddComponent<FFT_GPU>();
                return _fft_lod0;
            }
        }

        private FFT_GPU _fft_lod1;

        private FFT_GPU fft_lod1
        {
            get
            {
                if (_fft_lod1 == null && _tempGameObject != null) _fft_lod1 = _tempGameObject.AddComponent<FFT_GPU>();
                return _fft_lod1;
            }
        }

        private FFT_GPU _fft_lod2;

        private FFT_GPU fft_lod2
        {
            get
            {
                if (_fft_lod2 == null && _tempGameObject != null) _fft_lod2 = _tempGameObject.AddComponent<FFT_GPU>();
                return _fft_lod2;
            }
        }

        private KWS_FFT_ToHeightMap _fft_HeightData;

        private KWS_FFT_ToHeightMap fft_HeightData
        {
            get
            {
                if (_fft_HeightData == null && _tempGameObject != null)
                {
                    _fft_HeightData = _tempGameObject.AddComponent<KWS_FFT_ToHeightMap>();
                    _fft_HeightData.WaterInstance = this;
                    _fft_HeightData.IsDataReadCompleted += () => isBuoyancyDataReadCompleted = true;
                }

                return _fft_HeightData;
            }
        }

        private KW_ShorelineWaves _shorelineWaves;

        private KW_ShorelineWaves shorelineWaves
        {
            get
            {
                if (_shorelineWaves == null && _tempGameObject != null)
                {
                    _shorelineWaves = _tempGameObject.AddComponent<KW_ShorelineWaves>();
                    _shorelineWaves.WaterInstance = this;
                }

                return _shorelineWaves;
            }
        }

        private KW_FlowMap _flowMap;

        KW_FlowMap flowMap
        {
            get
            {
                if (_flowMap == null && _tempGameObject != null)
                {
                    _flowMap = _tempGameObject.AddComponent<KW_FlowMap>();
                    _flowMap.WaterInstance = this;
                }

                return _flowMap;
            }
        }

        private KW_FluidsSimulation2D _fluidsSimulation;

        KW_FluidsSimulation2D fluidsSimulation
        {
            get
            {
                if (_fluidsSimulation == null && _tempGameObject != null)
                {
                    _fluidsSimulation = _tempGameObject.AddComponent<KW_FluidsSimulation2D>();
                    _fluidsSimulation.WaterInstance = this;
                }

                return _fluidsSimulation;
            }
        }

        private KW_DynamicWaves _dynamicWaves;

        KW_DynamicWaves dynamicWaves
        {
            get
            {
                if (_dynamicWaves == null && _tempGameObject != null)
                {
                    _dynamicWaves = _tempGameObject.AddComponent<KW_DynamicWaves>();
                    _dynamicWaves.WaterInstance = this;
                }

                return _dynamicWaves;
            }
        }

        private KWS_SplineMesh _splineMesh;

        internal KWS_SplineMesh splineMesh
        {
            get
            {
                if (_splineMesh == null && _tempGameObject != null) _splineMesh = _tempGameObject.AddComponent<KWS_SplineMesh>();
                return _splineMesh;
            }
        }

        #endregion


        KW_Extensions.AsyncInitializingStatusEnum shoreLineInitializingStatus;
        KW_Extensions.AsyncInitializingStatusEnum flowmapInitializingStatus;
        KW_Extensions.AsyncInitializingStatusEnum fluidsSimInitializingStatus;

        const int BakeFluidsLimitFrames = 350;
        int currentBakeFluidsFrames = 0;

        KW_CustomFixedUpdate fixedUpdateFluids;
        KW_CustomFixedUpdate fixedUpdateBakingFluids;
        KW_CustomFixedUpdate fixedUpdateDynamicWaves;
        private bool _lastWaterVisible;
        private float _lastInfiniteMeshSize;


#if UNITY_EDITOR
        [MenuItem("GameObject/Effects/Water System")]
        static void CreateWaterSystemEditor(MenuCommand menuCommand)
        {
            var go = new GameObject("Water System");
            go.transform.position = SceneView.lastActiveSceneView.camera.transform.TransformPoint(Vector3.forward * 3f);
            go.AddComponent<WaterSystem>();
            GameObjectUtility.SetParentAndAlign(go, menuCommand.context as GameObject);
            Undo.RegisterCreatedObjectUndo(go, "Create " + go.name);
            Selection.activeObject = go;
        }
#endif


        private void OnEnable()
        {
            _waterTransform = transform;
       
            if (!WaterSystem.IsRTHandleInitialized)
            {
                var screenSize = KWS_CoreUtils.GetScreenSizeLimited();
                WaterSystem.IsRTHandleInitialized = true;
                KWS_RTHandles.Initialize(screenSize.x, screenSize.y, false, KWS.MSAASamples.None);
            }
            
            SubscribeBeforeCameraRendering();
            SubscribeAfterCameraRendering();
        }

        void OnDisable()
        {
            if (ActiveWaterInstances.Contains(this)) ActiveWaterInstances.Remove(this);
            _lastWaterVisible = false;

            UnsubscribeBeforeCameraRendering();
            UnsubscribeAfterCameraRendering();

            ReleasePlatformSpecificResources();
            ReleaseCommonResources();

            OnWaterRelease?.Invoke();
        }


        void OnBeforeCameraRendering(Camera cam)
        {
            if (!KWS_CoreUtils.CanRenderWaterForCurrentCamera(cam)) return;

            if (isWaterCommonResourcesInitialized)
            {
                IsWaterVisible = IsWaterVisibleForCamera(cam);
                UpdateActiveWaterInstancesInfo();
                if (!IsWaterVisible) return;
            }

#if UNITY_EDITOR
            KW_Extensions.UpdateEditorDeltaTime();
#endif
            _currentCamera = cam;

            Profiler.BeginSample("Water.Rendering");
            RenderWater();
            Profiler.EndSample();
        }

        void OnAfterCameraRendering(Camera cam)
        {
            if (cam.cameraType != CameraType.Game && cam.cameraType != CameraType.SceneView) return;

#if UNITY_EDITOR
            KW_Extensions.SetEditorDeltaTime();
#endif
        }


        public void EnableBuoyancyRendering()
        {
            isBuoyancyDataReadCompleted = false;
        }

        public void DisableBuoyancyRendering()
        {
            isBuoyancyDataReadCompleted = false;
        }
    }
}