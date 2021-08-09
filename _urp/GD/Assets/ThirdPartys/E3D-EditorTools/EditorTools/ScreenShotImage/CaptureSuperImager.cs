//******************************************************
//
//	File Name 	: 		CaptureSuperImager.cs
//	
//	Author  	:		dust Taoist

//	CreatTime   :		8/16/2019 18:16
//******************************************************
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using System.IO;

/// <summary>
/// The camera capture
/// </summary>
public class CaptureSuperImager : MonoBehaviour
{
    [Header("Magnification")]
    public int size = 1;

    void Update()
    {
        //Shortcut screenshot
        if (Input.GetKeyDown(KeyCode.F9))
        {
            Screen.SetResolution((int)pixelSize.x, (int)pixelSize.y, false);
            UnityEngine.ScreenCapture.CaptureScreenshot(Application.dataPath + "/" + savePath + "ASDAS.png", size);
            Debug.Log("Screenshot of success");
        }
    }
    /// <summary>
    /// Capture path
    /// </summary>
    string temePath;


    /// <summary>
    /// The file suffix
    /// </summary>
    string fileEx = ".png";
    /// <summary>
    /// target path
    /// </summary>
    string targetFolderPath;
    string dicPath;
    /// <summary>
    /// File path attribute
    /// </summary>
    public string DicPath
    {
        get { return dicPath; }
    }
    public void GetCapytureScreenShot()
    {
        if (Application.isPlaying)
            Screen.SetResolution((int)pixelSize.x, (int)pixelSize.y, false);

        targetFolderPath = Application.dataPath.Substring(0, Application.dataPath.LastIndexOf("/"));
        Debug.Log(targetFolderPath);
        dicPath = targetFolderPath + "/" + savePath;
        if (Directory.Exists(dicPath) == false)
        {
            Directory.CreateDirectory(dicPath);
        }
        temePath = targetFolderPath + "/" + savePath + "/" + fileName + fileEx;
        UnityEngine.ScreenCapture.CaptureScreenshot(temePath, size);
        Debug.Log("The screenshot has been saved to:" + temePath);
    }


    // Pixel size
    public Vector2 pixelSize;
    // Save the path
    public string savePath = "CameShotSave";
    // The file name
    public string fileName = "cameraCapture";

#if UNITY_EDITOR
    private void Reset()
    {
        pixelSize = new Vector2(Screen.currentResolution.width, Screen.currentResolution.height);
    }
#endif
}



