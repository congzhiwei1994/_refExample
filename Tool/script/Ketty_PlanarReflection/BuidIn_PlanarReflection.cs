using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;

[ExecuteInEditMode]
public class BuidIn_PlanarReflection : MonoBehaviour {
    public LayerMask _reflectionMask = -1;
    public bool _reflectSkybox = false;
    Color _clearColor = Color.black;

    const string _reflectionSampler = "_ReflectionTex";
    public float _clipPlaneOffset = 0.07F;

    Vector3 _oldpos;
    Camera _reflectionCamera;
    RenderTexture _bluredReflectionTexture;
    Material _sharedMaterial;

    public bool _blurOn = true;

    [Range (0.0f, 5.0f)]
    public float _blurSize = 1;
    public int _blurIterations = 2;
    public float _downsample = 1;

#if UNITY_EDITOR
    bool _oldBlurOn;
    float _oldBlurSize;
#endif

    private Shader _blurShader;
    private Material _blurMaterial;

    private static bool s_InsideWater;

    Material BlurMaterial {
        get {
            if (_blurMaterial == null) {
                _blurMaterial = new Material (_blurShader);
                return _blurMaterial;
            }
            return _blurMaterial;
        }
    }

#if UNITY_EDITOR
    void Awake () {
        _oldBlurOn = _blurOn;
        _oldBlurSize = _blurSize;
    }
#endif

    void Start () {
        _sharedMaterial = GetComponent<MeshRenderer> ().sharedMaterial;
        if (_blurShader == null)
            _blurShader = Shader.Find ("Hidden/KawaseBlur");
    }

    Camera CreateReflectionCameraFor (Camera cam) {
        String reflName = gameObject.name + "Reflection" + cam.name;
        GameObject go = new GameObject (reflName);
        go.hideFlags = HideFlags.HideAndDontSave;
        Camera reflectCamera = go.AddComponent<Camera> ();

        reflectCamera.backgroundColor = _clearColor;
        reflectCamera.clearFlags = _reflectSkybox ? CameraClearFlags.Skybox : CameraClearFlags.SolidColor;

        SetStandardCameraParameter (reflectCamera, _reflectionMask);

        if (!reflectCamera.targetTexture) {
            reflectCamera.targetTexture = CreateTexture ();
        }

        return reflectCamera;
    }

    void SetStandardCameraParameter (Camera cam, LayerMask mask) {
        cam.cullingMask = mask;
        cam.backgroundColor = Color.black;
        cam.enabled = false;
    }

    RenderTexture CreateTexture () {
#if UNITY_EDITOR
        RenderTexture rt = new RenderTexture (Mathf.FloorToInt (Screen.width), Mathf.FloorToInt (Screen.height * 0.5f), 16);
#else
        RenderTexture rt = new RenderTexture (Mathf.FloorToInt (Screen.width * 0.5f), Mathf.FloorToInt (Screen.height * 0.5f), 16);
#endif
        rt.hideFlags = HideFlags.DontSave;
        return rt;
    }

    void OnWillRenderObject () {
        Camera currentCam = Camera.current;
        if (!currentCam) {
            return;
        }

#if !UNITY_EDITOR
        if (!currentCam.gameObject.CompareTag ("MainCamera"))
            return;
#endif

#if UNITY_EDITOR
        if (!_bluredReflectionTexture)
            _bluredReflectionTexture = CreateTexture ();
#else
        if (_blurOn) {
            if (!_bluredReflectionTexture)
                _bluredReflectionTexture = CreateTexture ();
        }
#endif

        if (s_InsideWater) {
            return;
        }
        s_InsideWater = true;

        if (!_reflectionCamera) {
            _reflectionCamera = CreateReflectionCameraFor (currentCam);
        }

        RenderReflectionFor (currentCam, _reflectionCamera);

        if (_reflectionCamera && _sharedMaterial) {
            if (_blurOn) {
                PostProcessTexture (currentCam, _reflectionCamera.targetTexture, _bluredReflectionTexture);
                _sharedMaterial.SetTexture (_reflectionSampler, _bluredReflectionTexture);
            } else {
                _sharedMaterial.SetTexture (_reflectionSampler, _reflectionCamera.targetTexture);
            }
        }

        s_InsideWater = false;
    }

#if UNITY_EDITOR
    bool _blurParamChanged;
    void Update () {
        if (_blurParamChanged) {
            _oldBlurOn = _blurOn;
            _oldBlurSize = _blurSize;
        }

        if (_blurOn != _oldBlurOn || _blurSize != _oldBlurSize) {
            _blurParamChanged = true;
        }
    }
#endif

    void RenderReflectionFor (Camera cam, Camera reflectCamera) {
        if (!reflectCamera) {
            return;
        }

        if (_sharedMaterial && !_sharedMaterial.HasProperty (_reflectionSampler)) {
            return;
        }

        reflectCamera.cullingMask = _reflectionMask;

        SaneCameraSettings (reflectCamera);

        reflectCamera.backgroundColor = _clearColor;
        reflectCamera.clearFlags = _reflectSkybox ? CameraClearFlags.Skybox : CameraClearFlags.SolidColor;
        if (_reflectSkybox) {
            if (cam.gameObject.GetComponent (typeof (Skybox))) {
                Skybox sb = (Skybox) reflectCamera.gameObject.GetComponent (typeof (Skybox));
                if (!sb) {
                    sb = (Skybox) reflectCamera.gameObject.AddComponent (typeof (Skybox));
                }
                sb.material = ((Skybox) cam.GetComponent (typeof (Skybox))).material;
            }
        }

        bool isInvertCulling = GL.invertCulling;
        GL.invertCulling = true;

        Transform reflectiveSurface = transform; //waterHeight;

        Vector3 eulerA = cam.transform.eulerAngles;

        reflectCamera.transform.eulerAngles = new Vector3 (-eulerA.x, eulerA.y, eulerA.z);
        reflectCamera.transform.position = cam.transform.position;

        Vector3 pos = reflectiveSurface.transform.position;
        pos.y = reflectiveSurface.position.y;
        Vector3 normal = reflectiveSurface.transform.up;
        float d = -Vector3.Dot (normal, pos) - _clipPlaneOffset;
        Vector4 reflectionPlane = new Vector4 (normal.x, normal.y, normal.z, d);

        Matrix4x4 reflection = Matrix4x4.zero;
        reflection = CalculateReflectionMatrix (reflection, reflectionPlane);
        _oldpos = cam.transform.position;
        Vector3 newpos = reflection.MultiplyPoint (_oldpos);

        reflectCamera.worldToCameraMatrix = cam.worldToCameraMatrix * reflection;

        Vector4 clipPlane = CameraSpacePlane (reflectCamera, pos, normal, 1.0f);

        Matrix4x4 projection = cam.projectionMatrix;
        projection = CalculateObliqueMatrix (projection, clipPlane);
        reflectCamera.projectionMatrix = projection;

        reflectCamera.transform.position = newpos;
        Vector3 euler = cam.transform.eulerAngles;
        reflectCamera.transform.eulerAngles = new Vector3 (-euler.x, euler.y, euler.z);

        reflectCamera.Render ();

        GL.invertCulling = isInvertCulling;
    }

    void SaneCameraSettings (Camera helperCam) {
        helperCam.depthTextureMode = DepthTextureMode.None;
        helperCam.backgroundColor = Color.black;
        helperCam.clearFlags = CameraClearFlags.SolidColor;
        helperCam.renderingPath = RenderingPath.Forward;
    }

    static Matrix4x4 CalculateObliqueMatrix (Matrix4x4 projection, Vector4 clipPlane) {
        Vector4 q = projection.inverse * new Vector4 (
            Sgn (clipPlane.x),
            Sgn (clipPlane.y),
            1.0F,
            1.0F
        );
        Vector4 c = clipPlane * (2.0F / (Vector4.Dot (clipPlane, q)));
        // third row = clip plane - fourth row
        projection[2] = c.x - projection[3];
        projection[6] = c.y - projection[7];
        projection[10] = c.z - projection[11];
        projection[14] = c.w - projection[15];

        return projection;
    }

    static Matrix4x4 CalculateReflectionMatrix (Matrix4x4 reflectionMat, Vector4 plane) {
        reflectionMat.m00 = (1.0F - 2.0F * plane[0] * plane[0]);
        reflectionMat.m01 = (-2.0F * plane[0] * plane[1]);
        reflectionMat.m02 = (-2.0F * plane[0] * plane[2]);
        reflectionMat.m03 = (-2.0F * plane[3] * plane[0]);

        reflectionMat.m10 = (-2.0F * plane[1] * plane[0]);
        reflectionMat.m11 = (1.0F - 2.0F * plane[1] * plane[1]);
        reflectionMat.m12 = (-2.0F * plane[1] * plane[2]);
        reflectionMat.m13 = (-2.0F * plane[3] * plane[1]);

        reflectionMat.m20 = (-2.0F * plane[2] * plane[0]);
        reflectionMat.m21 = (-2.0F * plane[2] * plane[1]);
        reflectionMat.m22 = (1.0F - 2.0F * plane[2] * plane[2]);
        reflectionMat.m23 = (-2.0F * plane[3] * plane[2]);

        reflectionMat.m30 = 0.0F;
        reflectionMat.m31 = 0.0F;
        reflectionMat.m32 = 0.0F;
        reflectionMat.m33 = 1.0F;

        return reflectionMat;
    }

    static float Sgn (float a) {
        if (a > 0.0F) {
            return 1.0F;
        }
        if (a < 0.0F) {
            return -1.0F;
        }
        return 0.0F;
    }

    Vector4 CameraSpacePlane (Camera cam, Vector3 pos, Vector3 normal, float sideSign) {
        Vector3 offsetPos = pos + normal * _clipPlaneOffset;
        Matrix4x4 m = cam.worldToCameraMatrix;
        Vector3 cpos = m.MultiplyPoint (offsetPos);
        Vector3 cnormal = m.MultiplyVector (normal).normalized * sideSign;

        return new Vector4 (cnormal.x, cnormal.y, cnormal.z, -Vector3.Dot (cpos, cnormal));
    }

    private Dictionary<Camera, CommandBuffer> _cameras = new Dictionary<Camera, CommandBuffer> ();

    void PostProcessTexture (Camera cam, RenderTexture source, RenderTexture dest) {
        //�����б仯��Ҫˢ��commandbuffer
#if UNITY_EDITOR
        if (_blurParamChanged) {
            if (_cameras.ContainsKey (cam))
                cam.RemoveCommandBuffer (CameraEvent.BeforeForwardOpaque, _cameras[cam]);
            _cameras.Remove (cam);
        }
#endif
        //�Ѿ�������commandbuffer�Ͳ�����ִ����
        if (_cameras.ContainsKey (cam))
            return;

        CommandBuffer buf = new CommandBuffer ();
        buf.name = "Blur Reflection Texture";
        _cameras[cam] = buf;
        float width = source.width;
        float height = source.height;
        int rtW = Mathf.RoundToInt (width / _downsample);
        int rtH = Mathf.RoundToInt (height / _downsample);

        int blurredID = Shader.PropertyToID ("_Temp1");
        int blurredID2 = Shader.PropertyToID ("_Temp2");
        buf.GetTemporaryRT (blurredID, rtW, rtH, 0, FilterMode.Bilinear, source.format);
        buf.GetTemporaryRT (blurredID2, rtW, rtH, 0, FilterMode.Bilinear, source.format);

        buf.Blit ((Texture) source, blurredID);
        for (int i = 0; i < _blurIterations; i++) {
            float iterationOffs = (i * 1.0f);
            buf.SetGlobalFloat ("_Offset", iterationOffs / _downsample + _blurSize);
            buf.Blit (blurredID, blurredID2, BlurMaterial, 0);
            buf.Blit (blurredID2, blurredID, BlurMaterial, 0);
        }
        buf.Blit (blurredID, dest);

        buf.ReleaseTemporaryRT (blurredID);
        buf.ReleaseTemporaryRT (blurredID2);

        cam.AddCommandBuffer (CameraEvent.BeforeForwardOpaque, buf);
    }

}