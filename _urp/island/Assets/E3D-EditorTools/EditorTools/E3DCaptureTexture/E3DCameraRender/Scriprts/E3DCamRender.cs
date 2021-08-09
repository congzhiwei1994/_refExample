//******************************************************
//
//	文件名 (File Name) 	: 		MyTools
//	
//	脚本创建者(Author) 	:		E3D

//	创建时间 (CreatTime):		2019/12/11/15/5/33
//******************************************************

using E3DCommonTools;
using System.Collections;
using UnityEditor;
using UnityEngine;

[ExecuteInEditMode]
public class E3DCamRender : MonoBehaviour
{
    [HideInInspector] public int toolIndex = 0;

    [HideInInspector] public MyImageType_2018 outImagType = MyImageType_2018.PNG;

    [HideInInspector] public MyScreenShotImageType outScreenType = MyScreenShotImageType.RGBA;
    private MyScreenShotImageType currentType = MyScreenShotImageType.RGBA;
    [HideInInspector] public MyImageSize outGamveSize = MyImageSize._512;
    [HideInInspector] public int customWidth = 1;

    [HideInInspector] public Camera m_mainCamera;
    [HideInInspector] public Shader depthShader;
    [HideInInspector] public Shader depthNormalShader;
    [HideInInspector] public int cameraHeight = 15;

    [HideInInspector] public Material depthMat;

    public void SetIdleCameraRender()
    {
        if (m_mainCamera)
        {
            m_mainCamera.ResetReplacementShader();
        }
    }

    E3DCameraRenderCtr cameraDepthCtr;
    private void Update()
    {
        if (currentType != outScreenType)
        {
            currentType = outScreenType;
            if (cameraDepthCtr == null)
            {
                cameraDepthCtr = gameObject.transform.GetChild(0).GetComponent<E3DCameraRenderCtr>();
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
            Debug.Log("Change to Depth Model");
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
            Debug.Log("Capture Image Finish-->" + fileName);
#if UNITY_EDITOR
            UnityEditor.AssetDatabase.Refresh();
            EditorApplication.isPlaying = false;
#endif
        }
    }
}


