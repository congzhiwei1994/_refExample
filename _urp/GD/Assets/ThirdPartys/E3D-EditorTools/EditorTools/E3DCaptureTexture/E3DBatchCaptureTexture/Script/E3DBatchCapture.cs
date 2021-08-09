using System.Collections;
using System.Collections.Generic;
using System.IO;
using UnityEditor;
using UnityEngine;

public class E3DBatchCapture : MonoBehaviour
{
    public UnityEngine.Object InputFolder;
    public string property = "_MainTex";
    public UnityEngine.Object OutputFolder;

    Texture2D[] _texturesGroup;
    string _inputTextureFolderPath;
    string _outputTextureFolderPath;
    public Material _material;

    public void InputEntrance()
    {
        ReadAllTexture();
    }

    public void OutputEntrance()
    {
        _material = transform.GetComponent<MeshRenderer>().sharedMaterial;
        _outputTextureFolderPath = AssetDatabase.GetAssetPath(OutputFolder);
        //Debug.Log(_outputTextureFolderPath);
        foreach (var tex in _texturesGroup)
        {
            if (_material.HasProperty(property))
            {
                Debug.Log(_material);
                _material.SetTexture(property, tex);
                string path = _outputTextureFolderPath + "/" + tex.name + ".png";
                //TakeShot(path);
                TakeShotExtension(path);
            }
        }

        

    }

    void ReadAllTexture()
    {
        _texturesGroup = null;
        //================================================================//
        _inputTextureFolderPath = AssetDatabase.GetAssetPath(InputFolder);
        if (_inputTextureFolderPath.Contains("Resources"))
        {
            int index = _inputTextureFolderPath.IndexOf("Resources") + 10;
            _inputTextureFolderPath = _inputTextureFolderPath.Substring(index);
            _inputTextureFolderPath += "/";
            _texturesGroup = Resources.LoadAll<Texture2D>(_inputTextureFolderPath);
        }
        Debug.Log(_texturesGroup.Length);
        //================================================================//
    }


    private void TakeShot(string path)
    {
        int resolutionX = (int)Handles.GetMainGameViewSize().x;
        int resolutionY = (int)Handles.GetMainGameViewSize().y;
        RenderTexture rt = new RenderTexture(resolutionX, resolutionY, 24);
        Camera.main.targetTexture = rt;
        Texture2D screenShot = new Texture2D(resolutionX, resolutionY, TextureFormat.ARGB32, false);
        Camera.main.Render();
        RenderTexture.active = rt;
        screenShot.ReadPixels(new Rect(0, 0, resolutionX, resolutionY), 0, 0);
        Camera.main.targetTexture = null;
        RenderTexture.active = null;
        //Destroy(rt);
        byte[] bytes = screenShot.EncodeToPNG();
        System.IO.File.WriteAllBytes(path, bytes);
        UnityEditor.AssetDatabase.Refresh();
        Debug.Log("截图成功");
    }

    private void TakeShotExtension(string path)
    {
        int resolutionX = Screen.width;
        int resolutionY = Screen.height;
        GetGameViewSize(out resolutionX,out resolutionY);
        Debug.Log(resolutionX+"-----"+ resolutionY);
        RenderTexture rt = new RenderTexture(resolutionX, resolutionY, 24);
        Camera.main.targetTexture = rt;
        Texture2D screenShot = new Texture2D(resolutionX, resolutionY, TextureFormat.ARGB32, false);
        Camera.main.Render();
        RenderTexture.active = rt;
        screenShot.ReadPixels(new Rect(0, 0, resolutionX, resolutionY), 0, 0);
        Camera.main.targetTexture = null;
        RenderTexture.active = null;
        //Destroy(rt);
        byte[] bytes = screenShot.EncodeToPNG();
        System.IO.File.WriteAllBytes(path, bytes);
        UnityEditor.AssetDatabase.Refresh();
        Debug.Log("截图成功");
    }

    /// <summary>
    /// 获取Game View的分辨率
    /// </summary>
    /// <param name="width"></param>
    /// <param name="height"></param>
    private void GetGameViewSize(out int width, out int height)
    {
        System.Type T = System.Type.GetType("UnityEditor.PlayModeView,UnityEditor");
        System.Reflection.MethodInfo GetMainGameView = T.GetMethod("GetMainPlayModeView", System.Reflection.BindingFlags.NonPublic | System.Reflection.BindingFlags.Static);
        System.Object Res = GetMainGameView.Invoke(null, null);
        var gameView = (UnityEditor.EditorWindow)Res;
        var prop = gameView.GetType().GetProperty("currentGameViewSize", System.Reflection.BindingFlags.NonPublic | System.Reflection.BindingFlags.Instance);
        var gvsize = prop.GetValue(gameView, new object[0] { });
        var gvSizeType = gvsize.GetType();
        height = (int)gvSizeType.GetProperty("height", System.Reflection.BindingFlags.Public | System.Reflection.BindingFlags.Instance).GetValue(gvsize, new object[0] { });
        width = (int)gvSizeType.GetProperty("width", System.Reflection.BindingFlags.Public | System.Reflection.BindingFlags.Instance).GetValue(gvsize, new object[0] { });
    }
}
