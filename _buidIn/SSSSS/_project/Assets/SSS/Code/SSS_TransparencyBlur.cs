using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Profiling;
namespace SSS
{
    [ExecuteInEditMode]
    public class SSS_TransparencyBlur : MonoBehaviour
    {
        Shader DepthCopyShader;
        Material DepthCopyMaterial;
        //public bool Enabled = true;
        float FOV_compensation = 0;
        float initFOV;
        [HideInInspector] public bool AllowMSAA;
        [HideInInspector]
        [Range(0, 1f)]
        public float BlurRadius = 1;
        [HideInInspector]
        public Shader BlurShader = null;
        Camera _ThisCamera;
        [HideInInspector]
        public RenderTextureFormat rtFormat;
        [HideInInspector]
        public Material _BlurMaterial = null;
        Material BlurMaterial
        {
            get
            {
                if (_BlurMaterial == null && BlurShader)
                {
                    _BlurMaterial = new Material(BlurShader);
                    _BlurMaterial.hideFlags = HideFlags.HideAndDontSave;
                }
                return _BlurMaterial;
            }
        }
        [HideInInspector]
        [Range(0, 10)]
        public int iterations = 3;
        Camera ParentCamera;
        SSS sss;

        void OnEnable()
        {
            DepthCopyShader = Shader.Find("Hidden/CopyDepth");
            if (DepthCopyMaterial == null)
                DepthCopyMaterial = new Material(DepthCopyShader);

            DepthCopyMaterial.hideFlags = HideFlags.HideAndDontSave;

            _ThisCamera = gameObject.GetComponent<Camera>();
            try
            {
                ParentCamera = transform.parent.GetComponent<Camera>();
            }
            catch
            {
                ParentCamera = FindObjectOfType<SSS>().GetComponent<Camera>();
            }

            initFOV = ParentCamera.fieldOfView;
            sss = ParentCamera.GetComponent<SSS>();

        }
        //private void Update()
        //{
        //    if (Input.GetKeyDown(KeyCode.P))
        //        Enabled = !Enabled;
        //}
        // Called by the camera to apply the image effect
        //[SerializeField]
        RenderTexture buffer;
        [HideInInspector]
        public RenderTexture blurred;
        int AA = 1;

       // [ImageEffectOpaque] //Allow me to render transparencies here
        void OnRenderImage(RenderTexture source, RenderTexture destination)
        {

            // if (Enabled)
            {
                FOV_compensation = initFOV / _ThisCamera.fieldOfView;
                //BlurMaterial.SetFloat("BlurRadius", BlurRadius * FOV_compensation);

                int rtW = source.width;
                int rtH = source.height;

                BlurRadius *= FOV_compensation;
              
                Vector2 BlurRadiusCorrected = new Vector2(
                    Screen.width * BlurRadius * .002f,
                    Screen.height * BlurRadius * .002f
                    );

                //float ratio = rtW / rtH;
                //print(ratio);
                //https://github.com/Heep042/Unity-Graphics-Demo/blob/master/Assets/Standard%20Assets/Effects/ImageEffects/Scripts/Bloom.cs
                if (_ThisCamera.allowMSAA && QualitySettings.antiAliasing > 0 && AllowMSAA)
                    AA = QualitySettings.antiAliasing;
                else
                    AA = 1;

                Profiler.BeginSample("Transparency copy light pass");
                buffer = RenderTexture.GetTemporary(rtW, rtH, 0, rtFormat, RenderTextureReadWrite.Linear, AA);

                if (sss.bEnableTransparency)
                {
                    Graphics.Blit(source, buffer, DepthCopyMaterial);
                    Graphics.Blit(buffer, source);//merge back
                }
                else
                    Graphics.Blit(source, buffer);

                Profiler.EndSample();

                Profiler.BeginSample("Transparency blur");
                for (int i = 0; i < iterations; i++)
                {
                    // Blur vertical
                    RenderTexture buffer2 = RenderTexture.GetTemporary(rtW, rtH, 0, rtFormat, RenderTextureReadWrite.Linear, AA);
                    BlurMaterial.SetVector("_TexelOffsetScale", new Vector4(0, BlurRadiusCorrected.y, 0, 0));
                    Graphics.Blit(buffer, buffer2, BlurMaterial);
                    RenderTexture.ReleaseTemporary(buffer);
                    buffer = buffer2;

                    // Blur horizontal
                    buffer2 = RenderTexture.GetTemporary(rtW, rtH, 0, rtFormat, RenderTextureReadWrite.Linear, AA);
                    BlurMaterial.SetVector("_TexelOffsetScale", new Vector4(BlurRadiusCorrected.x, 0, 0, 0));
                    Graphics.Blit(buffer, buffer2, BlurMaterial);
                    RenderTexture.ReleaseTemporary(buffer);
                    buffer = buffer2;

                }
                Profiler.EndSample();

                Debug.Assert(blurred);

                Profiler.BeginSample("Transparency close blur");

                Graphics.Blit(buffer, blurred);

                Graphics.Blit(source, destination);
                RenderTexture.ReleaseTemporary(buffer);
                Profiler.EndSample();

            }
            //else
            //{
            //    Graphics.Blit(source, destination);
            //    Graphics.Blit(source, blurred);
            //}
        }
    }



}