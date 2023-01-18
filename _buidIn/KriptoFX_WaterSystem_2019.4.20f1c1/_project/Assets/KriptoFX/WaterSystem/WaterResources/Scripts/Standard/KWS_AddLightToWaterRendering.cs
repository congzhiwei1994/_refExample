using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Experimental.Rendering;
using UnityEngine.Rendering;
using static KWS.KWS_CoreUtils;
using static KWS.KWS_WaterLights;

namespace KWS
{
    [ExecuteAlways]
    [RequireComponent(typeof(Light))]
    public class KWS_AddLightToWaterRendering : MonoBehaviour
    {
        public VolumeLightRenderMode VolumetricLightRenderingMode = VolumeLightRenderMode.ShadowAndLight;
        public ShadowDownsampleEnum ShadowDownsample = ShadowDownsampleEnum._2x;

        TemporaryRenderTexture shadowMapRT = new TemporaryRenderTexture();

        CommandBuffer cmd;
        LightEvent lightEvent = LightEvent.AfterShadowMap;

        CommandBuffer cmd_copyShadowParams;
        LightEvent lightEvent_copyShadowParams = LightEvent.BeforeScreenspaceMask;

        ComputeBuffer computeBuffer_copyShadowParams;
        ComputeBuffer computeBuffer_copyPointShadowParams;
        ComputeShader computeShader;

        [HideInInspector]
        public Light currentLight;
        VolumeLight currentVolumeLight;

        bool isCommandBufferAdded;
        bool isCommandBufferCopyShadowParamsAdded;
        int _sourceShadowmapResolutionLog2 = -1;
        int sourceShadowmapResolutionLog2
        {
            get
            {
                if (_sourceShadowmapResolutionLog2 == -1) _sourceShadowmapResolutionLog2 = (int)Mathf.Log(1.0f * GetShadowSize() / (int)ShadowDownsample, 2);
                return _sourceShadowmapResolutionLog2;
            }
        }

        private void OnEnable()
        {
            if (currentVolumeLight == null)
            {
                currentLight = GetComponent<Light>();

                currentVolumeLight = new VolumeLight();
                currentVolumeLight.Light = currentLight;
                currentVolumeLight.LightTransform = currentLight.transform;
                currentVolumeLight.UseVolumetricShadows = (VolumetricLightRenderingMode == VolumeLightRenderMode.ShadowAndLight);
                currentVolumeLight.LightUpdate += LightUpdate;
                currentVolumeLight.ReleaseLight += ReleaseLight;
            }

            Lights.Add(currentVolumeLight);

        }

        void OnDisable()
        {
            Lights.Remove(currentVolumeLight);

            Release();
        }

        //void Update()
        //{
        //    if (currentLight.type == LightType.Directional) UpdateFoamShadows();
        //}

        //void UpdateFoamShadows()
        //{
        //    var currentWater = KW_WaterDynamicScripts.GetCurrentWater();
        //    if (currentWater != null)
        //    {
        //        if (currentWater.FoamReceiveShadows && !currentWater.UseVolumetricLight && currentLight.type == LightType.Directional)
        //        {
        //            currentVolumeLight.ShadowIndex = 0;
        //            InitializeShadowMapCommandBuffer();
        //        }
        //    }
        //}

        ///////////////////////////////////////////////////////////////////////////////////////// Shadowmap copy code ///////////////////////////////////////////////////////////////////////////////////


        void LightUpdate(Vector3 cameraPos)
        {
            currentVolumeLight.UseVolumetricShadows = (VolumetricLightRenderingMode == VolumeLightRenderMode.ShadowAndLight);
            // if (currentVolumeLight.IsVisible && currentVolumeLight.UseVolumetricShadows && currentLight.lightmapBakeType != LightmapBakeType.Baked && currentLight.shadows != LightShadows.None)
            if (currentVolumeLight.IsVisible && currentVolumeLight.UseVolumetricShadows && currentLight.shadows != LightShadows.None)
            {
                if (currentLight.type == LightType.Point || currentLight.type == LightType.Spot) UpdateLightShadowmapResolution(cameraPos);
                InitializeShadowMapCommandBuffer();
            }

            // if (!currentVolumeLight.UseVolumetricShadows || currentLight.lightmapBakeType == LightmapBakeType.Baked || currentLight.shadows == LightShadows.None)
            if (!currentVolumeLight.UseVolumetricShadows || currentLight.shadows == LightShadows.None)
            {
                if (isCommandBufferAdded) Release();
            }
        }

        void ReleaseLight()
        {
            ClearBuffers();
        }

        void UpdateLightShadowmapResolution(Vector3 cameraPosition)
        {
            var distance = Vector3.Distance(cameraPosition, currentVolumeLight.LightTransform.position);
            var maxDistance = currentLight.range * 10;
            var normalizedDistance = 1 - Mathf.Min(maxDistance, distance) / maxDistance;
            int normalizedShadowDistance = (int)(normalizedDistance * (sourceShadowmapResolutionLog2 + 1));
            int currentShadowSizeInPixels = (int)Mathf.Pow(2, normalizedShadowDistance);
            currentShadowSizeInPixels = Mathf.Max(currentShadowSizeInPixels, 32);
            currentLight.shadowCustomResolution = currentShadowSizeInPixels;
        }


        void InitializeShadowMapCommandBuffer()
        {
            if (cmd == null) cmd = new CommandBuffer() { name = "Water.CopyLightShadowMap" };
            cmd.Clear();
            if (currentVolumeLight.ShadowIndex == -1) return;

            var shadowmapProp = LightShadowmapID[currentLight.type][currentVolumeLight.ShadowIndex];
            cmd.SetShadowSamplingMode(BuiltinRenderTextureType.CurrentActive, ShadowSamplingMode.RawDepth);

            var lightType = currentLight.type;
            var dimension = LightShadowsDimension[lightType];
            int size = (lightType == LightType.Spot || lightType == LightType.Point) ? currentLight.shadowCustomResolution : (int)Mathf.Pow(2, sourceShadowmapResolutionLog2);
            if (size < 1) return;
            if (lightType == LightType.Directional) size = Mathf.Max(256, size);

            shadowMapRT.Alloc(shadowmapProp.ShadowmapName, size, size, 0, GraphicsFormat.R16_UNorm, useMipMap: false, dimension: dimension);

            if (lightType == LightType.Point) cmd.CopyTexture(BuiltinRenderTextureType.CurrentActive, shadowMapRT.rt);
            else cmd.Blit(BuiltinRenderTextureType.CurrentActive, shadowMapRT.rt);

            cmd.SetGlobalTexture(shadowmapProp.ShadowmapNameID, shadowMapRT.rt);

            if (lightType == LightType.Directional) CopyDirShadowParams();
            if (!isCommandBufferAdded)
            {
                currentLight.AddCommandBuffer(lightEvent, cmd);
                isCommandBufferAdded = true;
            }
        }


        int GetShadowSize()
        {
            Dictionary<LightShadowResolution, int> resolutionMap;
            switch (currentLight.type)
            {
                case LightType.Spot:
                    resolutionMap = StandardSpotLightShadowResolutionSize;
                    break;
                case LightType.Directional:
                    resolutionMap = StandardDirLightShadowResolutionSize;
                    break;
                case LightType.Point:
                    resolutionMap = StandardPointLightShadowResolutionSize;
                    break;
                default:
                    return -1;
            }

            var size = resolutionMap[currentLight.shadowResolution];
            if (size == -1)
            {
                var shadowResInt = (int)(QualitySettings.shadowResolution);
                size = resolutionMap[(LightShadowResolution)shadowResInt];
            }
            return size;
        }

        void CopyDirShadowParams()
        {
            if (!isCommandBufferCopyShadowParamsAdded)
            {
                if (cmd_copyShadowParams == null) cmd_copyShadowParams = new CommandBuffer() { name = "Water.CopyShadowMapParams" };
                cmd_copyShadowParams.Clear();

                if (computeShader == null) computeShader = (ComputeShader)Resources.Load("PlatformSpecific/KWS_CopyShadowParams");
                if (computeBuffer_copyShadowParams == null) computeBuffer_copyShadowParams = new ComputeBuffer(1, 336);
                cmd_copyShadowParams.SetComputeBufferParam(computeShader, 0, "_ShadowParams", computeBuffer_copyShadowParams);
                cmd_copyShadowParams.DispatchCompute(computeShader, 0, 1, 1, 1);
                cmd_copyShadowParams.SetGlobalBuffer(KWS_ShaderConstants_PlatformSpecific.LightsID.KWS_DirLightShadowParams, computeBuffer_copyShadowParams);
                currentLight.AddCommandBuffer(lightEvent_copyShadowParams, cmd_copyShadowParams);
                isCommandBufferCopyShadowParamsAdded = true;
            }
        }

        public void ClearBuffers()
        {
            if (cmd != null) cmd.Clear();
        }

        public void Release()
        {
            if (isCommandBufferAdded && cmd != null)
            {
                currentLight.RemoveCommandBuffer(lightEvent, cmd);
            }
            if (isCommandBufferCopyShadowParamsAdded && cmd_copyShadowParams != null)
            {
                currentLight.RemoveCommandBuffer(lightEvent_copyShadowParams, cmd_copyShadowParams);
            }

            isCommandBufferAdded = false;
            isCommandBufferCopyShadowParamsAdded = false;

            shadowMapRT.Release();
            if (computeBuffer_copyShadowParams != null)
            {
                computeBuffer_copyShadowParams.Release();
                computeBuffer_copyShadowParams = null;
            }

            if (computeBuffer_copyPointShadowParams != null)
            {
                computeBuffer_copyPointShadowParams.Release();
                computeBuffer_copyPointShadowParams = null;
            }

            _sourceShadowmapResolutionLog2 = -1;
            currentLight.shadowCustomResolution = -1;
        }

        /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    }
}