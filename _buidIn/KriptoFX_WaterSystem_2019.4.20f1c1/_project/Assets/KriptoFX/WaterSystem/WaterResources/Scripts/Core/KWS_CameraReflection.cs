using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Experimental.Rendering;


namespace KWS
{
    [ExecuteAlways]
    public partial class KWS_CameraReflection : MonoBehaviour
    {
        public WaterSystem WaterInstance;

        bool _isCanUpdate;
        private GameObject _reflCameraGo;
        private Camera _reflectionCamera;
        RenderTexture _planarRT;
        RenderTexture _planarRT_MipOrFiltered;

        RenderTexture _cubemapRT_Side;
        RenderTexture _cubemapRT_SideFiltered;
        Dictionary<Camera, RenderTexture> _cubemapRTBuffers = new Dictionary<Camera, RenderTexture>();
        private Material _filteringMaterial;
        private CommandBuffer cmd;

        const float m_ClipPlaneOffset = -0.025f;
        const float m_planeOffset = -0.025f;

        private float currentInterval = 0;
        private int sideIdx = 0;

        bool requiredUpdateAllFaces = true;
        // int waterCullingMask = ~(1 << 4);

        private bool _isPlanarTextureInitialized;
        private bool _isCubemapTextureInitialized;


        private void OnEnable()
        {
            _isCanUpdate = true;

            SubscribeBeforeCameraRendering();
            SubscribeAfterCameraRendering();
        }


        void OnDisable()
        {
            _isCanUpdate = false;

            UnsubscribeBeforeCameraRendering();
            UnsubscribeAfterCameraRendering();

            Release();
        }


        void OnBeforeCameraRendering(Camera cam)
        {
            if (!KWS_CoreUtils.CanRenderWaterForCurrentCamera(cam)) return;

            if (!_isCanUpdate) return;


            if (WaterInstance.ReflectionMode == WaterSystem.ReflectionModeEnum.PlanarReflection)
                RenderPlanar(cam, transform.position);

            //avoid incorrect frame debugger rendering with cubemap
#if UNITY_EDITOR
            var focusedWindow = UnityEditor.EditorWindow.focusedWindow;
            if (focusedWindow != null && focusedWindow.titleContent.text == "Frame Debug") return;
#endif

            if (WaterInstance.ReflectionMode == WaterSystem.ReflectionModeEnum.CubemapReflection || WaterInstance.ReflectionMode == WaterSystem.ReflectionModeEnum.ScreenSpaceReflection)
                RenderCubemap(cam, transform.position, WaterInstance.CubemapUpdateInterval, WaterInstance.CubemapCullingMask, WaterInstance.UsePlanarCubemapReflection);
        }

        void OnAfterCameraRendering(Camera cam)
        {

        }


        void ReleaseTextures()
        {
            _planarRT?.Release();
            _planarRT_MipOrFiltered?.Release();
            _cubemapRT_Side?.Release();
            _cubemapRT_SideFiltered?.Release();
            KW_Extensions.SafeDestroy(_planarRT, _planarRT_MipOrFiltered, _cubemapRT_Side, _cubemapRT_SideFiltered);
            _planarRT = _planarRT_MipOrFiltered = _cubemapRT_Side = _cubemapRT_SideFiltered = null;

            foreach (var cubemapRTBuffer in _cubemapRTBuffers.Values)
            {
                cubemapRTBuffer?.Release();
                KW_Extensions.SafeDestroy(cubemapRTBuffer);
            }
            _cubemapRTBuffers.Clear();

            _isPlanarTextureInitialized = false;
            _isCubemapTextureInitialized = false;

            KW_Extensions.WaterLog(this, "Release", KW_Extensions.WaterLogMessageType.Release);
        }

        void Release()
        {
            if (_reflectionCamera != null) _reflectionCamera.targetTexture = null;
            KW_Extensions.SafeDestroy(_reflCameraGo, _filteringMaterial);
            ReleaseTextures();
            currentInterval = 0;
            requiredUpdateAllFaces = true;

            KW_Extensions.WaterLog(this, "Release", KW_Extensions.WaterLogMessageType.Release);
        }

        private WaterSystem.PlanarReflectionResolutionQualityEnum _lastPlanarQuality;
        private WaterSystem.CubemapReflectionResolutionQualityEnum _lastCubemapQuality;
        private bool _lastUseAnisotropicReflections;
        private bool _lastAnisotropicReflectionsHighQuality;
        private int _lastCubemapLayers;

        void UpdateWaterLocalVariables()
        {
            _lastPlanarQuality = WaterInstance.PlanarReflectionResolutionQuality;
            _lastCubemapQuality = WaterInstance.CubemapReflectionResolutionQuality;
            _lastUseAnisotropicReflections = WaterInstance.UseAnisotropicReflections;
            _lastAnisotropicReflectionsHighQuality = WaterInstance.AnisotropicReflectionsHighQuality;
            _lastCubemapLayers = WaterInstance.CubemapCullingMask;
        }

        void UpdateRTHandlesSize()
        {
            if (WaterInstance.PlanarReflectionResolutionQuality != _lastPlanarQuality
                || WaterInstance.UseAnisotropicReflections != _lastUseAnisotropicReflections)
            {
                UpdateWaterLocalVariables();

                ReleaseTextures();
                KW_Extensions.WaterLog(this.ToString(), "Reset RTAlloc");
            }
        }


        void InitializePlanarTextures()
        {
            if (_isPlanarTextureInitialized) return;

            var format = GraphicsFormat.R16G16B16A16_SFloat;
            var height = (int)WaterInstance.PlanarReflectionResolutionQuality;
            var width = height * 2; // typical resolution ratio is 16x9 (or 2x1), for better pixel filling we use [2 * width] x [height], instead of square [width] * [height]. Also Camera.Render doesn't have SetViewportSize and we can't use RTHandle.DynamicSize

            if (WaterInstance.UseAnisotropicReflections)
            {
                _planarRT = new RenderTexture(width, height, 24, format) { name = "_planarRT", useMipMap = false, hideFlags = HideFlags.HideAndDontSave };
                _planarRT_MipOrFiltered = new RenderTexture(width, height, 0, format, 4) { name = "_planarRT_MipOrFiltered", useMipMap = true, autoGenerateMips = true, hideFlags = HideFlags.HideAndDontSave };
            }
            else
            {
                _planarRT = new RenderTexture(width, height, 24, format, 4) { name = "_planarRT", useMipMap = true, autoGenerateMips = true, hideFlags = HideFlags.HideAndDontSave };
            }


            UpdateWaterLocalVariables();
            _isPlanarTextureInitialized = true;

            KW_Extensions.WaterLog(this, _planarRT, _planarRT_MipOrFiltered);
        }

        void CreateCamera()
        {
            _reflCameraGo = new GameObject("WaterReflectionCamera");
#if KWS_DEBUG
            _reflCameraGo.hideFlags = HideFlags.DontSave;
#else
            _reflCameraGo.hideFlags = HideFlags.HideAndDontSave;
#endif

            _reflCameraGo.transform.parent = transform;
            _reflectionCamera = _reflCameraGo.AddComponent<Camera>();
            _reflectionCamera.cameraType = CameraType.Reflection;
            _reflectionCamera.allowMSAA = false;
            _reflectionCamera.enabled = false;
            _reflectionCamera.allowHDR = true;

            InitializeCameraParamsSRP();
        }

        void CopyCameraParams(Camera currentCamera, int cullingMask, bool invertFaceCulling)
        {
            //_reflectionCamera.CopyFrom(currentCamera); //this method have 100500 bugs

            _reflectionCamera.orthographic = currentCamera.orthographic;
            _reflectionCamera.fieldOfView = currentCamera.fieldOfView;
            _reflectionCamera.farClipPlane = currentCamera.farClipPlane;
            _reflectionCamera.nearClipPlane = currentCamera.nearClipPlane;
            _reflectionCamera.rect = currentCamera.rect;
            _reflectionCamera.renderingPath = currentCamera.renderingPath;

            if (currentCamera.usePhysicalProperties)
            {
                _reflectionCamera.usePhysicalProperties = true;
                _reflectionCamera.focalLength = currentCamera.focalLength;
                _reflectionCamera.sensorSize = currentCamera.sensorSize;
                _reflectionCamera.lensShift = currentCamera.lensShift;
                _reflectionCamera.gateFit = currentCamera.gateFit;
            }

            _reflectionCamera.cullingMask = cullingMask;
            _reflectionCamera.clearFlags = currentCamera.clearFlags;
            _reflectionCamera.backgroundColor = currentCamera.backgroundColor;
            _reflectionCamera.depth = currentCamera.depth - 100;


            CopyCameraParamsSRP(currentCamera, cullingMask, invertFaceCulling);
        }

        void RenderCamera(RenderTexture target, Vector3 waterPosition, Matrix4x4 cameraMatrix, Matrix4x4 projectionMatrix, Vector3 currentCameraPos, bool isPlanarMode = true)
        {
            if (isPlanarMode)
            {
                var pos    = waterPosition + Vector3.up * m_planeOffset;
                var normal = Vector3.up;

                var d               = -Vector3.Dot(normal, pos) - m_ClipPlaneOffset;
                var reflectionPlane = new Vector4(normal.x, normal.y, normal.z, d);

                var reflection = Matrix4x4.zero;
                CalculateReflectionMatrix(ref reflection, reflectionPlane);

                var newPos = reflection.MultiplyPoint(currentCameraPos);
                var xPos   = Mathf.Clamp(newPos.x, -float.MaxValue + 100, float.MaxValue - 100) + float.Epsilon; //avoiding error "Screen position out of view frustum"
                var yPos   = Mathf.Clamp(newPos.y, -float.MaxValue + 100, float.MaxValue - 100) + float.Epsilon;
                var zPos   = Mathf.Clamp(newPos.z, -float.MaxValue + 100, float.MaxValue - 100) + float.Epsilon;

                var _reflT = _reflectionCamera.transform;
                _reflT.position = new Vector3(xPos, yPos, zPos);
                if (_reflT.rotation.eulerAngles == Vector3.zero) _reflT.rotation = Quaternion.Euler(0.00001f, 0.00001f, 0.00001f);
                _reflectionCamera.worldToCameraMatrix = cameraMatrix * reflection;
                var clipPlane = CameraSpacePlane(_reflectionCamera, pos + normal * 0.05f, normal, 1.0f);

                CalculateObliqueMatrix(ref projectionMatrix, clipPlane);

                _reflectionCamera.projectionMatrix = projectionMatrix;
                var data = new PlanarReflectionSettingData();
                try
                {
                    data.Set();
                    _reflectionCamera.targetTexture = target;
                    CameraRender(_reflectionCamera);
                }
                finally
                {
                    data.Restore();
                }
            }
            else
            {
                _reflectionCamera.worldToCameraMatrix = cameraMatrix;
                _reflectionCamera.transform.position  = currentCameraPos;
                _reflectionCamera.projectionMatrix    = projectionMatrix;
                _reflectionCamera.targetTexture       = target;
                CameraRender(_reflectionCamera);
            }
        }

        void CalculateObliqueMatrix(ref Matrix4x4 projection, Vector4 clipPlane)
        {
            var q = projection.inverse * new Vector4(
                Sgn(clipPlane.x),
                Sgn(clipPlane.y),
                1.0f,
                1.0f
            );
            var c = clipPlane * (2.0F / (Vector4.Dot(clipPlane, q)));

            projection[2] = c.x - projection[3];
            projection[6] = c.y - projection[7];
            projection[10] = c.z - projection[11];
            projection[14] = c.w - projection[15];

            if (Mathf.Abs(projection[3, 2]) <= float.Epsilon) projection[3, 2] = -1;
        }


        public void RenderPlanar(Camera currentCamera, Vector3 waterPosition)
        {

            if (_reflCameraGo == null)
            {
                CreateCamera();
            }

            var cullingMask = ~(1 << KWS_Settings.Water.WaterLayer);
            CopyCameraParams(currentCamera, cullingMask, true);

            UpdateRTHandlesSize();
            InitializePlanarTextures();
            _reflectionCamera.fieldOfView = currentCamera.fieldOfView;
            _reflectionCamera.aspect = currentCamera.aspect;

            RenderCamera(_planarRT, waterPosition, currentCamera.worldToCameraMatrix, currentCamera.projectionMatrix, currentCamera.transform.position);

            if (WaterInstance.UseAnisotropicReflections)
            {
                if (_filteringMaterial == null) _filteringMaterial = KWS_CoreUtils.CreateMaterial(KWS_ShaderConstants.ShaderNames.ReflectionFiltering);

                _filteringMaterial.SetFloat(KWS_ShaderConstants.ReflectionsID.KWS_AnisoReflectionsScale, WaterInstance.AnisotropicReflectionsScale);
                _filteringMaterial.SetFloat(KWS_ShaderConstants.ReflectionsID.KWS_NormalizedWind, Mathf.Clamp01(WaterInstance.WindSpeed * 0.5f));

                if (cmd == null) cmd = new CommandBuffer() { name = "KWS.CameraReflection.AnisotropicFiltering_Pass" };
                cmd.Clear();
                cmd.BlitTriangle(_planarRT, Vector4.one, _planarRT_MipOrFiltered, _filteringMaterial, WaterInstance.AnisotropicReflectionsHighQuality ? 1 : 0);
                Graphics.ExecuteCommandBuffer(cmd);
                //  Graphics.Blit(_planarRT, _planarRT_MipOrFiltered, _filteringMaterial, WaterInstance.AnisotropicReflectionsHighQuality ? 1 : 0);
            }

            if (WaterInstance.UseAnisotropicReflections) RenderAnisotropicBlur(_planarRT, _planarRT_MipOrFiltered, false, false);
            var targetRT = WaterInstance.UseAnisotropicReflections ? _planarRT_MipOrFiltered : _planarRT;
            WaterInstance.SetTextures((KWS_ShaderConstants.ReflectionsID.KWS_PlanarReflectionRT, targetRT));
        }

        void RenderAnisotropicBlur(RenderTexture sourceRT, RenderTexture targetFilteredRT, bool isCubemap, bool isTopCubemap)
        {
            if (_filteringMaterial == null) _filteringMaterial = KWS_CoreUtils.CreateMaterial(KWS_ShaderConstants.ShaderNames.ReflectionFiltering);

            _filteringMaterial.SetFloat(KWS_ShaderConstants.ReflectionsID.KWS_AnisoReflectionsScale, WaterInstance.AnisotropicReflectionsScale);
            _filteringMaterial.SetFloat(KWS_ShaderConstants.ReflectionsID.KWS_NormalizedWind, Mathf.Clamp01(WaterInstance.WindSpeed * 0.5f));

            if (isCubemap)
            {
                var scale = 1f;
                if (isTopCubemap) scale = 0;
                _filteringMaterial.SetFloat(KWS_ShaderConstants.ReflectionsID.KWS_AnisoReflectionsScale, scale);
            }

            if (cmd == null) cmd = new CommandBuffer() { name = "KWS.CameraReflection.AnisotropicFiltering_Pass" };
            cmd.Clear();

            if (isCubemap) cmd.BlitTriangle(sourceRT, Vector4.one, targetFilteredRT, _filteringMaterial, WaterInstance.AnisotropicReflectionsHighQuality ? 3 : 2);
            else cmd.BlitTriangle(sourceRT, Vector4.one, targetFilteredRT, _filteringMaterial, WaterInstance.AnisotropicReflectionsHighQuality ? 1 : 0);

            Graphics.ExecuteCommandBuffer(cmd);
            //  Graphics.Blit(_planarRT, _planarRT_MipOrFiltered, _filteringMaterial, WaterInstance.AnisotropicReflectionsHighQuality ? 1 : 0);
        }

        bool IsRequireUpdateAllSides(Camera cam)
        {
            return (_cubemapRT_Side == null || !_cubemapRTBuffers.ContainsKey(cam) ||
                    WaterInstance.CubemapReflectionResolutionQuality != _lastCubemapQuality || WaterInstance.UseAnisotropicReflections != _lastUseAnisotropicReflections
                 || WaterInstance.CubemapCullingMask != _lastCubemapLayers || WaterInstance.AnisotropicReflectionsHighQuality != _lastAnisotropicReflectionsHighQuality);
        }

        RenderTexture GetCameraRelativeCubemapTexture(Camera cam)
        {
            if (!_cubemapRTBuffers.ContainsKey(cam))
            {
                var cubemapRT = InitializeCubemapTexture();
                _cubemapRTBuffers.Add(cam, cubemapRT);
                //KW_Extensions.WaterLog(this, _cubemapRTBuffers[cam]);
            }
            else if (_cubemapRTBuffers[cam].width != (int)WaterInstance.CubemapReflectionResolutionQuality)
            {
                var rt = _cubemapRTBuffers[cam];
                rt.Release();
                KW_Extensions.SafeDestroy(rt);
                _cubemapRTBuffers[cam] = InitializeCubemapTexture();
            }

            if (_cubemapRT_Side == null || _cubemapRT_Side.width != (int)WaterInstance.CubemapReflectionResolutionQuality
            || (WaterInstance.UseAnisotropicReflections && (_cubemapRT_SideFiltered == null || _cubemapRT_SideFiltered.width != (int)WaterInstance.CubemapReflectionResolutionQuality)))
            {
                InitializeCubemapTextureSide();
                //KW_Extensions.WaterLog(this, _cubemapRT_Side);
            }

            return _cubemapRTBuffers[cam];
        }

        RenderTexture InitializeCubemapTexture()
        {
            var size = (int)WaterInstance.CubemapReflectionResolutionQuality;
            var cubemapRT = new RenderTexture(size, size, 0, GraphicsFormat.R16G16B16A16_SFloat)
            {
                dimension = TextureDimension.Cube,
                useMipMap = false,
                autoGenerateMips = false,
                hideFlags = HideFlags.HideAndDontSave
            };
            return cubemapRT;
        }

        void InitializeCubemapTextureSide()
        {
            var size = (int)WaterInstance.CubemapReflectionResolutionQuality;
            if (_cubemapRT_Side != null)
            {
                _cubemapRT_Side.Release();
                KW_Extensions.SafeDestroy(_cubemapRT_Side);
            }

            if (_cubemapRT_SideFiltered != null)
            {
                _cubemapRT_SideFiltered.Release();
                KW_Extensions.SafeDestroy(_cubemapRT_SideFiltered);
            }

            if (WaterInstance.UseAnisotropicReflections)
            {
                _cubemapRT_SideFiltered = new RenderTexture(size, size, 24, GraphicsFormat.R16G16B16A16_SFloat) { name = "_cubemapRT_Side", useMipMap = false, autoGenerateMips = false, hideFlags = HideFlags.HideAndDontSave };
            }
            _cubemapRT_Side = new RenderTexture(size, size, 24, GraphicsFormat.R16G16B16A16_SFloat) { name = "_cubemapRT_Side", useMipMap = false, autoGenerateMips = false, hideFlags = HideFlags.HideAndDontSave };
        }

        public void RenderCubemap(Camera currentCamera, Vector3 waterPosition, float interval, int cullingMask, bool UsePlanarCubemapReflection)
        {
            currentInterval += KW_Extensions.DeltaTime();

            if (IsRequireUpdateAllSides(currentCamera)) requiredUpdateAllFaces = true;

            var targetCubemap = GetCameraRelativeCubemapTexture(currentCamera);

            if (requiredUpdateAllFaces || !(currentInterval < interval / 5.0f))
            {
                currentInterval = 0;

                if (_reflCameraGo == null)
                {
                    CreateCamera();
                }

                CopyCameraParams(currentCamera, cullingMask, UsePlanarCubemapReflection); //currentCamera.copyFrom doesn't work correctly 

                _reflectionCamera.fieldOfView = 90;
                _reflectionCamera.aspect = 1;
                var projectionMatrix = Matrix4x4.Perspective(90, 1, currentCamera.nearClipPlane, currentCamera.farClipPlane);


                if (requiredUpdateAllFaces)
                {
                    RenderToCubemapFace(targetCubemap, currentCamera, waterPosition, CubemapFace.NegativeX, projectionMatrix, UsePlanarCubemapReflection);
                    RenderToCubemapFace(targetCubemap, currentCamera, waterPosition, CubemapFace.NegativeY, projectionMatrix, UsePlanarCubemapReflection);
                    RenderToCubemapFace(targetCubemap, currentCamera, waterPosition, CubemapFace.NegativeZ, projectionMatrix, UsePlanarCubemapReflection);
                    RenderToCubemapFace(targetCubemap, currentCamera, waterPosition, CubemapFace.PositiveX, projectionMatrix, UsePlanarCubemapReflection);
                    RenderToCubemapFace(targetCubemap, currentCamera, waterPosition, CubemapFace.PositiveY, projectionMatrix, UsePlanarCubemapReflection);
                    RenderToCubemapFace(targetCubemap, currentCamera, waterPosition, CubemapFace.PositiveZ, projectionMatrix, UsePlanarCubemapReflection);
                }
                else
                {
                    if (sideIdx > 5) sideIdx = 0;
                    RenderToCubemapFace(targetCubemap, currentCamera, waterPosition, (CubemapFace)sideIdx, projectionMatrix, UsePlanarCubemapReflection);
                    sideIdx++;
                }

                requiredUpdateAllFaces = false;
                UpdateWaterLocalVariables();
            }

            WaterInstance.SetTextures((KWS_ShaderConstants.ReflectionsID.KWS_CubemapReflectionRT, targetCubemap));
        }

        void RenderToCubemapFace(RenderTexture targetCubemap, Camera currentCamera, Vector3 waterPosition, CubemapFace face, Matrix4x4 projectionMatrix, bool UsePlanarCubemapReflection)
        {
            var camPos = currentCamera.transform.position;
            var viewMatrix = Matrix4x4.Inverse(Matrix4x4.TRS(camPos, GetRotationByCubeFace(face), new Vector3(1, 1, -1)));

            RenderCamera(_cubemapRT_Side, waterPosition, viewMatrix, projectionMatrix, camPos, UsePlanarCubemapReflection);
            if (WaterInstance.UseAnisotropicReflections) RenderAnisotropicBlur(_cubemapRT_Side, _cubemapRT_SideFiltered, true, face == CubemapFace.PositiveY);
            var targetRT = WaterInstance.UseAnisotropicReflections ? _cubemapRT_SideFiltered : _cubemapRT_Side;
            Graphics.CopyTexture(targetRT, 0, targetCubemap, (int)face);
        }

        Quaternion GetRotationByCubeFace(CubemapFace face)
        {
            switch (face)
            {
                case CubemapFace.NegativeX: return Quaternion.Euler(0, -90, 0);
                case CubemapFace.PositiveX: return Quaternion.Euler(0, 90, 0);
                case CubemapFace.PositiveY: return Quaternion.Euler(90, 0, 0);
                case CubemapFace.NegativeY: return Quaternion.Euler(-90, 0, 0);
                case CubemapFace.PositiveZ: return Quaternion.Euler(0, 0, 0);
                case CubemapFace.NegativeZ: return Quaternion.Euler(0, -180, 0);
            }
            return Quaternion.identity;
        }

        private static float Sgn(float a)
        {
            if (a > 0.0f) return 1.0f;
            if (a < 0.0f) return -1.0f;
            return 0.0f;
        }

        private Vector4 CameraSpacePlane(Camera cam, Vector3 pos, Vector3 normal, float sideSign)
        {
            var offsetPos = pos + normal * m_ClipPlaneOffset;
            var m = cam.worldToCameraMatrix;
            var cameraPosition = m.MultiplyPoint(offsetPos);
            var cameraNormal = m.MultiplyVector(normal).normalized * sideSign;
            return new Vector4(cameraNormal.x, cameraNormal.y, cameraNormal.z, -Vector3.Dot(cameraPosition, cameraNormal));
        }

        private static void CalculateReflectionMatrix(ref Matrix4x4 reflectionMat, Vector4 plane)
        {
            reflectionMat.m00 = (1F - 2F * plane[0] * plane[0]);
            reflectionMat.m01 = (-2F * plane[0] * plane[1]);
            reflectionMat.m02 = (-2F * plane[0] * plane[2]);
            reflectionMat.m03 = (-2F * plane[3] * plane[0]);

            reflectionMat.m10 = (-2F * plane[1] * plane[0]);
            reflectionMat.m11 = (1F - 2F * plane[1] * plane[1]);
            reflectionMat.m12 = (-2F * plane[1] * plane[2]);
            reflectionMat.m13 = (-2F * plane[3] * plane[1]);

            reflectionMat.m20 = (-2F * plane[2] * plane[0]);
            reflectionMat.m21 = (-2F * plane[2] * plane[1]);
            reflectionMat.m22 = (1F - 2F * plane[2] * plane[2]);
            reflectionMat.m23 = (-2F * plane[3] * plane[2]);

            reflectionMat.m30 = 0F;
            reflectionMat.m31 = 0F;
            reflectionMat.m32 = 0F;
            reflectionMat.m33 = 1F;
        }

        class PlanarReflectionSettingData
        {
            private readonly bool _fog;
            private readonly int _maxLod;
            private readonly float _lodBias;

            public PlanarReflectionSettingData()
            {
                _fog = RenderSettings.fog;
                //_maxLod = QualitySettings.maximumLODLevel;
                // _lodBias = QualitySettings.lodBias;
            }

            public void Set()
            {
                GL.invertCulling = true;
                RenderSettings.fog = false;
                //QualitySettings.maximumLODLevel += 1;
                //QualitySettings.lodBias = _lodBias * 0.5f;
            }

            public void Restore()
            {
                GL.invertCulling = false;
                RenderSettings.fog = _fog;
                //QualitySettings.maximumLODLevel = _maxLod;
                //QualitySettings.lodBias = _lodBias;
            }
        }
    }
}