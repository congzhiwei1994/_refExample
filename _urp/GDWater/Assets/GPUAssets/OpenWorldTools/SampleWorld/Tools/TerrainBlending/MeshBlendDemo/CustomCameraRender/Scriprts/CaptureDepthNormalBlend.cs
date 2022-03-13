//******************************************************
//
//	文件名 (File Name) 	: 		CaptureDepthNormalBlend
//	
//	脚本创建者(Author) 	:		Ejoy_小林

//	创建时间 (CreatTime):		2019/12/11/15/5/33
//******************************************************

using ClTools;
using System.Collections;
using UnityEngine;

[ExecuteInEditMode]
public class CaptureDepthNormalBlend : MonoBehaviour
{
    [HideInInspector] public int toolIndex = 1;

    [HideInInspector] public MyImageType_2018 outImagType = MyImageType_2018.JPG;

    [HideInInspector] public MyScreenShotImageType outScreenType = MyScreenShotImageType.RGBA;
    private MyScreenShotImageType currentType = MyScreenShotImageType.RGBA;
    [HideInInspector] public MyImageSize outGamveSize = MyImageSize._720p;
    [HideInInspector] public int customWidth = 1;

    [HideInInspector] public Camera m_mainCamera;
    [HideInInspector] public Shader depthShader;
    [HideInInspector] public Shader depthNormalShader;
    [HideInInspector] public int cameraHeight = 15;

    [HideInInspector] public Material depthMat;
    [HideInInspector] public bool useTN = false;
    [HideInInspector] public Texture2D tnNormalTex;
    private void Start()
    {

    }
    public void SetIdleCameraRender()
    {
        if (m_mainCamera)
        {
            m_mainCamera.ResetReplacementShader();
        }
    }
    CustomCameraRenderCtr cameraDepthCtr;
    private void Update()
    {
        if (currentType == MyScreenShotImageType.DepthNormal)
        {
            cameraDepthCtr.USETN = useTN;
            cameraDepthCtr.TNTEX = tnNormalTex;
        }
        if (currentType != outScreenType)
        {
            currentType = outScreenType;
            if (cameraDepthCtr == null)
            {
                cameraDepthCtr = gameObject.transform.GetChild(0).GetComponent<CustomCameraRenderCtr>();
            }
            cameraDepthCtr.MyScreenShotType = outScreenType;
        }

    }

    public void ChangToDepthModel()
    {
        if (m_mainCamera)
        {
            Shader.SetGlobalFloat("_CameraHeight", cameraHeight);
            m_mainCamera.SetReplacementShader(depthShader, "RenderType");
            Debug.Log("切换到深度模式");
        }
    }
    public void ChangToDepthNormalModel()
    {
        if (m_mainCamera)
        {
            m_mainCamera.SetReplacementShader(depthNormalShader, "RenderType");
        }
    }

    public void CustomScreenShotTex(string filePath, MyImageType_2018 imgeType)
    {
        outImagType = imgeType;
        StartCoroutine(ScreenShotTex(filePath));
    }

    IEnumerator ScreenShotTex(string fileName)
    {
        yield return new WaitForEndOfFrame();
        Texture2D tex = UnityEngine.ScreenCapture.CaptureScreenshotAsTexture();
        byte[] bytes = new byte[] { };
        switch (outImagType)
        {
            case MyImageType_2018.JPG:
                bytes = tex.EncodeToJPG();
                break;
            case MyImageType_2018.PNG:
                bytes = tex.EncodeToPNG();
                break;
#if UNITY_2018_1_OR_NEWER
            case MyImageType_2018.TGA:     
                bytes = tex.EncodeToTGA();
                break;
#endif
            default:
                bytes = tex.EncodeToEXR();
                break;
        }
        if (bytes != null)
        {
            System.IO.File.WriteAllBytes(fileName, bytes);
            Debug.Log("截图纹理成功-->" + fileName);
#if UNITY_EDITOR
            UnityEditor.AssetDatabase.Refresh();//刷新Unity的资产目录
#endif
        }
    }
}


