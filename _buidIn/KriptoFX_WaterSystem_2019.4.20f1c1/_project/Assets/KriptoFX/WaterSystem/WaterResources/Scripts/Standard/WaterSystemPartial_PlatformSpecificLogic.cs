using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;


namespace KWS
{
    public partial class WaterSystem
    {
        public List<ThirdPartyAssetDescription> ThirdPartyFogAssetsDescription = new List<ThirdPartyAssetDescription>()
        { 
            new ThirdPartyAssetDescription(){EditorName = "Native Unity Fog", ShaderDefine = ""},
            new ThirdPartyAssetDescription(){EditorName = "Enviro", ShaderDefine = "ENVIRO_FOG", ShaderInclude = "EnviroFogCore.cginc"},
            new ThirdPartyAssetDescription(){EditorName = "Azure", ShaderDefine = "AZURE_FOG", ShaderInclude = "AzureFogCore.cginc"},
            new ThirdPartyAssetDescription(){EditorName = "Weather maker", ShaderDefine = "WEATHER_MAKER", ShaderInclude = "WeatherMakerFogExternalShaderInclude.cginc"},
            new ThirdPartyAssetDescription(){EditorName = "Atmospheric height fog", ShaderDefine = "ATMOSPHERIC_HEIGHT_FOG", ShaderInclude = "AtmosphericHeightFog.cginc", OverrideQueue = true, CustomQueue = 3002},
            new ThirdPartyAssetDescription(){EditorName = "Volumetric fog and mist 2", ShaderDefine = "VOLUMETRIC_FOG_AND_MIST", ShaderInclude = "VolumetricFogOverlayVF.cginc", DrawToDepth = true},
            new ThirdPartyAssetDescription(){EditorName = "COZY Weather", ShaderDefine = "COZY_FOG", ShaderInclude = "StylizedFogIncludes.cginc", OverrideQueue = true, CustomQueue = 3002},
        };

        KWS_WaterPassHandler waterPassHandler;
        KWS_CameraReflection reflection;

        void SubscribeBeforeCameraRendering()
        {
            Camera.onPreCull += OnBeforeCameraRendering;
        }

        void UnsubscribeBeforeCameraRendering()
        {
            Camera.onPreCull -= OnBeforeCameraRendering;
        }

        void SubscribeAfterCameraRendering()
        {
            Camera.onPostRender += OnAfterCameraRendering;
        }

        void UnsubscribeAfterCameraRendering()
        {
            Camera.onPostRender -= OnAfterCameraRendering;
        }



        void InitializeWaterPlatformSpecificResources()
        {
            if (waterPassHandler == null)
            {
                waterPassHandler = _tempGameObject.AddComponent<KWS_WaterPassHandler>();
                waterPassHandler.WaterInstance = this;
            }

            if (reflection == null)
            {
                reflection = _tempGameObject.AddComponent<KWS_CameraReflection>();
                reflection.WaterInstance = this;
            }
            isWaterPlatformSpecificResourcesInitialized = true;
        }

        void RenderPlatformSpecificFeatures(Camera cam)
        {
            SetAmbientLightToShaders();
            EnableDepthRenderingIfRequired(cam);
        }

        void ReleasePlatformSpecificResources()
        {
            isWaterPlatformSpecificResourcesInitialized = false;
        }

        public static void EnableDepthRenderingIfRequired(Camera cam)
        {
            if (cam.actualRenderingPath == RenderingPath.Forward && cam.depthTextureMode == DepthTextureMode.None) cam.depthTextureMode = DepthTextureMode.Depth;
        }

        void SetAmbientLightToShaders()
        {
            // return half3(unity_SHAr.w, unity_SHAg.w, unity_SHAb.w);
            SphericalHarmonicsL2 sh;
            LightProbes.GetInterpolatedProbe(WaterWorldPosition, null, out sh);
            var ambient = new Vector3(sh[0, 0] - sh[0, 6], sh[1, 0] - sh[1, 6], sh[2, 0] - sh[2, 6]);
            ambient = Vector3.Max(ambient, Vector3.zero);
            Shader.SetGlobalVector(KWS_ShaderConstants.WaterID.KWS_AmbientColor, ambient);
        }
    }

}