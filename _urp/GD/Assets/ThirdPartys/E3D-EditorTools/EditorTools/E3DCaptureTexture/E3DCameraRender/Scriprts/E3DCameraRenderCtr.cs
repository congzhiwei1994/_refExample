using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using E3DCommonTools;

public class E3DCameraRenderCtr : MonoBehaviour
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

    const string depthShaderPath = "E3D/PrintDepth";
    const string depthNormalShaderPath = "E3D/DepthNormal";

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
