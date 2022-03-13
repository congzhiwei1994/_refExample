using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class CustomGrassShaderInfo : MonoBehaviour
{
    public enum RenderType
    {
        OnlyDiffuse,
        BlinnPhong,
        SimpleBlinnPhong,
        Idle
    }
    public bool applyLightColor;
    public RenderType renderType = RenderType.BlinnPhong;
    private RenderType lastRenderType = RenderType.BlinnPhong;
    public bool openWindColor = true;
    public bool openShadowColor = true;
    public bool scaleControll = false;
    //public bool lambert = true;
    [Space(5)]
    [Header("========================================")]
    public Color grassBaseTopColor = Color.green;
    public Color grassHueColor = Color.gray;
    public Texture2D terrainColorMap;
    private Vector4 terrainUV;
    [Range(0, 1)]
    public float lerpLambertTerrainColorMap;
    [Range(0, 1)]
    public float colorMapStrenth = 0;

    [Range(0.01f, 1)]
    public float smoothness = 0.5f;
    [ColorUsage(true, true, 0, 8, 0, 8)]
    public Color specularColor = Color.white;
    [Range(0, 1)]
    public float backSpecular = 0.5f;

    [Range(0, 1)]
    public float translucency = 0.85f;

    [ColorUsage(true, true, 0, 8, 0, 8)]
    public Color shadowColor = Color.white;
    [Space(2)]
    [Range(0, 1)]
    public float pbrSmoothness;
    [Range(0, 1)]
    public float pbrMetallic;

    [Space(10)]
    [Header("========================================")]
    [Range(0, 2)]
    public float grassSpeed = 1;
    [Range(0, 1)]
    public float grassSwinging = 1;
    [Range(0, 1)]
    public float grassAnimStrength = 1;
    [Range(0, 1)]
    public float grassRandStrength = 1;
    [Range(0, 1)]
    public float grassRandObj = 1;

    [Space(10)]
    [Header("========================================")]
    public Texture2D windNoiseTex;

    [ColorUsage(true, true, 0, 8, 0, 8)]
    public Color waveColor = Color.white;
    [Range(0, 1)]
    public float windStrength = 0.5f;
    [Range(0, 1)]
    public float windXSpeed = 0.5f;
    [Range(0, 1)]
    public float windZSpeed = 0.5f;

    [Range(-1, 1)]
    public float windXDirect = 0.1f;
    [Range(-1, 1)]
    public float windZDirect = -0.1f;
    [Range(-10, 10)]
    public float waveAmplitude = -0.1f;
    [Range(1, 50)]
    public float waveFrequency = 50;
    private Vector4 waveContro = Vector4.one;

    [Space(10)]
    [Header("========================================")]
    public RenderTexture rtd;
    [Range(-5, 5)]
    public float bendStr = 1.0f;

    [Space(10)]
    [Header("========================================")]
    [Range(0,1)]
    public float scaleStep = 0.45f;


    private Terrain terrain;
    private void OnEnable()
    {        
        Shader.SetGlobalTexture("_PigmentMap", terrainColorMap);
    }
    private void OnDisable()
    {
        Shader.SetGlobalTexture("_PigmentMap", null);
    }
    private void Awake()
    {
        terrain = GameObject.FindObjectOfType<Terrain>();
    }
    void Start()
    {
        if(terrain)
        terrainUV = new Vector4(terrain.terrainData.size.x,terrain.terrainData.size.z,
                                Mathf.Abs(terrain.transform.position.x-1),
                                Mathf.Abs(terrain.transform.position.z-1));
        Shader.SetGlobalVector("_TerrainUV", terrainUV);

        Shader.DisableKeyword("_RENDER_ONLYDIFFUSE");
        Shader.DisableKeyword("_RENDER_BLINNPHONG");
        Shader.DisableKeyword("_RENDER_SIMPLEBLINN");
        Shader.DisableKeyword("_RENDER_PBR");
    }

    // Update is called once per frame
    void Update()
    {
        if (lastRenderType != renderType)
        {
            ShaderEnableKey();
            lastRenderType = renderType;
        }
        SetGlobaGrassInfo();
    }
    void ShaderEnableKey()
    {
        Shader_feature_RenderType(renderType);
    }

    void SetGlobaGrassInfo()
    {
        Shader_feature_ApplyLightColor();
        Shader_feature_WindColor();
        Shader_feature_ShadowColor();
        Shader_feature_ScaleTex();

        //Shader.SetGlobalFloat("Lambert", lambert == true ? 1 : 0);
        Shader.SetGlobalFloat("CustomLambert", lerpLambertTerrainColorMap);
        Shader.SetGlobalColor("BaseColor", grassBaseTopColor);
        Shader.SetGlobalColor("HueColor", grassHueColor);
        Shader.SetGlobalFloat("ColorMapStrenth", colorMapStrenth);

        Shader.SetGlobalFloat("Smoothness", smoothness);
        Shader.SetGlobalColor("SpecularColor", specularColor);
        Shader.SetGlobalFloat("BackSpecular", backSpecular);

        Shader.SetGlobalFloat("Translucency", translucency);

        Shader.SetGlobalColor("ShadowColor", shadowColor);

        Shader.SetGlobalFloat("PbrSmoothness", pbrSmoothness);
        Shader.SetGlobalFloat("PbrMetallic", pbrMetallic);

        Shader.SetGlobalFloat("GrassAnimStrength", grassAnimStrength);
        Shader.SetGlobalFloat("GrassRandStrength", grassRandStrength);
        Shader.SetGlobalFloat("GrassSwinging", grassSwinging);
        Shader.SetGlobalFloat("GrassSpeed", grassSpeed);
        Shader.SetGlobalFloat("GrassRandObj", grassRandObj);


        Shader.SetGlobalTexture("WindNoise", windNoiseTex);
        Shader.SetGlobalColor("WaveColor", waveColor);
        Shader.SetGlobalFloat("WindStrength", windStrength);
        Shader.SetGlobalFloat("WindSpeedX", windXSpeed);
        Shader.SetGlobalFloat("WindSpeedZ", windZSpeed);
        waveContro = new Vector4(windXDirect, windZDirect, waveAmplitude, waveFrequency);
        Shader.SetGlobalVector("WaveControl", waveContro);

        Shader.SetGlobalTexture("RTDTex", rtd);
        Shader.SetGlobalFloat("BendStr", bendStr);

        Shader.SetGlobalFloat("ScaleStep",scaleStep);
    }

    void ShaderSetLerp(string shaderPropretyName, bool state)
    {
        if (state == false)
        {
            Shader.SetGlobalFloat(shaderPropretyName, 0);
        }
        else
        {
            Shader.SetGlobalFloat(shaderPropretyName, 1);
        }
    }

    void Shader_feature_ApplyLightColor()
    {
        if (applyLightColor)
        {
            Shader.EnableKeyword("_APPLYLIGHTCOLOR_ON");
        }
        else
        {
            Shader.DisableKeyword("_APPLYLIGHTCOLOR_ON");
        }
    }

    /// <summary>
    /// 光照类型
    /// </summary>
    /// <param name="renderType"></param>
    void Shader_feature_RenderType(RenderType renderType)
    {
        //Shader.DisableKeyword("_RENDER_ONLYDIFFUSE");
        //Shader.DisableKeyword("_RENDER_BLINNPHONG");
        //Shader.DisableKeyword("_RENDER_SIMPLEBLINN");
        //Shader.DisableKeyword("_RENDER_PBR");
        //_RENDER_ONLYDIFFUSE _RENDER_BLINNPHONG _RENDER_SIMPLEBLINN _RENDER_PBR
        switch (renderType)
        {
            case RenderType.OnlyDiffuse:
                Shader.DisableKeyword("_RENDER_BLINNPHONG");
                Shader.DisableKeyword("_RENDER_SIMPLEBLINN");
                Shader.DisableKeyword("_RENDER_PBR");

                Shader.EnableKeyword("_RENDER_ONLYDIFFUSE");
                break;
            case RenderType.BlinnPhong:
                Shader.DisableKeyword("_RENDER_ONLYDIFFUSE");
                Shader.DisableKeyword("_RENDER_SIMPLEBLINN");
                Shader.DisableKeyword("_RENDER_PBR");

                Shader.EnableKeyword("_RENDER_BLINNPHONG");
                break;
            case RenderType.SimpleBlinnPhong:
                Shader.DisableKeyword("_RENDER_ONLYDIFFUSE");
                Shader.DisableKeyword("_RENDER_BLINNPHONG");
                Shader.DisableKeyword("_RENDER_PBR");

                Shader.EnableKeyword("_RENDER_SIMPLEBLINN");
                break;
            // case RenderType.Pbr:
            //     Shader.DisableKeyword("_RENDER_ONLYDIFFUSE");
            //     Shader.DisableKeyword("_RENDER_BLINNPHONG");
            //     Shader.DisableKeyword("_RENDER_SIMPLEBLINN");

            //     Shader.EnableKeyword("_RENDER_PBR");
            //     break;
            case RenderType.Idle:
                Shader.DisableKeyword("_RENDER_ONLYDIFFUSE");
                Shader.DisableKeyword("_RENDER_SIMPLEBLINN");
                Shader.DisableKeyword("_RENDER_PBR");

                Shader.EnableKeyword("_RENDER_BLINNPHONG");
                break;
        }
    }

    /// <summary>
    /// 风浪颜色
    /// </summary>
    void Shader_feature_WindColor()
    {
        if (openWindColor)
        {
            Shader.EnableKeyword("_WINDCOLOR_ON");
        }
        else
        {
            Shader.DisableKeyword("_WINDCOLOR_ON");
        }
    }

    /// <summary>
    /// 阴影颜色
    /// </summary>
    void Shader_feature_ShadowColor()
    {
        if (openShadowColor)
        {
            Shader.EnableKeyword("_SHADOWCOLOR_ON");
            //Shader.SetGlobalFloat("_ShadowColorT",1);
        }
        else
        {
            Shader.DisableKeyword("_SHADOWCOLOR_ON");
            //Shader.SetGlobalFloat("_ShadowColorT",0);
        }
    }

    /// <summary>
    /// 区域对象缩放控制
    /// </summary>
    void Shader_feature_ScaleTex()
    {
        if (scaleControll)
        {
            Shader.EnableKeyword("_SCALETEXCTR_ON");
        }
        else
        {
            Shader.DisableKeyword("_SCALETEXCTR_ON");
        }
    }
}
