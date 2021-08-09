using System;
using UnityEngine;
using System.Collections;
[ExecuteInEditMode]
public class PartBloom : MonoBehaviour
{
    /// <summary>
    /// 采样率
    /// </summary>
    public float samplerScale = 1;

    /// <summary>
    /// 每次采样增加次数
    /// </summary>
    public float samplerRadius = 0;

    /// <summary>
    ///高亮部分提取阈值
    /// </summary>
    public Color colorThreshold = Color.gray;

    /// <summary>
    ///Bloom泛光颜色
    /// </summary>
    public Color bloomColor = Color.white;

    /// <summary>
    /// Bloom权值
    /// </summary>
    [Range(0.0f, 1f)]
    public float bloomFactor = 0.5f;

    /// <summary>
    /// Bloom材质球
    /// </summary>
    private Material BloomMat;

    /// <summary>
    /// bloom屏幕效果shader
    /// </summary>
    public Shader BloomShader;

    /// <summary>
    /// bloom模糊次数
    /// </summary>
    public int blurNum = 2;

    /// <summary>
    /// 是否使用bloom
    /// </summary>
    public bool UseBloom = true;

    /// <summary>
    /// 当前摄像机渲染图
    /// </summary>
    public RenderTexture cameraRenderTex;

    /// <summary>
    /// 摄像机
    /// </summary>
    private Camera mainCamera;

    #region 缓存shader变量
    private int _colorThreshold;
    private int _samplerScale;
    private int _BlurTexTemp;
    private int _BlurTex;
    private int _bloomColor;
    private int _bloomFactor;

    private void InitPropertyToId()
    {
        _colorThreshold = Shader.PropertyToID("_colorThreshold");
        _samplerScale = Shader.PropertyToID("_samplerScale");
        _BlurTexTemp = Shader.PropertyToID("_BlurTexTemp");
        _BlurTex = Shader.PropertyToID("_BlurTex");
        _bloomColor = Shader.PropertyToID("_bloomColor");
        _bloomFactor = Shader.PropertyToID("_bloomFactor");
    }
    #endregion

    private void Awake()
    {
        InitPropertyToId();
        mainCamera = GetComponent<Camera>();
        mainCamera.allowMSAA = false;
        BloomMat = new Material(BloomShader);
    }

    private void OnDestroy()
    {

    }

    private void OnDisable()
    {

    }

    private void OnEnable()
    {
#if UNITY_EDITOR
        InitPropertyToId();
        if (!Application.isPlaying)
        {
            mainCamera = GetComponent<Camera>();
            mainCamera.allowMSAA = false;
            BloomMat = new Material(BloomShader);
        }
#endif

    }

    private void OnPreRender()
    {
        if (QualitySettings.antiAliasing == 0)
        {
            cameraRenderTex = RenderTexture.GetTemporary(Screen.width, Screen.height, 24, RenderTextureFormat.Default, RenderTextureReadWrite.Default);
        }
        else
        {
            cameraRenderTex = RenderTexture.GetTemporary(Screen.width, Screen.height, 24, RenderTextureFormat.Default, RenderTextureReadWrite.Default, QualitySettings.antiAliasing);
        }
        mainCamera.targetTexture = cameraRenderTex;
    }

    private void OnPostRender()
    {
        mainCamera.targetTexture = null;
        if (UseBloom)
        {
            if (BloomMat)
            {
                //根据阈值提取高亮部分,使用pass0进行高亮提取
                RenderTexture ThresholdMaskTex = RenderTexture.GetTemporary(cameraRenderTex.width / 2, cameraRenderTex.height / 2, 0, RenderTextureFormat.Default);
                BloomMat.SetVector(_colorThreshold, colorThreshold);
                Graphics.Blit(cameraRenderTex, ThresholdMaskTex, BloomMat, 0);

                RenderTexture AddBlurt = RenderTexture.GetTemporary((int)cameraRenderTex.width / 4, (int)cameraRenderTex.height / 4, 0, RenderTextureFormat.ARGBHalf);

                //进行模糊和模糊效果叠加
                for (int i = 0; i < blurNum; i++)
                {
                    //计算分辨率几分几处理模糊效果（1/4,1/8,1/16,1/32）
                    int BlurPart = (int)Mathf.Pow(2, (i + 2));
                    RenderTexture blurTemp = RenderTexture.GetTemporary((int)cameraRenderTex.width / BlurPart, (int)cameraRenderTex.height / BlurPart, 0, RenderTextureFormat.ARGBHalf);
                    BloomMat.SetFloat(_samplerScale, samplerScale + i * samplerRadius);
                    Graphics.Blit(ThresholdMaskTex, blurTemp, BloomMat, 1);
                    RenderTexture.ReleaseTemporary(ThresholdMaskTex);
                    ThresholdMaskTex = blurTemp;

                    //模糊叠加
                    if (i == 0)
                    {
                        Graphics.Blit(ThresholdMaskTex, AddBlurt);
                    }
                    else
                    {
                        BloomMat.SetTexture(_BlurTexTemp, ThresholdMaskTex);
                        RenderTexture AddBlurtTemp = RenderTexture.GetTemporary((int)cameraRenderTex.width / 4, (int)cameraRenderTex.height / 4, 0, RenderTextureFormat.Default);
                        Graphics.Blit(AddBlurt, AddBlurtTemp, BloomMat, 3);
                        RenderTexture.ReleaseTemporary(AddBlurt);
                        AddBlurt = AddBlurtTemp;
                    }
                }

                //Bloom，将模糊后的图作为Material的Blur图参数
                BloomMat.SetTexture(_BlurTex, AddBlurt);
                //bloom叠加颜色
                BloomMat.SetVector(_bloomColor, bloomColor);
                //bloom效果权值
                BloomMat.SetFloat(_bloomFactor, bloomFactor);
                //使用pass2进行景深效果计算，清晰场景图直接从source输入到shader的_MainTex中
                Graphics.Blit(cameraRenderTex, null as RenderTexture, BloomMat, 2);
                RenderTexture.ReleaseTemporary(ThresholdMaskTex);
                RenderTexture.ReleaseTemporary(AddBlurt);
                RenderTexture.ReleaseTemporary(cameraRenderTex);
            }
        }
        else
        {
            Graphics.Blit(cameraRenderTex, null as RenderTexture);
            RenderTexture.ReleaseTemporary(cameraRenderTex);
        }
    }
}


