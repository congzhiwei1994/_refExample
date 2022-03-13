using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using ClTools;
public class CustomCameraRenderCtr : MonoBehaviour
{

    private Camera m_camera;

    private MyScreenShotImageType myScreenShotImageType = MyScreenShotImageType.RGBA;
    public MyScreenShotImageType MyScreenShotType
    {
        get
        {
            return myScreenShotImageType;
        }
        set
        {
            myScreenShotImageType = value;
        }
    }

    private MyScreenShotImageType currentType;
    private Material depthMat;
    private Material depthNormalMat;

    const string depthShaderPath = "Cl/PrintDepth";
    const string depthNormalShaderPath = "Cl/WN";
    const string tnTexPropertyName = "TN";
    [SerializeField]
    private bool useTN;
    public bool USETN
    {
        get { return useTN; }
        set { useTN = value; }
    }
    [SerializeField]
    private Texture2D tnTex;
    public Texture2D TNTEX
    {
        get { return tnTex; }
        set { tnTex = value; }
    }
    void Start()
    {
        m_camera = this.GetComponent<Camera>();
        m_camera.depthTextureMode = DepthTextureMode.Depth | DepthTextureMode.DepthNormals;


        depthMat = new Material(Shader.Find(depthShaderPath));
        depthNormalMat = new Material(Shader.Find(depthNormalShaderPath));

    }


    void Update()
    {
        if (currentType != myScreenShotImageType)
            currentType = myScreenShotImageType;
        if (currentType == MyScreenShotImageType.DepthNormal)
        {
            if (depthNormalMat && useTN)
            {
                depthNormalMat.SetFloat("NType", 1);
                depthNormalMat.SetTexture(tnTexPropertyName, tnTex);
            }
        }
    }

    void OnRenderImage(RenderTexture src, RenderTexture dest)
    {
        m_camera.ResetReplacementShader();
        switch (currentType)
        {
            case MyScreenShotImageType.RGBA:
                Graphics.Blit(src, dest);
                break;
            case MyScreenShotImageType.Depth:
                if (depthMat)
                    Graphics.Blit(src, dest, depthMat);
                break;
            case MyScreenShotImageType.DepthNormal:
                Graphics.Blit(src, dest);
                m_camera.SetReplacementShader(depthNormalMat.shader, "RenderType");
                break;
        }
    }
}
