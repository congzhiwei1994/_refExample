using System;
using System.Collections;
using System.Collections.Generic;
using System.IO;
using System.Reflection;
using UnityEditor;
using UnityEngine;

[ExecuteInEditMode]
public class SetRTSize : MonoBehaviour
{
    public RenderTexture RenderTex;
    [HideInInspector]
    public bool execute;

    private void OnGUI()
    {
        if (GetComponent<Camera>().targetTexture == null) return;
        if (GetComponent<Camera>().targetTexture.width != Screen.width || GetComponent<Camera>().targetTexture.height != Screen.height)
        {
            if (RenderTex != null && execute)
            {
                string path = AssetDatabase.GetAssetPath(RenderTex);
                //Debug.Log(path);
                RenderTex = new RenderTexture(Screen.width, Screen.height, 24);
                GetComponent<Camera>().targetTexture = RenderTex;
                AssetDatabase.CreateAsset(RenderTex, path);
                execute = false;
            }
        }
    }
}
