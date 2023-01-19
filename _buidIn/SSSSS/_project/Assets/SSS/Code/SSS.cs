using UnityEngine;
using UnityEngine.XR;
using SSS_utilities;
using UnityEngine.Profiling;
using System.Collections;
using UnityEngine.Rendering;
using System.Collections.Generic;
#if UNITY_EDITOR
using UnityEditor;
#endif

namespace SSS
{
    [ExecuteInEditMode]
    public class SSS : MonoBehaviour
    {
        public bool AllowMSAA;
        public LayerMask SSS_TransparencyLayer;
        [Range(0, 1)]
        public float CloseupCompensation = 0;
        public bool bEnableTransparency = false;
        public bool ForceWhiteTransparencyProfile = false;

        public bool ProfilePerObject = false;
        public enum ToggleTexture
        {
            LightingTex,
            LightingTexBlurred,
            ProfileTex,
            TransparencyTex,
            None
        }

        public ToggleTexture toggleTexture = ToggleTexture.LightingTex;
        public bool ShowGUI = false;
        public bool DEBUG_DISTANCE = false;

        #region layer
        [HideInInspector]
        public LayerMask SSS_Layer;
        SSS_buffers_viewer sss_buffers_viewer;
        #endregion

        public int maxDistance = 10;
        Camera cam;
        Camera LightingCamera;
        Camera ProfileCamera;
        Camera TransparencyCamera;
        //OrbitCamera _OrbitCamera;
        int InitialpixelLights = 0;
        ShadowQuality InitialShadows;
        // [HideInInspector]
        public Shader ProfileShader, LightingPassShader;
        private Vector2 m_TextureSize;

        [HideInInspector]
        public RenderTexture SSS_ProfileTex, LightingTex, LightingTexBlurred, SSS_TransparencyTex, SSS_TransparencyTexBlurred;
        RenderTexture SSS_ProfileTexR, LightingTexR, LightingTexBlurredR, SSS_TransparencyTexR, SSS_TransparencyTexBlurredR;
        [SerializeField]
        [Range(0, 1)]
        public float DepthTest = 0.3f, NormalTest = 0.3f, ProfileColorTest = .05f, ProfileRadiusTest = .05f;
        [Range(1, 1.2f)]
        public float EdgeOffset = 1.1f;
        public bool FixPixelLeaks = false;
        public bool DitherEdgeTest = false;
        public bool UseProfileTest = false;
        public Color sssColor = Color.yellow;
        GameObject ProfileCameraGO;
        GameObject LightingCameraGO;
        GameObject TransparencyCameraGO;
        SSS_convolution sss_convolution;
        SSS_TransparencyBlur sss_TransparencyBlur;
        [Range(0, 10f)]
        public float ScatteringRadius = 1;
        [Range(0, 10f)]
        public float TransparencyBlurRadius = 1;
        [Range(1, 4)]
        public
        float Downsampling = 1;
        [Range(0, 10)]
        public int ScatteringIterations = 3;
        [Range(0, 10)]
        public int TransparencyIterations = 3;
        [Range(1, 20)]
        public int ShaderIterations = 12;
        [Range(1, 20)]
        public int TransparencyShaderIterations = 12;
        public bool ShowCameras = false;
        bool ShowCamerasBack;
        public bool Dither = true;
        public Texture NoiseTexture;
        [Range(0, .5f)] public float DitherIntensity = 1;
        [Range(1, 5)] public float DitherScale = 1;
        //[Range(1, 20)] public float DitherSpeed = 1;
        Shader DepthCopyShader;
        Material DepthCopyMaterial;


        #region RT formats and camera settings
        private void UpdateCameraModes(Camera src, Camera dest)
        {
            if (dest == null)
                return;

            dest.farClipPlane = src.farClipPlane;
            dest.nearClipPlane = src.nearClipPlane;
            dest.stereoTargetEye = src.stereoTargetEye;
            dest.orthographic = src.orthographic;
            dest.aspect = src.aspect;
            dest.renderingPath = RenderingPath.Forward;
            dest.orthographicSize = src.orthographicSize;
            if (src.stereoEnabled == false)
            {
                if (src.usePhysicalProperties == false)
                {
                    dest.fieldOfView = src.fieldOfView;

                }
                else
                {
                    dest.usePhysicalProperties = src.usePhysicalProperties;
                    dest.projectionMatrix = src.projectionMatrix;
                }

            }


            if (src.stereoEnabled && dest.fieldOfView != src.fieldOfView)
                dest.fieldOfView = src.fieldOfView;
        }

        protected RenderTextureReadWrite GetRTReadWrite()
        {
            //return RenderTextureReadWrite.Default;
            return (cam.allowHDR) ? RenderTextureReadWrite.Default : RenderTextureReadWrite.Linear;
        }

        protected RenderTextureFormat GetRTFormat()
        {
            return (cam.allowHDR == true) ? RenderTextureFormat.ARGBFloat : RenderTextureFormat.Default;
        }
        bool Enabled = true;

        protected void GetRT(ref RenderTexture rt, int x, int y, string name)
        {
            ReleaseRT(rt);
            if (cam.allowMSAA && QualitySettings.antiAliasing > 0 && AllowMSAA)
            {
                sss_convolution.AllowMSAA = AllowMSAA;
                rt = RenderTexture.GetTemporary(x, y, 24, GetRTFormat(), GetRTReadWrite(), QualitySettings.antiAliasing);
            }
            else
                rt = RenderTexture.GetTemporary(x, y, 24, GetRTFormat(), GetRTReadWrite());
            rt.filterMode = FilterMode.Bilinear;
            //rt.autoGenerateMips = false;
            rt.name = name;
            rt.wrapMode = TextureWrapMode.Clamp;

        }

        private void Update()
        {
            //if (Input.GetKeyDown(KeyCode.Space))
            //    Enabled = !Enabled;

            //if (Input.GetKeyDown(KeyCode.Escape))
            //    Application.Quit();

            //if (!cam.allowMSAA && AllowMSAA)
            //{
            //    AllowMSAA = false;
            //    Debug.LogWarning("MSAA is not enabled in this camera");
            //}



#if UNITY_EDITOR
            if (LightingCameraGO)
                if (ShowCameras)
                {
                    LightingCameraGO.hideFlags = HideFlags.None;
                }
                else
                {
                    LightingCameraGO.hideFlags = HideFlags.HideInHierarchy;
                }

            if (ProfileCameraGO)
                if (ShowCameras)
                {
                    ProfileCameraGO.hideFlags = HideFlags.None;
                }
                else
                {
                    ProfileCameraGO.hideFlags = HideFlags.HideInHierarchy;
                }

            if (TransparencyCameraGO)
                if (ShowCameras)
                {
                    TransparencyCameraGO.hideFlags = HideFlags.None;
                }
                else
                {
                    TransparencyCameraGO.hideFlags = HideFlags.HideInHierarchy;
                }

            if (ShowCamerasBack != ShowCameras)
            {
                EditorApplication.RepaintHierarchyWindow();
                EditorApplication.DirtyHierarchyWindowSorting();
                ShowCamerasBack = ShowCameras;

            }

#endif

        }
        protected void GetProfileRT(ref RenderTexture rt, int x, int y, string name)
        {
            ReleaseRT(rt);
            //if (cam.allowMSAA && QualitySettings.antiAliasing > 0 && AllowMSAA)
            //    rt = RenderTexture.GetTemporary(x, y, 16, RenderTextureFormat.ARGB32, RenderTextureReadWrite.Linear, QualitySettings.antiAliasing);
            //else
            rt = RenderTexture.GetTemporary(x, y, 16, RenderTextureFormat.ARGB32, RenderTextureReadWrite.Linear);
            rt.filterMode = FilterMode.Point;
            rt.autoGenerateMips = false;
            rt.name = name;
            rt.wrapMode = TextureWrapMode.Clamp;
        }


        void ReleaseRT(RenderTexture rt)
        {
            if (rt != null)
            {
                RenderTexture.ReleaseTemporary(rt);
                rt = null;
            }
        }
        #endregion


        private void CreateCameras(Camera currentCamera, out Camera ProfileCamera, out Camera LightingCamera, out Camera TransparencyCamera)
        {


            //Camera for profile
            ProfileCamera = null;
            if (ProfilePerObject)
            {
                ProfileCameraGO = GameObject.Find("SSS profile Camera");
                if (!ProfileCameraGO)
                {
                    ProfileCameraGO = new GameObject("SSS profile Camera", typeof(Camera));
                    ProfileCameraGO.transform.parent = transform;
                    ProfileCameraGO.transform.localPosition = Vector3.zero;
                    ProfileCameraGO.transform.localEulerAngles = Vector3.zero;
                    ProfileCamera = ProfileCameraGO.GetComponent<Camera>();
                    ProfileCamera.backgroundColor = Color.black;
                    ProfileCamera.enabled = false;
                    ProfileCamera.depth = -254;
                    ProfileCamera.allowMSAA = false;
                }
                ProfileCamera = ProfileCameraGO.GetComponent<Camera>();
            }
            // Camera for lighting
            LightingCamera = null;
            LightingCameraGO = GameObject.Find("SSS Lighting Pass Camera");
            if (!LightingCameraGO)
            {
                LightingCameraGO = new GameObject("SSS Lighting Pass Camera", typeof(Camera));
                LightingCameraGO.transform.parent = transform;
                LightingCameraGO.transform.localPosition = Vector3.zero;
                LightingCameraGO.transform.localEulerAngles = Vector3.zero;
                LightingCamera = LightingCameraGO.GetComponent<Camera>();
                LightingCamera.backgroundColor = cam.backgroundColor;
                LightingCamera.enabled = false;
                LightingCamera.depth = -846;
                sss_convolution = LightingCameraGO.AddComponent<SSS_convolution>();
                sss_convolution.BlurShader = Shader.Find("Hidden/SeparableSSS");

            }
            LightingCamera = LightingCameraGO.GetComponent<Camera>();
            LightingCamera.allowMSAA = currentCamera.allowMSAA;

            TransparencyCamera = null;
            TransparencyCameraGO = GameObject.Find("SSS Transparency Camera");
            if (!TransparencyCameraGO)
            {
                TransparencyCameraGO = new GameObject("SSS Transparency Camera", typeof(Camera));
                TransparencyCameraGO.transform.parent = transform;
                TransparencyCameraGO.transform.localPosition = Vector3.zero;
                TransparencyCameraGO.transform.localEulerAngles = Vector3.zero;
                TransparencyCamera = TransparencyCameraGO.GetComponent<Camera>();
                TransparencyCamera.backgroundColor = cam.backgroundColor;
                TransparencyCamera.enabled = false;
                sss_TransparencyBlur = TransparencyCameraGO.AddComponent<SSS_TransparencyBlur>();
                sss_TransparencyBlur.BlurShader = Shader.Find("Hidden/SeparableSSS");
            }
            TransparencyCamera = TransparencyCameraGO.GetComponent<Camera>();
            TransparencyCamera.allowMSAA = currentCamera.allowMSAA;

        }

        void OnEnable()
        {


            if (SSS_Layer == 0)
            {
                SSS_Layer = 1;
                print("Setting SSS layer from Nothing to Default");
            }

            //optional
            //Utilities.CreateLayer("SSS pass");
            // SetSSS_Layer(_SSS_LayerName);
            if (NoiseTexture == null)
                NoiseTexture = (Texture)Resources.Load("bluenoise");
            cam = GetComponent<Camera>();
            //_OrbitCamera = gameObject.GetComponent<OrbitCamera>();
            //if (_OrbitCamera != null)
            //{
            //    if (cam.stereoEnabled && Application.isPlaying)
            //        _OrbitCamera.enabled = false;

            //    if (!Application.isPlaying)
            //        _OrbitCamera.enabled = true;

            //}
            //if (cam.renderingPath == RenderingPath.Forward) AllowMSAA = false;



            if (cam.GetComponent<SSS_buffers_viewer>() == null)
                sss_buffers_viewer = cam.gameObject.AddComponent<SSS_buffers_viewer>();

            if (sss_buffers_viewer == null)
                sss_buffers_viewer = cam.gameObject.GetComponent<SSS_buffers_viewer>();

            sss_buffers_viewer.hideFlags = HideFlags.HideAndDontSave;

            //Make things work on load if only scene view is active
            Shader.EnableKeyword("SCENE_VIEW");
            if (ProfilePerObject)
                Shader.EnableKeyword("SSS_PROFILES");

            DepthCopyShader = Shader.Find("Hidden/CopyDepth");
            if (DepthCopyMaterial == null)
                DepthCopyMaterial = new Material(DepthCopyShader);

            DepthCopyMaterial.hideFlags = HideFlags.HideAndDontSave;

        }


        private void OnPreRender()
        {

            if (Enabled)
            {

                #region Initial setup
                Shader.DisableKeyword("SCENE_VIEW");
                if (ProfileShader == null) ProfileShader = Shader.Find("Hidden/SSS_Profile");
                if (LightingPassShader == null) LightingPassShader = Shader.Find("Hidden/LightingPass");


                if (cam.stereoEnabled)
                {
                    m_TextureSize.x = XRSettings.eyeTextureWidth / Downsampling;
                    m_TextureSize.y = XRSettings.eyeTextureHeight / Downsampling;
                    //Shader.EnableKeyword("SSS_STEREO_ON");

                }
                else
                {
                    m_TextureSize.x = cam.pixelWidth / Downsampling;
                    m_TextureSize.y = cam.pixelHeight / Downsampling;
                    //Shader.DisableKeyword("SSS_STEREO_ON");

                }

                CreateCameras(cam, out ProfileCamera, out LightingCamera, out TransparencyCamera);
                #endregion




                #region Render Profile
                Profiler.BeginSample("SSS Profile");

                if (ProfilePerObject)
                {
                    UpdateCameraModes(cam, ProfileCamera);
                    //ProfileCamera.allowHDR = false;//humm, removes a lot of artifacts when far away

                    InitialpixelLights = QualitySettings.pixelLightCount;
                    InitialShadows = QualitySettings.shadows;
                    QualitySettings.pixelLightCount = 0;
                    QualitySettings.shadows = ShadowQuality.Disable;
                    Shader.EnableKeyword("SSS_PROFILES");
                    ProfileCamera.cullingMask = SSS_Layer;
                    ProfileCamera.backgroundColor = Color.black;
                    ProfileCamera.clearFlags = CameraClearFlags.SolidColor;

                    if (cam.stereoEnabled)
                    {    //Left eye   
                        if (cam.stereoTargetEye == StereoTargetEyeMask.Both || cam.stereoTargetEye == StereoTargetEyeMask.Left)
                        {
                            ProfileCamera.stereoTargetEye = StereoTargetEyeMask.Left;

                            //ProfileCamera.transform.localPosition = InputTracking.GetLocalPosition(XRNode.LeftEye);
                            //ProfileCamera.transform.localRotation = InputTracking.GetLocalRotation(XRNode.LeftEye);
                            ProfileCamera.projectionMatrix = cam.GetStereoProjectionMatrix(Camera.StereoscopicEye.Left);
                            ProfileCamera.worldToCameraMatrix = cam.GetStereoViewMatrix(Camera.StereoscopicEye.Left);
                            GetProfileRT(ref SSS_ProfileTex, (int)m_TextureSize.x, (int)m_TextureSize.y, "SSS_ProfileTex");
                            Rendering.RenderToTarget(ProfileCamera, SSS_ProfileTex, ProfileShader);
                            Shader.SetGlobalTexture("SSS_ProfileTex", SSS_ProfileTex);
                        }
                        //Right eye   
                        if (cam.stereoTargetEye == StereoTargetEyeMask.Both || cam.stereoTargetEye == StereoTargetEyeMask.Right)
                        {

                            ProfileCamera.stereoTargetEye = StereoTargetEyeMask.Right;
                            //ProfileCamera.transform.localPosition = InputTracking.GetLocalPosition(XRNode.SSS_StereoEyeIndex);
                            //ProfileCamera.transform.localRotation = InputTracking.GetLocalRotation(XRNode.SSS_StereoEyeIndex);
                            ProfileCamera.projectionMatrix = cam.GetStereoProjectionMatrix(Camera.StereoscopicEye.Right);
                            ProfileCamera.worldToCameraMatrix = cam.GetStereoViewMatrix(Camera.StereoscopicEye.Right);
                            GetProfileRT(ref SSS_ProfileTexR, (int)m_TextureSize.x, (int)m_TextureSize.y, "SSS_ProfileTexR");
                            Rendering.RenderToTarget(ProfileCamera, SSS_ProfileTexR, ProfileShader);
                            Shader.SetGlobalTexture("SSS_ProfileTexR", SSS_ProfileTexR);
                        }

                    }
                    else
                    {
                        //Mono
                        ProfileCamera.projectionMatrix = cam.projectionMatrix;//avoid frustum jitter from taa
                        ProfileCamera.worldToCameraMatrix = cam.worldToCameraMatrix;

                        GetProfileRT(ref SSS_ProfileTex, (int)m_TextureSize.x, (int)m_TextureSize.y, "SSS_ProfileTex");
                        Rendering.RenderToTarget(ProfileCamera, SSS_ProfileTex, ProfileShader);
                        Shader.SetGlobalTexture("SSS_ProfileTex", SSS_ProfileTex);
                    }

                    QualitySettings.pixelLightCount = InitialpixelLights;
                    QualitySettings.shadows = InitialShadows;

                }
                else
                {
                    Shader.DisableKeyword("SSS_PROFILES");

                    SafeDestroy(SSS_ProfileTex);
                    SafeDestroy(SSS_ProfileTexR);
                }
                Profiler.EndSample();

                #endregion

                #region Render Lighting
                Profiler.BeginSample("SSS diffuse lighting");
                UpdateCameraModes(cam, LightingCamera);
                LightingCamera.allowHDR = cam.allowHDR;
                // if (SurfaceScattering)
                {
                    if (sss_convolution == null)
                        sss_convolution = LightingCameraGO.GetComponent<SSS_convolution>();
                    if (sss_convolution && sss_convolution._BlurMaterial)
                    {
                        sss_convolution._BlurMaterial.SetFloat("CloseupCompensation", CloseupCompensation);
                        sss_convolution._BlurMaterial.SetFloat("DepthTest", Mathf.Max(.00001f, DepthTest / 20));
                        maxDistance = Mathf.Max(0, maxDistance);
                        sss_convolution._BlurMaterial.SetFloat("maxDistance", maxDistance);
                        sss_convolution._BlurMaterial.SetFloat("NormalTest", Mathf.Max(.001f, NormalTest));
                        sss_convolution._BlurMaterial.SetFloat("ProfileColorTest", Mathf.Max(.001f, ProfileColorTest));
                        sss_convolution._BlurMaterial.SetFloat("ProfileRadiusTest", Mathf.Max(.001f, ProfileRadiusTest));
                        sss_convolution._BlurMaterial.SetFloat("EdgeOffset", EdgeOffset);
                        sss_convolution._BlurMaterial.SetInt("_SSS_NUM_SAMPLES", ShaderIterations + 1);
                        sss_convolution._BlurMaterial.SetColor("sssColor", sssColor);

                        if (Dither)
                        {
                            sss_convolution._BlurMaterial.EnableKeyword("RANDOMIZED_ROTATION");
                            sss_convolution._BlurMaterial.SetFloat("DitherScale", DitherScale);
                            //sss_convolution._BlurMaterial.SetFloat("DitherSpeed", DitherSpeed * 10);
                            sss_convolution._BlurMaterial.SetFloat("DitherIntensity", DitherIntensity);

                            if (NoiseTexture)
                                sss_convolution._BlurMaterial.SetTexture("NoiseTexture", NoiseTexture);
                            else
                                Debug.Log("Noise texture not available");
                        }
                        else
                            sss_convolution._BlurMaterial.DisableKeyword("RANDOMIZED_ROTATION");

                        if (UseProfileTest && ProfilePerObject)
                            sss_convolution._BlurMaterial.EnableKeyword("PROFILE_TEST");
                        else
                            sss_convolution._BlurMaterial.DisableKeyword("PROFILE_TEST");

                        if (DEBUG_DISTANCE)
                            sss_convolution._BlurMaterial.EnableKeyword("DEBUG_DISTANCE");
                        else
                            sss_convolution._BlurMaterial.DisableKeyword("DEBUG_DISTANCE");

                        if (FixPixelLeaks)
                            sss_convolution._BlurMaterial.EnableKeyword("OFFSET_EDGE_TEST");
                        else
                            sss_convolution._BlurMaterial.DisableKeyword("OFFSET_EDGE_TEST");

                        if (DitherEdgeTest)
                            sss_convolution._BlurMaterial.EnableKeyword("DITHER_EDGE_TEST");
                        else
                            sss_convolution._BlurMaterial.DisableKeyword("DITHER_EDGE_TEST");
                    }
                    LightingCamera.backgroundColor = cam.backgroundColor;
                    LightingCamera.clearFlags = cam.clearFlags;
                    //LightingCamera.clearFlags = CameraClearFlags.Color;
                    LightingCamera.cullingMask = SSS_Layer;
                    sss_convolution.iterations = ScatteringIterations;

                    if (cam.stereoEnabled)
                        sss_convolution.BlurRadius = (ScatteringRadius / Downsampling) / 2;
                    else
                        sss_convolution.BlurRadius = (ScatteringRadius / Downsampling);

                    LightingCamera.depthTextureMode = DepthTextureMode.DepthNormals;

                    //Stereo
                    if (cam.stereoEnabled)
                    {

                        //Left eye  
                        if (cam.stereoTargetEye == StereoTargetEyeMask.Both || cam.stereoTargetEye == StereoTargetEyeMask.Left)
                        {
                            Shader.SetGlobalInt("SSS_StereoEyeIndex", 0);

                            LightingCamera.stereoTargetEye = StereoTargetEyeMask.Left;

                            //LightingCamera.transform.localPosition = InputTracking.GetLocalPosition(XRNode.LeftEye);
                            //LightingCamera.transform.localRotation = InputTracking.GetLocalRotation(XRNode.LeftEye);

                            LightingCamera.projectionMatrix = cam.GetStereoProjectionMatrix(Camera.StereoscopicEye.Left);
                            LightingCamera.worldToCameraMatrix = cam.GetStereoViewMatrix(Camera.StereoscopicEye.Left);
                            GetRT(ref LightingTex, (int)m_TextureSize.x, (int)m_TextureSize.y, "LightingTexture");
                            GetRT(ref LightingTexBlurred, (int)m_TextureSize.x, (int)m_TextureSize.y, "SSSLightingTextureBlurred");
                            sss_convolution.blurred = LightingTexBlurred;
                            sss_convolution.rtFormat = LightingTex.format;
                            Rendering.RenderToTarget(LightingCamera, LightingTex, LightingPassShader);
                            Shader.SetGlobalTexture("LightingTexBlurred", LightingTexBlurred);
                            Shader.SetGlobalTexture("LightingTex", LightingTex);
                        }
                        //Right eye  
                        if (cam.stereoTargetEye == StereoTargetEyeMask.Both || cam.stereoTargetEye == StereoTargetEyeMask.Right)
                        {
                            Shader.SetGlobalInt("SSS_StereoEyeIndex", 1);

                            LightingCamera.stereoTargetEye = StereoTargetEyeMask.Right;
                            //LightingCamera.transform.localPosition = InputTracking.GetLocalPosition(XRNode.SSS_StereoEyeIndex); 



                            LightingCamera.projectionMatrix = cam.GetStereoProjectionMatrix(Camera.StereoscopicEye.Right);
                            LightingCamera.worldToCameraMatrix = cam.GetStereoViewMatrix(Camera.StereoscopicEye.Right);
                            //LightingCamera.transform.localRotation = InputTracking.GetLocalRotation(XRNode.SSS_StereoEyeIndex);

                            GetRT(ref LightingTexR, (int)m_TextureSize.x, (int)m_TextureSize.y, "LightingTextureR");
                            GetRT(ref LightingTexBlurredR, (int)m_TextureSize.x, (int)m_TextureSize.y, "SSSLightingTextureBlurredR");
                            sss_convolution.blurred = LightingTexBlurredR;
                            sss_convolution.rtFormat = LightingTexR.format;
                            Rendering.RenderToTarget(LightingCamera, LightingTexR, LightingPassShader);
                            Shader.SetGlobalTexture("LightingTexBlurredR", LightingTexBlurredR);
                            Shader.SetGlobalTexture("LightingTexR", LightingTexR);
                        }

                    }
                    else
                    {   //Mono                    
                        Shader.SetGlobalInt("SSS_StereoEyeIndex", 0);

                        LightingCamera.projectionMatrix = cam.projectionMatrix;
                        LightingCamera.worldToCameraMatrix = cam.worldToCameraMatrix;

                        GetRT(ref LightingTex, (int)m_TextureSize.x, (int)m_TextureSize.y, "LightingTexture");
                        GetRT(ref LightingTexBlurred, (int)m_TextureSize.x, (int)m_TextureSize.y, "SSSLightingTextureBlurred");
                        sss_convolution.blurred = LightingTexBlurred;
                        sss_convolution.rtFormat = LightingTex.format;
                        Rendering.RenderToTarget(LightingCamera, LightingTex, LightingPassShader);
                        Shader.SetGlobalTexture("LightingTexBlurred", LightingTexBlurred);
                        Shader.SetGlobalTexture("LightingTex", LightingTex);
                    }

                }

                Profiler.EndSample();

                #endregion


                #region Render Transparency

                Profiler.BeginSample("SSS Transparency");

                if (bEnableTransparency)
                {
                    UpdateCameraModes(cam, TransparencyCamera);
                    TransparencyCamera.allowHDR = cam.allowHDR;
                    if (sss_TransparencyBlur == null)
                        sss_TransparencyBlur = TransparencyCameraGO.GetComponent<SSS_TransparencyBlur>();
                    if (sss_TransparencyBlur && sss_TransparencyBlur._BlurMaterial)
                    {

                        //sss_TransparencyBlur._BlurMaterial.DisableKeyword("EDGE_TEST");//Not needed
                        sss_TransparencyBlur._BlurMaterial.EnableKeyword("TRANSPARENCY");//Specific treatment for this stage
                        sss_TransparencyBlur._BlurMaterial.SetFloat("DepthTest", Mathf.Max(.00001f, DepthTest / 20));
                        maxDistance = Mathf.Max(0, maxDistance);
                        sss_TransparencyBlur._BlurMaterial.SetFloat("maxDistance", maxDistance);
                        sss_TransparencyBlur._BlurMaterial.SetFloat("NormalTest", Mathf.Max(.001f, NormalTest));
                        sss_TransparencyBlur._BlurMaterial.SetFloat("ProfileColorTest", Mathf.Max(.001f, ProfileColorTest));
                        sss_TransparencyBlur._BlurMaterial.SetFloat("ProfileRadiusTest", Mathf.Max(.001f, ProfileRadiusTest));
                        sss_TransparencyBlur._BlurMaterial.SetFloat("EdgeOffset", EdgeOffset);
                        sss_TransparencyBlur._BlurMaterial.SetInt("_SSS_NUM_SAMPLES", TransparencyShaderIterations + 1);

                        sss_TransparencyBlur._BlurMaterial.SetFloat("ForceWhiteTransparencyProfile", ForceWhiteTransparencyProfile ? 1 : 0);

                        if (ForceWhiteTransparencyProfile == true)
                        {
                            sss_TransparencyBlur._BlurMaterial.SetColor("sssColor", new Vector4(1, 1, 1, sssColor.a));

                        }
                        else
                            sss_TransparencyBlur._BlurMaterial.SetColor("sssColor", sssColor);

                        if (Dither)
                        {
                            sss_TransparencyBlur._BlurMaterial.EnableKeyword("RANDOMIZED_ROTATION");
                            sss_TransparencyBlur._BlurMaterial.SetFloat("DitherScale", DitherScale);
                            //sss_convolution._BlurMaterial.SetFloat("DitherSpeed", DitherSpeed * 10);
                            sss_TransparencyBlur._BlurMaterial.SetFloat("DitherIntensity", DitherIntensity);

                            if (NoiseTexture)
                                sss_TransparencyBlur._BlurMaterial.SetTexture("NoiseTexture", NoiseTexture);
                            else
                                Debug.Log("Noise texture not available");
                        }
                        else
                            sss_TransparencyBlur._BlurMaterial.DisableKeyword("RANDOMIZED_ROTATION");

                        if (UseProfileTest && ProfilePerObject)
                            sss_TransparencyBlur._BlurMaterial.EnableKeyword("PROFILE_TEST");
                        else
                            sss_TransparencyBlur._BlurMaterial.DisableKeyword("PROFILE_TEST");



                        if (FixPixelLeaks)
                            sss_TransparencyBlur._BlurMaterial.EnableKeyword("OFFSET_EDGE_TEST");
                        else
                            sss_TransparencyBlur._BlurMaterial.DisableKeyword("OFFSET_EDGE_TEST");

                        if (DitherEdgeTest)
                            sss_TransparencyBlur._BlurMaterial.EnableKeyword("DITHER_EDGE_TEST");

                    }

                    //Shader.EnableKeyword("SSS_TRANSPARENCY");
                    TransparencyCamera.cullingMask = SSS_TransparencyLayer;
                    TransparencyCamera.backgroundColor = cam.backgroundColor;
                    TransparencyCamera.clearFlags = cam.clearFlags;

                    sss_TransparencyBlur.iterations = TransparencyIterations;

                    if (cam.stereoEnabled)
                        sss_TransparencyBlur.BlurRadius = (TransparencyBlurRadius / Downsampling) / 2;
                    else
                        sss_TransparencyBlur.BlurRadius = (TransparencyBlurRadius / Downsampling);

                    //TransparencyCamera.depthTextureMode = DepthTextureMode.DepthNormals;

                    if (cam.stereoEnabled)
                    {    //Left eye   
                        if (cam.stereoTargetEye == StereoTargetEyeMask.Both || cam.stereoTargetEye == StereoTargetEyeMask.Left)
                        {
                            Shader.SetGlobalInt("SSS_StereoEyeIndex", 0);

                            TransparencyCamera.stereoTargetEye = StereoTargetEyeMask.Left;

                            TransparencyCamera.projectionMatrix = cam.GetStereoProjectionMatrix(Camera.StereoscopicEye.Left);
                            TransparencyCamera.worldToCameraMatrix = cam.GetStereoViewMatrix(Camera.StereoscopicEye.Left);
                            GetRT(ref SSS_TransparencyTex, (int)m_TextureSize.x, (int)m_TextureSize.y, "SSS_TransparencyTex");
                            GetRT(ref SSS_TransparencyTexBlurred, (int)m_TextureSize.x, (int)m_TextureSize.y, "SSS_TransparencyTexBlurred");
                            sss_TransparencyBlur.blurred = SSS_TransparencyTexBlurred;
                            sss_TransparencyBlur.rtFormat = SSS_TransparencyTex.format;
                            Rendering.RenderToTarget(TransparencyCamera, SSS_TransparencyTex, null);
                            Shader.SetGlobalTexture("SSS_TransparencyTex", SSS_TransparencyTex);
                            Shader.SetGlobalTexture("SSS_TransparencyTexBlurred", SSS_TransparencyTexBlurred);
                        }
                        //Right eye   
                        if (cam.stereoTargetEye == StereoTargetEyeMask.Both || cam.stereoTargetEye == StereoTargetEyeMask.Right)
                        {
                            Shader.SetGlobalInt("SSS_StereoEyeIndex", 1);

                            TransparencyCamera.stereoTargetEye = StereoTargetEyeMask.Right;

                            TransparencyCamera.projectionMatrix = cam.GetStereoProjectionMatrix(Camera.StereoscopicEye.Right);
                            TransparencyCamera.worldToCameraMatrix = cam.GetStereoViewMatrix(Camera.StereoscopicEye.Right);
                            GetRT(ref SSS_TransparencyTexR, (int)m_TextureSize.x, (int)m_TextureSize.y, "SSS_TransparencyTexR");
                            GetRT(ref SSS_TransparencyTexBlurredR, (int)m_TextureSize.x, (int)m_TextureSize.y, "SSS_TransparencyTexBlurredR");
                            sss_TransparencyBlur.blurred = SSS_TransparencyTexBlurredR;
                            sss_TransparencyBlur.rtFormat = SSS_TransparencyTexR.format;
                            Rendering.RenderToTarget(TransparencyCamera, SSS_TransparencyTexR, null);
                            Shader.SetGlobalTexture("SSS_TransparencyTexR", SSS_TransparencyTexR);
                            Shader.SetGlobalTexture("SSS_TransparencyTexBlurredR", SSS_TransparencyTexBlurredR);
                        }

                    }
                    else
                    {
                        //Mono
                        Shader.SetGlobalInt("SSS_StereoEyeIndex", 0);

                        TransparencyCamera.projectionMatrix = cam.projectionMatrix;
                        TransparencyCamera.worldToCameraMatrix = cam.worldToCameraMatrix;

                        GetRT(ref SSS_TransparencyTex, (int)m_TextureSize.x, (int)m_TextureSize.y, "SSS_TransparencyTex");
                        GetRT(ref SSS_TransparencyTexBlurred, (int)m_TextureSize.x, (int)m_TextureSize.y, "SSS_TransparencyTexBlurred");
                        sss_TransparencyBlur.blurred = SSS_TransparencyTexBlurred;
                        sss_TransparencyBlur.rtFormat = SSS_TransparencyTex.format;

                        Rendering.RenderToTarget(TransparencyCamera, SSS_TransparencyTex, null);
                        Shader.SetGlobalTexture("SSS_TransparencyTex", SSS_TransparencyTex);
                        Shader.SetGlobalTexture("SSS_TransparencyTexBlurred", SSS_TransparencyTexBlurred);



                    }

                }
                else
                {
                    //sss_TransparencyBlur._BlurMaterial.DisableKeyword("TRANSPARENCY");
                    //Shader.DisableKeyword("SSS_TRANSPARENCY");

                    SafeDestroy(SSS_TransparencyTex);
                    SafeDestroy(SSS_TransparencyTexR);
                    SafeDestroy(SSS_TransparencyTexBlurred);
                    SafeDestroy(SSS_TransparencyTexBlurredR);
                }
                Profiler.EndSample();
                #endregion



            }
            else
            {
                LightingCamera.depthTextureMode = DepthTextureMode.None;
                if (sss_buffers_viewer.enabled)
                    sss_buffers_viewer.enabled = false;
            }

            #region Debug
            if (sss_buffers_viewer != null && Enabled)
                switch (toggleTexture)
                {
                    case ToggleTexture.LightingTex:
                        sss_buffers_viewer.InputBuffer = LightingTex;
                        sss_buffers_viewer.enabled = true;
                        break;
                    case ToggleTexture.LightingTexBlurred:
                        sss_buffers_viewer.InputBuffer = LightingTexBlurred;
                        sss_buffers_viewer.enabled = true;
                        break;
                    case ToggleTexture.ProfileTex:
                        sss_buffers_viewer.InputBuffer = SSS_ProfileTex;
                        sss_buffers_viewer.enabled = true;
                        break;
                    case ToggleTexture.TransparencyTex:
                        sss_buffers_viewer.InputBuffer = SSS_TransparencyTex;
                        sss_buffers_viewer.enabled = true;
                        break;
                    case ToggleTexture.None:
                        sss_buffers_viewer.enabled = false;
                        break;
                }
            #endregion
        }

        private void OnPostRender()
        {
            Shader.EnableKeyword("SCENE_VIEW");

        }

        void SafeDestroy(Object obj)
        {
            if (obj != null)
            {
                obj = null;
                DestroyImmediate(obj);
            }
        }

        void Cleanup()
        {
            if (ProfilePerObject)
            {
                SafeDestroy(ProfileCameraGO);
                SafeDestroy(SSS_ProfileTex);
                SafeDestroy(SSS_ProfileTexR);
            }
            SafeDestroy(LightingCameraGO);
            SafeDestroy(TransparencyCameraGO);
            SafeDestroy(LightingTex);
            SafeDestroy(LightingTexR);

            SafeDestroy(LightingTexBlurred);
            SafeDestroy(LightingTexBlurredR);
            //SafeDestroy(sss_buffers_viewer);

            if (bEnableTransparency)
            {
                SafeDestroy(SSS_TransparencyTex);
                SafeDestroy(SSS_TransparencyTexR);
                SafeDestroy(SSS_TransparencyTexBlurred);
                SafeDestroy(SSS_TransparencyTexBlurredR);
            }

            //DirectionalLights.Clear();

            //if (cbSceneCopy != null)
            //{
            //    cam.RemoveCommandBuffer(CameraEvent.BeforeForwardAlpha, cbSceneCopy);
            //    cbSceneCopy = null;
            //}
        }

        // Cleanup all the objects we possibly have created
        void OnDisable()
        {
            Shader.EnableKeyword("SCENE_VIEW");
            Cleanup();
        }

        private void OnGUI()
        {
            if (ShowGUI)
            {
                float verticalDisplacement = 30;
                GUI.color = Color.white;
                Enabled = GUI.Toggle(new Rect(20, verticalDisplacement, 200, 20), Enabled, "Enabled");
                if (LightingTex)
                    GUI.Label(new Rect(20, 20 + verticalDisplacement, 200, 20), "Buffer size: " + LightingTex.width + " x " + LightingTex.height);
                GUI.Label(new Rect(20, 40 + verticalDisplacement, 200, 20), "Screen size: " + Screen.width + " x " + Screen.height);
                GUI.Label(new Rect(20, 60 + verticalDisplacement, 200, 20), "Downscale factor: " + Downsampling.ToString("0.0"));
                Downsampling = GUI.HorizontalSlider(new Rect(20, 80 + verticalDisplacement, 200, 20), Downsampling, 1, 4);
                GUI.Label(new Rect(20, 100 + verticalDisplacement, 200, 20), "Blur size: " + ScatteringRadius.ToString("0.0"));
                ScatteringRadius = GUI.HorizontalSlider(new Rect(20, 120 + verticalDisplacement, 200, 20), ScatteringRadius, 0, 10);
                GUI.Label(new Rect(20, 140 + verticalDisplacement, 200, 20), "Postprocess iterations: " + ScatteringIterations);
                ScatteringIterations = (int)GUI.HorizontalSlider(new Rect(20, 160 + verticalDisplacement, 200, 20), ScatteringIterations, 0, 10);
                GUI.Label(new Rect(20, 180 + verticalDisplacement, 200, 20), "Shader iterations per pass: " + ShaderIterations);

                ShaderIterations = (int)GUI.HorizontalSlider(new Rect(20, 200 + verticalDisplacement, 200, 20), ShaderIterations, 0, 20);
                //GUI.Label(new Rect(20, 220, 200, 20), "Dither: " + Dither);
                Dither = GUI.Toggle(new Rect(20, 220 + verticalDisplacement, 200, 20), Dither, "Dither");
                if (Dither)
                {
                    GUI.Label(new Rect(20, 240 + verticalDisplacement, 200, 20), "Dither scale: " + DitherScale);
                    DitherScale = GUI.HorizontalSlider(new Rect(20, 260 + verticalDisplacement, 200, 20), DitherScale, 0, 5);
                    GUI.Label(new Rect(20, 280 + verticalDisplacement, 200, 20), "Dither intensity: " + DitherIntensity);
                    DitherIntensity = GUI.HorizontalSlider(new Rect(20, 300 + verticalDisplacement, 200, 20), DitherIntensity, 0, .5f);

                }

                if (bEnableTransparency)
                {
                    GUI.Label(new Rect(20, 320 + verticalDisplacement, 200, 20), "Transparency Blur size: " + TransparencyBlurRadius.ToString("0.0"));
                    TransparencyBlurRadius = GUI.HorizontalSlider(new Rect(20, 340 + verticalDisplacement, 200, 20), TransparencyBlurRadius, 0, 10);

                    GUI.Label(new Rect(20, 360 + verticalDisplacement, 200, 20), "Transparency Postprocess iterations: " + TransparencyIterations);
                    TransparencyIterations = (int)GUI.HorizontalSlider(new Rect(20, 380 + verticalDisplacement, 200, 20), TransparencyIterations, 0, 10);

                    GUI.Label(new Rect(20, 400 + verticalDisplacement, 250, 20), "Transparency Shader iterations per pass: " + TransparencyShaderIterations);
                    TransparencyShaderIterations = (int)GUI.HorizontalSlider(new Rect(20, 420 + verticalDisplacement, 200, 20), TransparencyShaderIterations, 0, 10);
                }
            }

        }
    }
}