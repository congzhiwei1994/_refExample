#if UNITY_EDITOR
using System;
using System.Collections.Generic;
using System.Linq;
using UnityEditor;
using UnityEngine;
using static KWS.KWS_EditorUtils;
using Debug = UnityEngine.Debug;
using static KWS.WaterSystem;
using static KWS.KWS_Settings;
using Description = KWS.KWS_EditorTextDescription;

namespace KWS
{
    [System.Serializable]
    [CustomEditor(typeof(WaterSystem))]
    public partial class KWS_Editor : Editor
    {
        private WaterSystem _waterSystem;

        private bool                _isActive;
        private WaterEditorModeEnum _waterEditorMode;
        private WaterEditorModeEnum _waterEditorModeLast;


        static KWS_EditorProfiles.PerfomanceProfiles.Reflection       _reflectionProfile;
        static KWS_EditorProfiles.PerfomanceProfiles.ColorRerfraction _colorRefractionProfile;
        static KWS_EditorProfiles.PerfomanceProfiles.Flowing          _flowingProfile;
        static KWS_EditorProfiles.PerfomanceProfiles.DynamicWaves     _dynamicWavesProfile;
        static KWS_EditorProfiles.PerfomanceProfiles.Shoreline        _shorelineProfile;
        static KWS_EditorProfiles.PerfomanceProfiles.VolumetricLight  _volumetricLightProfile;
        static KWS_EditorProfiles.PerfomanceProfiles.Caustic          _causticProfile;
        static KWS_EditorProfiles.PerfomanceProfiles.Mesh             _meshProfile;
        static KWS_EditorProfiles.PerfomanceProfiles.Rendering        _renderingProfile;

        private KWS_EditorShoreline shorelineEditor = new KWS_EditorShoreline();
        private KWS_EditorFlowmap   flowmapEditor   = new KWS_EditorFlowmap();
        private KWS_EditorCaustic   causticEditor   = new KWS_EditorCaustic();

        private KWS_EditorSplineMesh _splineMeshEditor;

        private KWS_EditorSplineMesh SplineMeshEditor
        {
            get
            {
                if (_splineMeshEditor == null) _splineMeshEditor = new KWS_EditorSplineMesh(_waterSystem);
                return _splineMeshEditor;
            }
        }

        enum WaterEditorModeEnum
        {
            Default,
            ShorelineEditor,
            FlowmapEditor,
            FluidsEditor,
            CausticEditor,
            SplineMeshEditor
        }

        void OnDestroy()
        {
            KWS_EditorUtils.Release();
        }


        public override void OnInspectorGUI()
        {
            _waterSystem = (WaterSystem) target;
            if (_waterSystem.enabled && _waterSystem.gameObject.activeSelf && _waterSystem.IsEditorAllowed())
            {
                _isActive   = true;
                GUI.enabled = true;
            }
            else
            {
                _isActive   = false;
                GUI.enabled = false;
            }

            UpdateWaterGUI();
        }

#if UNITY_2019_1_OR_NEWER
        void OnEnable()
        {
            SceneView.duringSceneGui += OnSceneGUICustom;
        }


        void OnDisable()
        {
            SceneView.duringSceneGui -= OnSceneGUICustom;
        }

        void OnSceneGUICustom(SceneView sceneView)
        {
            DrawWaterEditor();
        }
#else
        public void OnSceneGUI()
        {
            DrawWaterEditor();
        }

#endif

        void DrawWaterEditor()
        {
            if (!_isActive) return;

            if (_waterSystem.ShorelineInEditMode) _waterEditorMode               = WaterEditorModeEnum.ShorelineEditor;
            else if (_waterSystem.FlowMapInEditMode) _waterEditorMode            = WaterEditorModeEnum.FlowmapEditor;
            else if (_waterSystem.FluidsSimulationInEditMode()) _waterEditorMode = WaterEditorModeEnum.FluidsEditor;
            else if (_waterSystem.CausticDepthScaleInEditMode) _waterEditorMode  = WaterEditorModeEnum.CausticEditor;
            else if (_waterSystem.SplineMeshInEditMode) _waterEditorMode         = WaterEditorModeEnum.SplineMeshEditor;
            else _waterEditorMode                                                = WaterEditorModeEnum.Default;

            shorelineEditor.UpdateShorelineTime();

            switch (_waterEditorMode)
            {
                case WaterEditorModeEnum.Default:
                    break;
                case WaterEditorModeEnum.ShorelineEditor:
                    shorelineEditor.DrawShorelineEditor(_waterSystem);
                    _waterSystem.ShowShorelineMap = true;
                    break;
                case WaterEditorModeEnum.FlowmapEditor:
                    flowmapEditor.DrawFlowMapEditor(_waterSystem, this);
                    _waterSystem.ShowFlowMap = true;
                    break;
                case WaterEditorModeEnum.CausticEditor:
                    causticEditor.DrawCausticEditor(_waterSystem);
                    _waterSystem.ShowCausticEffectSettings = true;
                    break;
                case WaterEditorModeEnum.SplineMeshEditor:
                    SplineMeshEditor.DrawSplineMeshEditor(target);
                    _waterSystem.ShowMeshSettings = true;
                    break;
            }

            if (_waterEditorMode != WaterEditorModeEnum.Default || _waterEditorModeLast != _waterEditorMode) Repaint();
            _waterEditorModeLast = _waterEditorMode;
        }

        void UpdateWaterGUI()
        {
#if KWS_DEBUG
            _waterSystem.Test4 = EditorGUILayout.Vector4Field("Test4", _waterSystem.Test4);
#endif
            //waterSystem.TestObj = (GameObject) EditorGUILayout.ObjectField(waterSystem.TestObj, typeof(GameObject), true);

            var lastScene = SceneView.lastActiveSceneView;
            if (lastScene != null)
            {


#if UNITY_2020_2_OR_NEWER
            lastScene.sceneViewState.alwaysRefresh = true;
#else
                lastScene.sceneViewState.showMaterialUpdate = true;
#endif
                lastScene.sceneViewState.showSkybox       = true;
                lastScene.sceneViewState.showImageEffects = true;

#if UNITY_2020_3_OR_NEWER
            lastScene.sceneLighting = true;
#endif
            }

            EditorGUI.BeginChangeCheck();

            CheckMessages();

            var isActiveTab = _waterEditorMode == WaterEditorModeEnum.Default && _isActive;
            GUI.enabled = isActiveTab;

            bool                         defaultVal     = false;

            KWS_Tab(_waterSystem, ref _waterSystem.ShowColorSettings, false, false, ref defaultVal, null, "Color Settings", ColorSettings);
            KWS_Tab(_waterSystem, ref _waterSystem.ShowWaves,         false, false, ref defaultVal, null, "Waves",          WavesSettings);

            KWS_Tab(_waterSystem, ref _waterSystem.ShowReflectionSettings, true, true,  ref _waterSystem.ShowExpertReflectionSettings, _reflectionProfile,      "Reflection",       ReflectionSettings);
            KWS_Tab(_waterSystem, ref _waterSystem.ShowRefractionSettings, true, false, ref defaultVal,                                _colorRefractionProfile, "Color Refraction", RefractionSetting);

            KWS_Tab(_waterSystem, isActiveTab, ref _waterSystem.UseFlowMap, ref _waterSystem.ShowFlowMap, true, ref _waterSystem.ShowExpertFlowmapSettings, _flowingProfile, "Flowing", FlowingSettings);
            KWS_Tab(_waterSystem,    isActiveTab, ref _waterSystem.UseDynamicWaves, ref _waterSystem.ShowDynamicWaves, false, ref defaultVal, _dynamicWavesProfile, "Dynamic Waves", DynamicWavesSettings);
            KWS_Tab(_waterSystem, isActiveTab, ref _waterSystem.UseShorelineRendering, ref _waterSystem.ShowShorelineMap, false, ref defaultVal, _shorelineProfile, "Shoreline",ShorelineSetting);
            KWS_Tab(_waterSystem, isActiveTab, ref _waterSystem.UseVolumetricLight, ref _waterSystem.ShowVolumetricLightSettings, false, ref defaultVal, _volumetricLightProfile, "Volumetric Lighting", VolumetricLightingSettings);
            KWS_Tab(_waterSystem, isActiveTab, ref _waterSystem.UseCausticEffect, ref _waterSystem.ShowCausticEffectSettings, true, ref _waterSystem.ShowExpertCausticEffectSettings, _causticProfile, "Caustic", CausticSettings);
            KWS_Tab(_waterSystem, isActiveTab, ref _waterSystem.UseUnderwaterEffect, ref _waterSystem.ShowUnderwaterEffectSettings, false, ref defaultVal, null, "Underwater", UnderwaterSettings);

            KWS_Tab(_waterSystem, ref _waterSystem.ShowMeshSettings, true, false, ref defaultVal, _meshProfile,      "Mesh",      MeshSettings);
            KWS_Tab(_waterSystem, ref _waterSystem.ShowRendering,    true, false, ref defaultVal, _renderingProfile, "Rendering", RenderingSetting);


            GUI.enabled = isActiveTab;

            if (!_waterSystem.UseFlowMap            || !_isActive) _waterSystem.FlowMapInEditMode   = false;
            if (!_waterSystem.UseShorelineRendering || !_isActive) _waterSystem.ShorelineInEditMode = false;

            EditorGUILayout.LabelField("Water GUID: " + _waterSystem.WaterGUID, KWS_EditorUtils.NotesLabelStyleFade);

            Undo.RecordObject(target, "Changed water parameters");
        }

        void CheckMessages()
        {
            CheckPlatformSpecificMessages();
            if (_waterSystem.UseFlowMap && !_waterSystem.IsFlowmapInitialized()) KWS_EditorMessage(Description.Flowing.FlowingNotInitialized, MessageType.Warning);
            if (WaterSystem.SelectedThirdPartyFogMethod > 0) KWS_EditorMessage(Description.Rendering.ThirdPartyFogWarnign, MessageType.Warning);
        }

        void ColorSettings()
        {
            _waterSystem.Transparent = Slider("Transparent", Description.Color.Transparent, _waterSystem.Transparent, 0.1f, 50f, nameof(_waterSystem.Transparent));
            _waterSystem.WaterColor  = ColorField("Water Color", Description.Color.WaterColor, _waterSystem.WaterColor, false, false, false, nameof(_waterSystem.WaterColor));
            EditorGUILayout.Space();
            _waterSystem.TurbidityColor = ColorField("Turbidity Color", Description.Color.TurbidityColor, _waterSystem.TurbidityColor, false, false, false, nameof(_waterSystem.TurbidityColor));
            _waterSystem.Turbidity      = Slider("Turbidity", Description.Color.Turbidity, _waterSystem.Turbidity, 0.05f, 1f, nameof(_waterSystem.Turbidity));
        }

        void WavesSettings()
        {
            _waterSystem.FFT_SimulationSize = (FFT_GPU.SizeSetting) EnumPopup("Waves Detailing", Description.Waves.FFT_SimulationSize, _waterSystem.FFT_SimulationSize, nameof(_waterSystem.FFT_SimulationSize));
            _waterSystem.WindSpeed          = Slider("Wind Speed",      Description.Waves.WindSpeed,      _waterSystem.WindSpeed,      0.1f, 15.0f,  nameof(_waterSystem.WindSpeed));
            _waterSystem.WindRotation       = Slider("Wind Rotation",   Description.Waves.WindRotation,   _waterSystem.WindRotation,   0.0f, 360.0f, nameof(_waterSystem.WindRotation));
            _waterSystem.WindTurbulence     = Slider("Wind Turbulence", Description.Waves.WindTurbulence, _waterSystem.WindTurbulence, 0.0f, 1.0f,   nameof(_waterSystem.WindTurbulence));
            _waterSystem.TimeScale          = Slider("Time Scale",      Description.Waves.TimeScale,      _waterSystem.TimeScale,      0.0f, 2.0f,   nameof(_waterSystem.TimeScale));
        }

        void ReflectionSettings()
        {
            //KWS_EditorProfiles.PerfomanceProfiles.Reflection.ReadDataFromProfile(_waterSystem);

            _waterSystem.ReflectionMode = (ReflectionModeEnum) EnumPopup("Reflection Mode", Description.Reflection.ReflectionMode, _waterSystem.ReflectionMode, nameof(_waterSystem.ReflectionMode));

            if (_waterSystem.ReflectionMode == ReflectionModeEnum.PlanarReflection)
            {
                _waterSystem.PlanarReflectionResolutionQuality =
                    (PlanarReflectionResolutionQualityEnum) EnumPopup("Planar Resolution Quality", Description.Reflection.PlanarReflectionResolutionQuality, _waterSystem.PlanarReflectionResolutionQuality, nameof(_waterSystem.PlanarReflectionResolutionQuality));
            }

            if (_waterSystem.ReflectionMode == ReflectionModeEnum.ScreenSpaceReflection)
            {
                _waterSystem.ScreenSpaceReflectionResolutionQuality =
                    (ScreenSpaceReflectionResolutionQualityEnum) EnumPopup("Screen Space Resolution Quality", Description.Reflection.ScreenSpaceReflectionResolutionQuality, _waterSystem.ScreenSpaceReflectionResolutionQuality,
                                                                           nameof(_waterSystem.ScreenSpaceReflectionResolutionQuality));
            }

            if (_waterSystem.ShowExpertReflectionSettings)
            {
                if (_waterSystem.ReflectionMode == ReflectionModeEnum.ScreenSpaceReflection || _waterSystem.ReflectionMode == ReflectionModeEnum.PlanarReflection)
                    _waterSystem.ReflectionClipPlaneOffset = Slider("Clip Plane Offset", Description.Reflection.ReflectionClipPlaneOffset, _waterSystem.ReflectionClipPlaneOffset, 0, 0.07f, nameof(_waterSystem.ReflectionClipPlaneOffset));

                if (_waterSystem.ReflectionMode == ReflectionModeEnum.ScreenSpaceReflection)
                    _waterSystem.ReflectioDepthHolesFillDistance = IntSlider("Depth Holes Fill Distance", Description.Reflection.ReflectioDepthHolesFillDistance, _waterSystem.ReflectioDepthHolesFillDistance, 0, 25,
                                                                             nameof(_waterSystem.ReflectioDepthHolesFillDistance));

                EditorGUILayout.Space();
                EditorGUILayout.Space();

                if (_waterSystem.ReflectionMode == ReflectionModeEnum.CubemapReflection || _waterSystem.ReflectionMode == ReflectionModeEnum.ScreenSpaceReflection)
                {
                    var layerNames = new List<string>();
                    for (int i = 0; i <= 31; i++)
                    {
                        layerNames.Add(LayerMask.LayerToName(i));
                    }

                    EditorGUILayout.Space();
                    var mask = MaskField("Cubemap Culling Mask", Description.Reflection.CubemapCullingMask, _waterSystem.CubemapCullingMask, layerNames.ToArray(), nameof(_waterSystem.CubemapCullingMask));
                    _waterSystem.CubemapCullingMask    = mask & ~(1 << Water.WaterLayer);
                    _waterSystem.CubemapUpdateInterval = Slider("Cubemap Update Delay", Description.Reflection.CubemapUpdateInterval, _waterSystem.CubemapUpdateInterval, 0.25f, 60, nameof(_waterSystem.CubemapUpdateInterval));
                    _waterSystem.CubemapReflectionResolutionQuality =
                        (CubemapReflectionResolutionQualityEnum) EnumPopup("Cubemap Resolution Quality", Description.Reflection.CubemapReflectionResolutionQuality, _waterSystem.CubemapReflectionResolutionQuality, nameof(_waterSystem.CubemapReflectionResolutionQuality));
                }

                _waterSystem.UsePlanarCubemapReflection = Toggle("Use Planar Cubemap Reflection", Description.Reflection.UsePlanarCubemapReflection, _waterSystem.UsePlanarCubemapReflection, nameof(_waterSystem.UsePlanarCubemapReflection));

                EditorGUILayout.Space();
            }

            _waterSystem.UseAnisotropicReflections = Toggle("Use Anisotropic Reflections", Description.Reflection.UseAnisotropicReflections, _waterSystem.UseAnisotropicReflections, nameof(_waterSystem.UseAnisotropicReflections));
            if (_waterSystem.ShowExpertReflectionSettings && _waterSystem.UseAnisotropicReflections)
            {
                _waterSystem.AnisotropicReflectionsScale = Slider("Anisotropic Reflections Scale", Description.Reflection.AnisotropicReflectionsScale, _waterSystem.AnisotropicReflectionsScale, 0.1f, 1.5f,
                                                                  nameof(_waterSystem.AnisotropicReflectionsScale));
                _waterSystem.AnisotropicReflectionsHighQuality = Toggle("High Quality Anisotropic", Description.Reflection.AnisotropicReflectionsHighQuality, _waterSystem.AnisotropicReflectionsHighQuality,
                                                                        nameof(_waterSystem.AnisotropicReflectionsHighQuality));
                EditorGUILayout.Space();
            }


            _waterSystem.ReflectSun = Toggle("Reflect Sunlight", Description.Reflection.ReflectSun, _waterSystem.ReflectSun, nameof(_waterSystem.ReflectSun));
            if (_waterSystem.ReflectSun)
            {
                _waterSystem.ReflectedSunCloudinessStrength = Slider("Sun Cloudiness", Description.Reflection.ReflectedSunCloudinessStrength, _waterSystem.ReflectedSunCloudinessStrength, 0.03f, 0.25f,
                                                                     nameof(_waterSystem.ReflectedSunCloudinessStrength));
                if (_waterSystem.ShowExpertReflectionSettings)
                    _waterSystem.ReflectedSunStrength = Slider("Sun Strength", Description.Reflection.ReflectedSunStrength, _waterSystem.ReflectedSunStrength, 0f, 1f, nameof(_waterSystem.ReflectedSunStrength));
            }

            CheckPlatformSpecificMessages_Reflection();

            //KWS_EditorProfiles.PerfomanceProfiles.Reflection.CheckDataChangesAnsSetCustomProfile(_waterSystem);
        }

        void RefractionSetting()
        {
            _waterSystem.RefractionMode = (RefractionModeEnum) EnumPopup("Refraction Mode", Description.Refraction.RefractionMode, _waterSystem.RefractionMode, nameof(_waterSystem.RefractionMode));

            if (_waterSystem.RefractionMode == RefractionModeEnum.PhysicalAproximationIOR)
            {
                _waterSystem.RefractionAproximatedDepth = Slider("Aproximated Depth", Description.Refraction.RefractionAproximatedDepth, _waterSystem.RefractionAproximatedDepth, 0.25f, 5f, nameof(_waterSystem.RefractionAproximatedDepth));
            }

            if (_waterSystem.RefractionMode == RefractionModeEnum.Simple)
            {
                _waterSystem.RefractionSimpleStrength = Slider("Strength", Description.Refraction.RefractionSimpleStrength, _waterSystem.RefractionSimpleStrength, 0.02f, 1, nameof(_waterSystem.RefractionSimpleStrength));
            }

            _waterSystem.UseRefractionDispersion = Toggle("Use Dispersion", Description.Refraction.UseRefractionDispersion, _waterSystem.UseRefractionDispersion, nameof(_waterSystem.UseRefractionDispersion));
            if (_waterSystem.UseRefractionDispersion)
            {
                _waterSystem.RefractionDispersionStrength = Slider("Dispersion Strength", Description.Refraction.RefractionDispersionStrength, _waterSystem.RefractionDispersionStrength, 0.25f, 1,
                                                                   nameof(_waterSystem.RefractionDispersionStrength));
            }

        }


        void FlowingSettings()
        {
            EditorGUILayout.HelpBox(Description.Flowing.FlowingDescription, MessageType.Info);

            KWS_EditorTab(_waterEditorMode == WaterEditorModeEnum.FlowmapEditor, FlowmapEditModeSettings);

            EditorGUILayout.Space();
            _waterSystem.UseFluidsSimulation = Toggle("Use Fluids Simulation", Description.Flowing.UseFluidsSimulation, _waterSystem.UseFluidsSimulation, nameof(_waterSystem.UseFluidsSimulation));
            if (_waterSystem.UseFluidsSimulation)
            {
                EditorGUILayout.HelpBox(Description.Flowing.FluidSimulationUsage, MessageType.Info);

                var simPercent = _waterSystem.GetBakeSimulationPercent();
                var fluidsInfo = simPercent > 0 ? string.Concat(" (", simPercent, "%)") : string.Empty;
                if (GUILayout.Button("Bake Fluids Obstacles" + fluidsInfo))
                {
                    if (EditorUtility.DisplayDialog("Warning", "Baking may take about a minute (depending on the settings and power of your PC).", "Ready to wait", "Cancel"))
                    {
                        _waterSystem.FlowMapInEditMode = false;
                        _waterSystem.Editor_SaveFluidsDepth();
                        _waterSystem.BakeFluidSimulation();
                    }
                }

                if (simPercent > 0) DisplayMessageNotification("Fluids baking: " + fluidsInfo, false, 3);

                EditorGUILayout.Space();

                if (_waterSystem.ShowExpertFlowmapSettings)
                {
                    float currentRenderedPixels = _waterSystem.FluidsSimulationIterrations * _waterSystem.FluidsTextureSize * _waterSystem.FluidsTextureSize * 2f; //iterations * width * height * lodLevels
                    currentRenderedPixels = (currentRenderedPixels / 1000000f);
                    EditorGUILayout.LabelField("Current rendered pixels(less is better): " + currentRenderedPixels.ToString("0.0") + " millions", KWS_EditorUtils.NotesLabelStyleFade);
                    _waterSystem.FluidsSimulationIterrations = IntSlider("Simulation iterations", Description.Flowing.FluidsSimulationIterrations, _waterSystem.FluidsSimulationIterrations, 1, 3,
                                                                         nameof(_waterSystem.FluidsSimulationIterrations));
                    _waterSystem.FluidsTextureSize = IntSlider("Fluids Texture Resolution", Description.Flowing.FluidsTextureSize, _waterSystem.FluidsTextureSize, 368, 2048, nameof(_waterSystem.FluidsTextureSize));
                }

                _waterSystem.FluidsAreaSize     = IntSlider("Fluids Area Size", Description.Flowing.FluidsAreaSize, _waterSystem.FluidsAreaSize, 10, 80, nameof(_waterSystem.FluidsAreaSize));
                _waterSystem.FluidsSpeed        = Slider("Fluids Flow Speed",    Description.Flowing.FluidsSpeed,        _waterSystem.FluidsSpeed,        0.25f, 1.0f, nameof(_waterSystem.FluidsSpeed));
                _waterSystem.FluidsFoamStrength = Slider("Fluids Foam Strength", Description.Flowing.FluidsFoamStrength, _waterSystem.FluidsFoamStrength, 0.0f,  1.0f, nameof(_waterSystem.FluidsFoamStrength));
            }
        }

        void FlowmapEditModeSettings()
        {
            if (GUILayout.Toggle(_waterSystem.FlowMapInEditMode, "Flowmap Painter", "Button"))
            {
                if (!_waterSystem.FlowMapInEditMode) SetEditorCameraPosition(_waterSystem.FlowMapAreaPosition);
                _waterSystem.FlowMapInEditMode = true;
            }
            else
            {
                _waterSystem.FlowMapInEditMode = false;
            }

            if (_waterSystem.FlowMapInEditMode)
            {
                EditorGUILayout.HelpBox(Description.Flowing.FlowingEditorUsage, MessageType.Info);

                EditorGUI.BeginChangeCheck();
                _waterSystem.FlowMapAreaPosition   = Vector3Field("FlowMap Area Position", Description.Flowing.FlowMapAreaPosition, _waterSystem.FlowMapAreaPosition, nameof(_waterSystem.FlowMapAreaPosition));
                _waterSystem.FlowMapAreaPosition.y = _waterSystem.transform.position.y;

                var newAreaSize = IntSlider("Flowmap Area Size", Description.Flowing.FlowMapAreaSize, _waterSystem.FlowMapAreaSize, 10, 2000, nameof(_waterSystem.FlowMapAreaSize));
                _waterSystem.FlowMapTextureResolution = (FlowmapTextureResolutionEnum) EnumPopup("Flowmap resolution", Description.Flowing.FlowMapTextureResolution, _waterSystem.FlowMapTextureResolution, nameof(_waterSystem.FlowMapTextureResolution));

                EditorGUILayout.Space();
                _waterSystem.FlowMapSpeed = Slider("Flow Speed", Description.Flowing.FlowMapSpeed, _waterSystem.FlowMapSpeed, 0.1f, 5f, nameof(_waterSystem.FlowMapSpeed));
                if (EditorGUI.EndChangeCheck())
                {
                    _waterSystem.RedrawFlowMap(newAreaSize);
                    _waterSystem.FlowMapAreaSize = newAreaSize;
                }

                _waterSystem.FlowMapBrushStrength = Slider("Brush Strength", Description.Flowing.FlowMapBrushStrength, _waterSystem.FlowMapBrushStrength, 0.01f, 1, nameof(_waterSystem.FlowMapBrushStrength));
                EditorGUILayout.Space();

                if (GUILayout.Button("Load Latest Saved"))
                {
                    if (EditorUtility.DisplayDialog("Load Latest Saved?", Description.Flowing.LoadLatestSaved, "Yes", "Cancel"))
                    {
                        _waterSystem.ReadFlowMap();
                        Debug.Log("Load Latest Saved");
                    }
                }

                if (GUILayout.Button("Delete All"))
                {
                    if (EditorUtility.DisplayDialog("Delete All?", Description.Flowing.DeleteAll, "Yes", "Cancel"))
                    {
                        _waterSystem.ClearFlowMap();
                        Debug.Log("Flowmap changes and texture deleted");
                    }
                }

                if (GUILayout.Button("Save All"))
                {
                    _waterSystem.SaveFlowMap();
                    _waterSystem.ReadFlowMap();
                    Debug.Log("Flowmap texture saved");
                }

                GUI.enabled = _isActive;
            }
        }

        void DynamicWavesSettings()
        {
            EditorGUILayout.HelpBox(Description.DynamicWaves.Usage, MessageType.Warning);
            var maxTexSize = DynamicWaves.MaxDynamicWavesTexSize;

            int currentRenderedPixels = _waterSystem.DynamicWavesAreaSize * _waterSystem.DynamicWavesResolutionPerMeter;
            currentRenderedPixels = currentRenderedPixels * currentRenderedPixels;
            EditorGUILayout.LabelField($"Simulation rendered pixels (less is better): {KW_Extensions.SpaceBetweenThousand(currentRenderedPixels)}", KWS_EditorUtils.NotesLabelStyleFade);

            _waterSystem.DynamicWavesAreaSize = IntSlider("Waves Area Size", Description.DynamicWaves.DynamicWavesAreaSize, _waterSystem.DynamicWavesAreaSize, 10, 200, nameof(_waterSystem.DynamicWavesAreaSize));
            _waterSystem.DynamicWavesResolutionPerMeter = _waterSystem.DynamicWavesAreaSize * _waterSystem.DynamicWavesResolutionPerMeter > maxTexSize
                ? maxTexSize / _waterSystem.DynamicWavesAreaSize
                : _waterSystem.DynamicWavesResolutionPerMeter;


            _waterSystem.DynamicWavesResolutionPerMeter = IntSlider("Detailing per meter", Description.DynamicWaves.DynamicWavesResolutionPerMeter, _waterSystem.DynamicWavesResolutionPerMeter, 5, 50,
                                                                    nameof(_waterSystem.DynamicWavesResolutionPerMeter));
            _waterSystem.DynamicWavesAreaSize = _waterSystem.DynamicWavesAreaSize * _waterSystem.DynamicWavesResolutionPerMeter > maxTexSize
                ? maxTexSize / _waterSystem.DynamicWavesResolutionPerMeter
                : _waterSystem.DynamicWavesAreaSize;



            _waterSystem.DynamicWavesPropagationSpeed = Slider("Speed", Description.DynamicWaves.DynamicWavesPropagationSpeed, _waterSystem.DynamicWavesPropagationSpeed, 0.1f, 2, nameof(_waterSystem.DynamicWavesPropagationSpeed));

            EditorGUILayout.Space();
            _waterSystem.UseDynamicWavesRainEffect = Toggle("Rain Drops", Description.DynamicWaves.UseDynamicWavesRainEffect, _waterSystem.UseDynamicWavesRainEffect, nameof(_waterSystem.UseDynamicWavesRainEffect));
            if (_waterSystem.UseDynamicWavesRainEffect)
            {
                _waterSystem.DynamicWavesRainStrength = Slider("Rain Strength", Description.DynamicWaves.DynamicWavesRainStrength, _waterSystem.DynamicWavesRainStrength, 0.01f, 1, nameof(_waterSystem.DynamicWavesRainStrength));
            }
        }

        void ShorelineSetting()
        {
            _waterSystem.FoamLodQuality     = (QualityEnum) EnumPopup("Foam Lod Quality", Description.Shoreline.FoamLodQuality, _waterSystem.FoamLodQuality, nameof(_waterSystem.FoamLodQuality));
            _waterSystem.FoamCastShadows    = Toggle("Foam Cast Shadows",    Description.Shoreline.FoamCastShadows,    _waterSystem.FoamCastShadows,    nameof(_waterSystem.FoamCastShadows));
            _waterSystem.FoamReceiveShadows = Toggle("Foam Receive Shadows", Description.Shoreline.FoamReceiveShadows, _waterSystem.FoamReceiveShadows, nameof(_waterSystem.FoamReceiveShadows));
            if (_waterSystem.UseShorelineRendering && _waterSystem.FoamReceiveShadows && !_waterSystem.UseVolumetricLight) EditorGUILayout.HelpBox(Description.Shoreline.FoamShadowsRequiredVolumetric, MessageType.Warning);
            if (_waterSystem.UseShorelineRendering && _waterSystem.FoamReceiveShadows)
                EditorGUILayout.HelpBox(Description.Shoreline.FoamShadowsUsageWarning, MessageType.Warning);

            EditorGUI.BeginChangeCheck();

            KWS_EditorTab(_waterEditorMode == WaterEditorModeEnum.ShorelineEditor, ShorelineEditModeSettings);
        }

        void ShorelineEditModeSettings()
        {
            _waterSystem.ShorelineInEditMode = GUILayout.Toggle(_waterSystem.ShorelineInEditMode, "Edit Mode", "Button");

            if (_isActive)
            {
                if (EditorGUI.EndChangeCheck())
                {
                    if (_waterSystem.ShorelineInEditMode && _waterSystem.IsShorelineWavesDataRequiredInitialize())
                    {
                        if (_waterSystem.ShorelineInEditMode) SetEditorCameraPosition(_waterSystem.ShorelineAreaPosition);
                        _waterSystem.InitialiseShorelineEditorResources();
                        shorelineEditor.ForceUpdateShoreline();
                    }
                }
            }

            if (_waterSystem.ShorelineInEditMode)
            {
                EditorGUILayout.HelpBox(Description.Shoreline.ShorelineEditorUsage, MessageType.Info);

                _waterSystem.ShorelineAreaPosition   = Vector3Field("Drawing Area Position", Description.Shoreline.ShorelineAreaPosition, _waterSystem.ShorelineAreaPosition, nameof(_waterSystem.ShorelineAreaPosition));
                _waterSystem.ShorelineAreaPosition.y = _waterSystem.transform.position.y;
                _waterSystem.ShorelineAreaSize       = IntSlider("Shoreline Area Size", Description.Shoreline.ShorelineAreaSize, _waterSystem.ShorelineAreaSize, 100, 8000, nameof(_waterSystem.ShorelineAreaSize));

                _waterSystem.ShorelineCurvedSurfacesQuality =
                    (QualityEnum) EnumPopup("Curved Surfaces Quality", Description.Shoreline.ShorelineCurvedSurfacesQuality, _waterSystem.ShorelineCurvedSurfacesQuality, nameof(_waterSystem.ShorelineCurvedSurfacesQuality));

                GUILayout.Space(10);
                if (GUILayout.Button(new GUIContent("Add Wave")))
                {
                    shorelineEditor.AddWave(_waterSystem, shorelineEditor.GetCameraToWorldRay(), true);
                    shorelineEditor.ForceUpdateShoreline();
                }


                if (GUILayout.Button("Delete All Waves"))
                {
                    if (EditorUtility.DisplayDialog("Delete Shoreline Waves?", Description.Shoreline.DeleteAll, "Yes", "Cancel"))
                    {
                        _waterSystem.ClearShorelineWavesWithFoam();
                        Debug.Log("Shoreline waves deleted");
                        shorelineEditor.ForceUpdateShoreline();
                    }
                }

                if (GUILayout.Button("Save Changes"))
                {
                    _waterSystem.BakeWavesToTexture();
                    _waterSystem.SaveShorelineToDataFolder();
                    _waterSystem.SaveShorelineDepth();
                    Debug.Log("Shoreline Saved");
                }
            }
        }

        void VolumetricLightingSettings()
        {
            CheckPlatformSpecificMessages_VolumeLight();

            _waterSystem.VolumetricLightResolutionQuality =
                (VolumetricLightResolutionQualityEnum) EnumPopup("Resolution Quality", Description.VolumetricLight.ResolutionQuality, _waterSystem.VolumetricLightResolutionQuality, nameof(_waterSystem.VolumetricLightResolutionQuality));
            _waterSystem.VolumetricLightIteration = IntSlider("Iterations", Description.VolumetricLight.Iterations, _waterSystem.VolumetricLightIteration, 2, 8, nameof(_waterSystem.VolumetricLightIteration));
            _waterSystem.VolumetricLightFilter    = (VolumetricLightFilterEnum) EnumPopup("Filter Mode", Description.VolumetricLight.Filter, _waterSystem.VolumetricLightFilter, nameof(_waterSystem.VolumetricLightFilter));

            if (_waterSystem.VolumetricLightFilter != VolumetricLightFilterEnum.Bilateral)
                _waterSystem.VolumetricLightBlurRadius = EditorGUILayout.Slider(new GUIContent("Blur Radius", Description.VolumetricLight.BlurRadius), _waterSystem.VolumetricLightBlurRadius, 1, 4);

        }

        void CausticSettings()
        {
            if (_waterSystem.ShowExpertCausticEffectSettings)
            {
                float currentRenderedPixels = _waterSystem.CausticTextureSize * _waterSystem.CausticTextureSize * _waterSystem.CausticActiveLods;
                currentRenderedPixels = (currentRenderedPixels / 1000000f);
                EditorGUILayout.LabelField("Simulation rendered pixels (less is better): " + currentRenderedPixels.ToString("0.0") + " millions", KWS_EditorUtils.NotesLabelStyleFade);

                _waterSystem.UseCausticDispersion = Toggle("Use Dispersion", Description.Caustic.UseCausticDispersion, _waterSystem.UseCausticDispersion, nameof(_waterSystem.UseCausticDispersion));
                _waterSystem.UseCausticBicubicInterpolation = Toggle("Use Bicubic Interpolation", Description.Caustic.UseCausticBicubicInterpolation, _waterSystem.UseCausticBicubicInterpolation,
                                                                     nameof(_waterSystem.UseCausticBicubicInterpolation));
            }

            var texSize = IntSlider("Texture Size", Description.Caustic.CausticTextureSize, _waterSystem.CausticTextureSize, 256, 1024, nameof(_waterSystem.CausticTextureSize));
            texSize                         = Mathf.RoundToInt(texSize / 64f);
            _waterSystem.CausticTextureSize = (int) texSize * 64;
            if (_waterSystem.ShowExpertCausticEffectSettings)
                _waterSystem.CausticMeshResolution = IntSlider("Mesh Resolution", Description.Caustic.CausticMeshResolution, _waterSystem.CausticMeshResolution, 128, 512, nameof(_waterSystem.CausticMeshResolution));
            _waterSystem.CausticActiveLods = IntSlider("Cascades", Description.Caustic.CausticActiveLods, _waterSystem.CausticActiveLods, 1, 4, nameof(_waterSystem.CausticActiveLods));

            EditorGUILayout.Space();
            _waterSystem.CausticStrength   = Slider("Caustic Strength", Description.Caustic.CausticStrength,   _waterSystem.CausticStrength,   0,    2, nameof(_waterSystem.CausticStrength));
            _waterSystem.CausticDepthScale = Slider("Caustic Scale",    Description.Caustic.CausticDepthScale, _waterSystem.CausticDepthScale, 0.1f, 5, nameof(_waterSystem.CausticDepthScale));
            EditorGUILayout.Space();
            _waterSystem.UseDepthCausticScale = Toggle("Use Depth Scaling", Description.Caustic.UseDepthCausticScale, _waterSystem.UseDepthCausticScale, nameof(_waterSystem.UseDepthCausticScale));

            KWS_EditorTab(_waterEditorMode == WaterEditorModeEnum.CausticEditor, CausticEditModeSettings);
        }

        void CausticEditModeSettings()
        {
            if (_waterSystem.UseDepthCausticScale)
            {
                _waterSystem.CausticDepthScaleInEditMode = GUILayout.Toggle(_waterSystem.CausticDepthScaleInEditMode, "Edit Mode", "Button");
                if (_waterSystem.CausticDepthScaleInEditMode)
                {
                    if (_waterSystem.CausticOrthoDepthPosition.x > 10000000f) _waterSystem.CausticOrthoDepthPosition = shorelineEditor.GetSceneCameraPosition();
                    _waterSystem.CausticOrthoDepthPosition   = Vector3Field("Depth Area Position", Description.Caustic.CausticOrthoDepthPosition, _waterSystem.CausticOrthoDepthPosition, nameof(_waterSystem.CausticOrthoDepthPosition));
                    _waterSystem.CausticOrthoDepthPosition.y = _waterSystem.transform.position.y;

                    _waterSystem.CausticOrthoDepthAreaSize =
                        IntSlider("Depth Area Size", Description.Caustic.CausticOrthoDepthAreaSize, _waterSystem.CausticOrthoDepthAreaSize, 10, 8000, nameof(_waterSystem.CausticOrthoDepthAreaSize));
                    _waterSystem.CausticOrthoDepthTextureResolution =
                        IntSlider("Depth Texture Size", Description.Caustic.CausticOrthoDepthTextureResolution, _waterSystem.CausticOrthoDepthTextureResolution, 128, 4096, nameof(_waterSystem.CausticOrthoDepthTextureResolution));
                    if (GUILayout.Button("Bake Caustic Depth"))
                    {
                        _waterSystem.Editor_SaveCausticDepth();
                    }
                }
            }
        }

        void UnderwaterSettings()
        {
            _waterSystem.UseUnderwaterBlur = Toggle("Use Blur Effect", Description.Underwater.UseUnderwaterBlur, _waterSystem.UseUnderwaterBlur, nameof(_waterSystem.UseUnderwaterBlur));
            if (_waterSystem.UseUnderwaterBlur)
            {
                _waterSystem.UnderwaterBlurRadius = Slider("Blur Radius", Description.Underwater.UnderwaterBlurRadius, _waterSystem.UnderwaterBlurRadius, 0.1f, 3, nameof(_waterSystem.UnderwaterBlurRadius));
            }

        }

        void MeshSettings()
        {
            if (_waterSystem.WaterMesh != null)
            {
                int vertexCount = (int) (_waterSystem.WaterMesh.triangles.Length / 3.0f);
                EditorGUILayout.LabelField($"Water mesh triangles count (without tesselation): {KW_Extensions.SpaceBetweenThousand(vertexCount)}", KWS_EditorUtils.NotesLabelStyleFade);
            }

            var currentWaterMeshType = (WaterMeshTypeEnum)EnumPopup("Render Mode", Description.Mesh.WaterMeshType, _waterSystem.WaterMeshType, nameof(_waterSystem.WaterMeshType));
         
            if (currentWaterMeshType == WaterMeshTypeEnum.CustomMesh)
            {
                EditorGUI.BeginChangeCheck();
                _waterSystem.CustomMesh = (Mesh) EditorGUILayout.ObjectField(_waterSystem.CustomMesh, typeof(Mesh), true);
                if (EditorGUI.EndChangeCheck()) _waterSystem.InitializeOrUpdateCustomMesh();
            }

            if (currentWaterMeshType == WaterMeshTypeEnum.River)
            {
                KWS_EditorTab(_waterEditorMode == WaterEditorModeEnum.SplineMeshEditor, SplineEditModeSettings);
            }

            if (_waterSystem.WaterMeshType != currentWaterMeshType)
            {
                _waterSystem.WaterMeshType = currentWaterMeshType;
                _waterSystem.InitializeOrUpdateMesh();
            }

            EditorGUI.BeginChangeCheck();
            if (_waterSystem.WaterMeshType == WaterMeshTypeEnum.FiniteBox) _waterSystem.MeshSize = EditorGUILayout.Vector3Field("Water Mesh Size", _waterSystem.MeshSize);
            if (EditorGUI.EndChangeCheck()) _waterSystem.InitializeOrUpdateMesh();

            GUILayout.Space(20);

            if (!_waterSystem.UseTesselation)
            {
                EditorGUI.BeginChangeCheck();
                switch (currentWaterMeshType)
                {
                    case WaterMeshTypeEnum.InfiniteOcean:
                        _waterSystem.InfiniteMeshQuality = (WaterInfiniteMeshQualityEnum) EnumPopup("Mesh Quality", Description.Mesh.MeshQuality, _waterSystem.InfiniteMeshQuality, nameof(_waterSystem.InfiniteMeshQuality));
                        break;
                    case WaterMeshTypeEnum.FiniteBox:
                        _waterSystem.FiniteMeshQuality = (WaterFiniteMeshQualityEnum) EnumPopup("Mesh Quality", Description.Mesh.MeshQuality, _waterSystem.FiniteMeshQuality, nameof(_waterSystem.FiniteMeshQuality));
                        break;
                }

                if (EditorGUI.EndChangeCheck()) _waterSystem.InitializeOrUpdateMesh();
            }


            EditorGUI.BeginChangeCheck();
            _waterSystem.UseTesselation = Toggle("Use Tesselation", Description.Mesh.UseTesselation, _waterSystem.UseTesselation, nameof(_waterSystem.UseTesselation));
            if (EditorGUI.EndChangeCheck())
            {
                _waterSystem.InitializeOrUpdateMesh();
                _waterSystem.InitializeWaterMaterial(_waterSystem.UseTesselation);
            }

            if (_waterSystem.UseTesselation)
            {
                _waterSystem.TesselationFactor = Slider("Tesselation Factor", Description.Mesh.TesselationFactor, _waterSystem.TesselationFactor, 0.15f, 1, nameof(_waterSystem.TesselationFactor));

                if (_waterSystem.WaterMeshType == WaterMeshTypeEnum.InfiniteOcean)
                    _waterSystem.TesselationInfiniteMeshMaxDistance = Slider("Tesselation Max Distance", Description.Mesh.TesselationMaxDistance, _waterSystem.TesselationInfiniteMeshMaxDistance, 10, 10000, "TesselationMaxDistance");
                else _waterSystem.TesselationOtherMeshMaxDistance   = Slider("Tesselation Max Distance", Description.Mesh.TesselationMaxDistance, _waterSystem.TesselationOtherMeshMaxDistance,    10, 150,  "TesselationMaxDistance");

            }
        }

        void SplineEditModeSettings()
        {

            EditorGUI.BeginChangeCheck();
            _waterSystem.SplineMeshInEditMode = GUILayout.Toggle(_waterSystem.SplineMeshInEditMode, "River Editor", "Button");
            if (EditorGUI.EndChangeCheck() && _waterSystem.SplineMeshInEditMode)
            {
                var result = _waterSystem.splineMesh.LoadOrCreateSpline(_waterSystem.WaterGUID);
            }

            if (_waterSystem.SplineMeshInEditMode)
            {
                EditorGUILayout.HelpBox(Description.Mesh.RiverUsage, MessageType.Info);
                GUILayout.Space(20);

                _waterSystem.RiverSplineNormalOffset = Slider("Spline Normal Offset", Description.Mesh.RiverSplineNormalOffset, _waterSystem.RiverSplineNormalOffset, 0.1f, 10, nameof(_waterSystem.RiverSplineNormalOffset));

                EditorGUI.BeginChangeCheck();

                var loadedVertexCount                          = SplineMeshEditor.GetVertexCountBetweenPoints();
                if (loadedVertexCount == -1) loadedVertexCount = _waterSystem.RiverSplineVertexCountBetweenPoints;
                var newVertexCountBetweenPoints = IntSlider("Spline Vertex Count", Description.Mesh.RiverSplineVertexCountBetweenPoints,
                                                            loadedVertexCount,     Water.SplineRiverMinVertexCount, Water.SplineRiverMaxVertexCount, nameof(_waterSystem.RiverSplineVertexCountBetweenPoints));
                if (EditorGUI.EndChangeCheck())
                {
                    _waterSystem.RiverSplineVertexCountBetweenPoints = newVertexCountBetweenPoints;
                    SplineMeshEditor.UpdateVertexCountBetweenPoints();


                    if (_waterSystem.WaterMesh != null)
                    {
                        var vertexCount = (int) (_waterSystem.WaterMesh.triangles.Length / 3.0f);
                        DisplayMessageNotification($"Water mesh triangles count: {KW_Extensions.SpaceBetweenThousand(vertexCount)}", false, 1);
                    }
                }

                if (GUILayout.Button("Add River"))
                {
                    SplineMeshEditor.AddSpline();
                }

                if (GUILayout.Button("Delete Selected River"))
                {
                    if (EditorUtility.DisplayDialog("Delete Selected River?", Description.Mesh.RiverDeleteAll, "Yes", "Cancel"))
                    {
                        SplineMeshEditor.DeleteSpline();
                        Debug.Log("Selected river deleted");
                    }
                }

                if (SaveButton("Save Changes", SplineMeshEditor.IsSplineChanged()))
                {
                    _waterSystem.splineMesh.SaveSplineDataToFile(_waterSystem.WaterGUID);
                    SplineMeshEditor.ResetSplineChangeStatus();
                    Debug.Log("River spline saved");
                }
            }
        }

        void RenderingSetting()
        {
            ReadSelectedThirdPartyFog();
            var selectedThirdPartyFogMethod = _waterSystem.ThirdPartyFogAssetsDescription[WaterSystem.SelectedThirdPartyFogMethod];

            _waterSystem.UseFiltering            = Toggle("Use Filtering",           Description.Rendering.UseFiltering,            _waterSystem.UseFiltering,            nameof(_waterSystem.UseFiltering));
            _waterSystem.UseAnisotropicFiltering = Toggle("Use Anisotropic Normals", Description.Rendering.UseAnisotropicFiltering, _waterSystem.UseAnisotropicFiltering, nameof(_waterSystem.UseAnisotropicFiltering));

            if (selectedThirdPartyFogMethod.DrawToDepth)
            {
                EditorGUILayout.LabelField($"Draw To Depth overrated by {selectedThirdPartyFogMethod.EditorName}", KWS_EditorUtils.NotesLabelStyleFade);
                GUI.enabled = false;
                _waterSystem.DrawToPosteffectsDepth = Toggle("Draw To Depth", Description.Rendering.DrawToPosteffectsDepth, true, nameof(_waterSystem.DrawToPosteffectsDepth));
                GUI.enabled = true;
            }
            else
            {
                _waterSystem.DrawToPosteffectsDepth = Toggle("Draw To Depth", Description.Rendering.DrawToPosteffectsDepth, _waterSystem.DrawToPosteffectsDepth, nameof(_waterSystem.DrawToPosteffectsDepth));
            }
            
            var assets = _waterSystem.ThirdPartyFogAssetsDescription;
            var fogDisplayedNames = new string[assets.Count + 1];
            for (var i = 0; i < assets.Count; i++)
            {
                fogDisplayedNames[i] = assets[i].EditorName;
            }
            EditorGUI.BeginChangeCheck();
            WaterSystem.SelectedThirdPartyFogMethod = EditorGUILayout.Popup("Third-Party Fog Support", WaterSystem.SelectedThirdPartyFogMethod, fogDisplayedNames);
            if (EditorGUI.EndChangeCheck())
            {
                UpdateThirdPartyFog();
            }
        }

        void ReadSelectedThirdPartyFog()
        {
            //load enabled third-party asset for all water instances
            if (WaterSystem.SelectedThirdPartyFogMethod == -1)
            {
                var defines = _waterSystem.ThirdPartyFogAssetsDescription.Select(n => n.ShaderDefine).ToList();
                WaterSystem.SelectedThirdPartyFogMethod = KWS_EditorUtils.GetEnabledDefineIndex(ShaderPaths.KWS_PlatformSpecificHelpers, defines);
            }

        }

        void UpdateThirdPartyFog()
        {
            //replace defines
            for (int i = 1; i < _waterSystem.ThirdPartyFogAssetsDescription.Count; i++)
            {
                var selectedMethod = _waterSystem.ThirdPartyFogAssetsDescription[i];
                SetShaderTextDefine(ShaderPaths.KWS_PlatformSpecificHelpers, selectedMethod.ShaderDefine, WaterSystem.SelectedThirdPartyFogMethod == i);
            }

            //replace queue
            {
                var selectedMethod = _waterSystem.ThirdPartyFogAssetsDescription[WaterSystem.SelectedThirdPartyFogMethod];
                var queue          = selectedMethod.OverrideQueue ? selectedMethod.CustomQueue : KWS_Settings.Water.DefaultWaterQueue;

                KWS_EditorUtils.SetShaderTextQueue(ShaderPaths.KWS_WaterTesselated, queue);
                KWS_EditorUtils.SetShaderTextQueue(ShaderPaths.KWS_Water,           queue);
                KWS_EditorUtils.SetShaderTextQueue(ShaderPaths.KWS_FoamParticles,   queue + 1);
            }

            //replace paths to assets
            if (WaterSystem.SelectedThirdPartyFogMethod > 0)
            {
                var selectedMethod = _waterSystem.ThirdPartyFogAssetsDescription[WaterSystem.SelectedThirdPartyFogMethod];
                var inlcudeFileName = KW_Extensions.GetAssetsRelativePathToFile(selectedMethod.ShaderInclude);
                KWS_EditorUtils.ChangeShaderTextIncludePath(KWS_Settings.ShaderPaths.KWS_PlatformSpecificHelpers, selectedMethod.ShaderDefine, inlcudeFileName);
            }

            AssetDatabase.Refresh();
        }
    }
}
#endif