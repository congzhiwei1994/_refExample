using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Experimental.Rendering;
using UnityEngine.Rendering;
using static KWS.KWS_CoreUtils;

namespace KWS
{
    public class KWS_SSR_CommandPass
    {
        bool debugNonDx11Features = false;

        private KWS_RTHandle _reflectionRT;
        private KWS_RTHandle _reflectionRT_FilteredMip;
        ComputeBuffer _hashBuffer;
        private Material _filteringMaterial;
        private ComputeShader _cs;

        RenderTargetIdentifier _depthBuffer;
        RenderTargetIdentifier _colorBuffer;

        int _kernelClear;
        int _kernelRenderHash;
        int _kernelRenderColorFromHash;

        private WaterSystem _waterInstance;
        bool _isTexturesInitialized;

        private WaterSystem.ScreenSpaceReflectionResolutionQualityEnum _lastResolutionQuality;
        private bool _lastUseAnisotropicReflections;

        const int SHADER_NUMTHREAD_X = 8;
        const int SHADER_NUMTHREAD_Y = 8;

        void UpdateRTHandlesSize(Camera cam)
        {
            if (_waterInstance.ScreenSpaceReflectionResolutionQuality != _lastResolutionQuality)
            {
                _lastResolutionQuality = _waterInstance.ScreenSpaceReflectionResolutionQuality;
                var newSize = GetCameraScreenSizeLimited(cam);
                _isTexturesInitialized = false;
                InitializeTextures();
                KW_Extensions.WaterLog(this, "Reset RTHandle Reference Size");
            }

            if (_waterInstance.UseAnisotropicReflections != _lastUseAnisotropicReflections)
            {
                _lastUseAnisotropicReflections = _waterInstance.UseAnisotropicReflections;
                ReleaseTextures();
                InitializeTextures();
                KW_Extensions.WaterLog(this, "Reset RTAlloc");
            }
        }

        Vector2Int GetReflectionResolution(int width, int height)
        {
            var resolutionDownsample = (int)_waterInstance.ScreenSpaceReflectionResolutionQuality / 100f;
            return new Vector2Int((int)(width * resolutionDownsample), (int)(height * resolutionDownsample));
        }

        Vector2Int ComputeRTHandleSize(Vector2Int screenSize)
        {
            return GetReflectionResolution(screenSize.x, screenSize.y);
        }

        void InitializeTextures()
        {
            if (_isTexturesInitialized) return;

            var colorFormat = GraphicsFormat.R16G16B16A16_SFloat;
            
            if (_waterInstance.UseAnisotropicReflections)
            {
                _reflectionRT = KWS_RTHandles.Alloc(ComputeRTHandleSize, name: "_reflectionRT", colorFormat: colorFormat, enableRandomWrite: true, useMipMap: false);
                _reflectionRT_FilteredMip = KWS_RTHandles.Alloc(ComputeRTHandleSize, name: "_reflectionRT_Mip", colorFormat: colorFormat, useMipMap: true, autoGenerateMips: true, mipMapCount: 4);
            }
            else
            {
                _reflectionRT = KWS_RTHandles.Alloc(ComputeRTHandleSize, name: "_reflectionRT", colorFormat: colorFormat, enableRandomWrite: true, useMipMap: true, autoGenerateMips: false, mipMapCount: 4);
            }

            _lastResolutionQuality = _waterInstance.ScreenSpaceReflectionResolutionQuality;
            _lastUseAnisotropicReflections = _waterInstance.UseAnisotropicReflections;
            _isTexturesInitialized = true;

            KW_Extensions.WaterLog(this, _reflectionRT, _reflectionRT_FilteredMip);
        }

        void InitializeHashBuffer(int width, int height)
        {
            _hashBuffer = KWS_CoreUtils.GetOrUpdateBuffer<uint>(ref _hashBuffer, width * height);
            
        }

        public RenderTargetIdentifier GetTargetColorBuffer()
        {
            return _reflectionRT;
        }

        void InitializeMaterials()
        {
            if (_cs == null)
            {
                _cs = (ComputeShader)Resources.Load($"PlatformSpecific/KWS_SSR");
                _kernelClear = _cs.FindKernel(KWS_ShaderConstants.SSR_Kernels.Clear_kernel);
                _kernelRenderHash = _cs.FindKernel(KWS_ShaderConstants.SSR_Kernels.RenderHash_kernel);
                _kernelRenderColorFromHash = _cs.FindKernel(KWS_ShaderConstants.SSR_Kernels.RenderColorFromHash_kernel);
            }

            if (_filteringMaterial == null) _filteringMaterial = KWS_CoreUtils.CreateMaterial(KWS_ShaderConstants.ShaderNames.ReflectionFiltering);
        }

        public void Initialize(WaterSystem currentWater, RenderTargetIdentifier depthBuffer)
        {
            _waterInstance = currentWater;
            _depthBuffer = depthBuffer;
            InitializeTextures();
            InitializeMaterials();
        }

        public void Execute(Camera cam, CommandBuffer cmd)
        {
            UpdateRTHandlesSize(cam);
          
            var rtWidth  = _reflectionRT.rt.width  * _reflectionRT.rtHandleProperties.rtHandleScale.x;
            var rtHeight = _reflectionRT.rt.height * _reflectionRT.rtHandleProperties.rtHandleScale.y;

            int dispatchThreadGroupXCount = Mathf.CeilToInt((float)rtWidth / SHADER_NUMTHREAD_X);
            int dispatchThreadGroupYCount = Mathf.CeilToInt((float)rtHeight / SHADER_NUMTHREAD_Y);
            var waterOffsetFix = _waterInstance.ReflectionClipPlaneOffset * 15;

            InitializeHashBuffer((int) rtWidth, (int) rtHeight);

            cmd.SetComputeVectorParam(_cs, KWS_ShaderConstants.SSR_ID._RTSize, new Vector4(rtWidth, rtHeight, 1f / rtWidth, 1f / rtHeight));
            cmd.SetComputeFloatParam(_cs, KWS_ShaderConstants.SSR_ID._HorizontalPlaneHeightWS, _waterInstance.WaterMeshTransform.position.y + waterOffsetFix);
            cmd.SetComputeIntParam(_cs, KWS_ShaderConstants.SSR_ID._DepthHolesFillDistance, _waterInstance.ReflectioDepthHolesFillDistance);

            var matrixV = GL.GetGPUProjectionMatrix(cam.projectionMatrix, true);
            var matrixP = cam.worldToCameraMatrix;
            var matrixVP = matrixV * matrixP;
           
            cmd.SetComputeMatrixParam(_cs, KWS_ShaderConstants.SSR_ID.KW_MATRIX_VP, matrixVP);
            cmd.SetComputeMatrixParam(_cs, KWS_ShaderConstants.SSR_ID.KW_MATRIX_I_VP, matrixVP.inverse);

            cmd.SetComputeBufferParam(_cs, _kernelClear, KWS_ShaderConstants.SSR_ID.HashRT, _hashBuffer);
            cmd.SetComputeTextureParam(_cs, _kernelClear, KWS_ShaderConstants.SSR_ID.ColorRT, _reflectionRT.rt);
            cmd.DispatchCompute(_cs, _kernelClear, dispatchThreadGroupXCount, dispatchThreadGroupYCount, 1);

            cmd.SetComputeBufferParam(_cs, _kernelRenderHash, KWS_ShaderConstants.SSR_ID.HashRT, _hashBuffer);
            cmd.SetComputeTextureParam(_cs, _kernelRenderHash, KWS_ShaderConstants.SSR_ID.ColorRT, _reflectionRT.rt);
            cmd.SetComputeTextureParam(_cs, _kernelRenderHash, KWS_ShaderConstants.SSR_ID._CameraDepthTexture, _depthBuffer);
            cmd.DispatchCompute(_cs, _kernelRenderHash, dispatchThreadGroupXCount, dispatchThreadGroupYCount, 1);

            cmd.SetComputeBufferParam(_cs, _kernelRenderColorFromHash, KWS_ShaderConstants.SSR_ID.HashRT, _hashBuffer);
            cmd.SetComputeTextureParam(_cs, _kernelRenderColorFromHash, KWS_ShaderConstants.SSR_ID.ColorRT, _reflectionRT.rt);
            cmd.DispatchCompute(_cs, _kernelRenderColorFromHash, dispatchThreadGroupXCount, dispatchThreadGroupYCount, 1);

            if (_waterInstance.UseAnisotropicReflections)
            {
                _filteringMaterial.SetFloat(KWS_ShaderConstants.ReflectionsID.KWS_AnisoReflectionsScale, _waterInstance.AnisotropicReflectionsScale);
                _filteringMaterial.SetFloat(KWS_ShaderConstants.ReflectionsID.KWS_NormalizedWind, Mathf.Clamp01(_waterInstance.WindSpeed * 0.5f));

                cmd.BlitTriangleRTHandle(_reflectionRT, _reflectionRT.rtHandleProperties.rtHandleScale, _reflectionRT_FilteredMip, _filteringMaterial, ClearFlag.None, Color.clear, _waterInstance.AnisotropicReflectionsHighQuality ? 1 : 0);
            }
            else
            {
                cmd.GenerateMips(_reflectionRT.rt);
                //_reflectionRT.rt.GenerateMips();
            }

            var targetRT = _waterInstance.UseAnisotropicReflections ? _reflectionRT_FilteredMip : _reflectionRT;
            var rtScale = targetRT.rtHandleProperties.rtHandleScale;

            _waterInstance.SetTextures(cmd, (KWS_ShaderConstants.SSR_ID.KWS_ScreenSpaceReflectionRT, targetRT));
            _waterInstance.SetVectors(cmd, (KWS_ShaderConstants.SSR_ID.KWS_ScreenSpaceReflection_RTHandleScale, rtScale));
        }

        public void ReleaseTextures()
        {
            _reflectionRT?.Release();
            _reflectionRT_FilteredMip?.Release();
            _hashBuffer?.Release();
            _hashBuffer = null;
            _isTexturesInitialized = false;
        }

        public void Release()
        {
            ReleaseTextures();
            Resources.UnloadAsset(_cs);
            KW_Extensions.SafeDestroy(_filteringMaterial);

            KW_Extensions.WaterLog(this, "Release", KW_Extensions.WaterLogMessageType.Release);
        }
    }
}