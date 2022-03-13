using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class CustomGrassShaderFullInfo : MonoBehaviour {
 // Start is called before the first frame update
    public Color grassBaseTopColor = Color.green;
    public Color grassRootColor = Color.gray;
    [Range(0, 1)]
    public float rootOffset = 0.5f;
    [Range(0,1)]
    public float smoothness = 0.5f;
    [Range(0, 1)]
    public float windStrength = 0.5f;
    [Range(0,1)]
    public float windXSpeed = 0.5f;
    [Range(0, 1)]
    public float windZSpeed = 0.5f;
    public Vector4 waveContro = Vector4.one;
    public Texture2D windNoiseTex;
    public Transform actor;
    [Range(0, 10)]
    public float pushRadius = 0.5f;
    [Range(0, 10)]
    public float pushStrength = 0.5f;

    public Color fresnelColor = Color.red;
    [Range(0,15)]
    public float fresnelStrength = 2.5f;
    private Terrain terrain;
    public float detailObjectDistance = 2.5f;
    [ColorUsage(true,true,0,8,0,8)]
    public Color specularColor = Color.white;
    public RenderTexture rtd;
    [Range(-2,2)]
    public float bendStr = 1.0f;
    public bool actorType = false;

    [Space(5)]
    public bool cullType = true;
    public float cullStart = 20;
    [HideInInspector]
    public float cullFadeLenth = 5;

    public Texture2D albedo;
    public Texture2D gradient;
    public Texture2D bumpmap;
    [Range(-1,1)]
    public float cutoff;

    [ColorUsage(true, true, 0, 8, 0, 8)]
    public Color shadowColor = Color.white;
    [Range(0,1)]
    public float specularLerp = 1;

    [Range(-2,2)]
    public float heightOffset = 0;

    [ColorUsage(true, true, 0, 8, 0, 8)]
    public Color waveColor = Color.white;
    public bool scaleControll = false;
    [Range(0,1)]
    public float colorMapStrenth = 0;
    [Range(0,1)]
    public float backSpecular=0.5f;
    void Start()
    {
        terrain = GameObject.FindObjectOfType<Terrain>();
        //cullStart = Mathf.Min(cullStart, terrain.detailObjectDistance) - cullFadeLenth;
    }

    // Update is called once per frame
    void Update()
    {
        SetGlobaGrassInfo();
    }

    void SetGlobaGrassInfo()
    {
        Shader.SetGlobalTexture("WindNoise", windNoiseTex);
        Shader.SetGlobalVector("WaveControl", waveContro);
        Shader.SetGlobalFloat("Smoothness", smoothness);
        Shader.SetGlobalFloat("WindStrength", windStrength);
        Shader.SetGlobalFloat("WinsSpeedX", windXSpeed);
        Shader.SetGlobalFloat("WinsSpeedZ", windZSpeed);

        Shader.SetGlobalFloat("RootOffset", rootOffset);

        Shader.SetGlobalColor("BaseColor", grassBaseTopColor);
        Shader.SetGlobalColor("RootColor", grassRootColor);
        if(actor!=null)
        Shader.SetGlobalVector("ActorPos", actor.position);
        Shader.SetGlobalFloat("PushStrength", pushStrength);
        Shader.SetGlobalFloat("ActorRadius", pushRadius);

        Shader.SetGlobalColor("FresnelColor", fresnelColor);
        Shader.SetGlobalFloat("FresnelScale", fresnelStrength);
        if(terrain)
        Shader.SetGlobalFloat("DistanceFade", terrain.detailObjectDistance);

        Shader.SetGlobalFloat("CameraPosW", detailObjectDistance);
        Shader.SetGlobalColor("SpecularColor", specularColor);

        Shader.SetGlobalTexture("RTDTex", rtd);
        Shader.SetGlobalFloat("BendStr", bendStr);

        ShaderSetLerp("ActorType", actorType);
        //if (actorType == false)
        //{
        //    Shader.SetGlobalFloat("ActorType", 0);
        //}
        //else
        //{
        //    Shader.SetGlobalFloat("ActorType", 1);
        //}
        ShaderSetLerp("CULLFADETYPE", cullType);
        Shader.SetGlobalFloat("CullFadeStart", cullStart);

        Shader.SetGlobalTexture("Albedo", albedo);
        Shader.SetGlobalTexture("Gradient", gradient);
        Shader.SetGlobalFloat("CutOffset", cutoff);
        Shader.SetGlobalTexture("BumpMap", bumpmap);
        Shader.SetGlobalColor("ShadowColor",shadowColor);
        Shader.SetGlobalFloat("SpecularLerp",specularLerp);

        Shader.SetGlobalFloat("HeightOffset",heightOffset);

        Shader.SetGlobalColor("WaveColor", waveColor);

        if (scaleControll)
        {
            Shader.EnableKeyword("_SCALETEXCTR_ON");
        }
        else
        {
            Shader.DisableKeyword("_SCALETEXCTR_ON");
        }

        Shader.SetGlobalFloat("ColorMapStrenth",colorMapStrenth);
        Shader.SetGlobalFloat("BackSpecular",backSpecular);
    }

    void ShaderSetLerp(string shaderPropretyName ,bool state)
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
}
