//******************************************************
//
//	File Name 	: 		CaptureSuperImagerEditor.cs
//	
//	Author  	:		dust Taoist

//	CreatTime   :		8/16/2019 18:19
//******************************************************

using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;
using System.IO;
using System;

/// <summary>
/// The screenshot has been saved to
/// </summary>
[CustomEditor(typeof(CaptureSuperImager))]
public class CaptureSuperImagerEditor : Editor
{
    string[] shotOptions = new string[] { "Post-processing", "No Post-processing" };
    int shotOptionsSelect = 0;
    Vector2 pixel;
    Vector2 pixelMin;

    private string dicPath;
    private void OnEnable()
    {
        pixelMin = new Vector2(2, 2);
        dicPath= Application.dataPath.Substring(0, Application.dataPath.LastIndexOf("/"));
        dicPath =dicPath+"/" + "CameShotSave";
    }

    private void OnDisable() { }

    /// <summary>
    /// override InspectorGUI
    /// </summary>
    public override void OnInspectorGUI()
    {
        CaptureSuperImager script = (CaptureSuperImager)target;
        serializedObject.Update();

        if (Application.isEditor && Application.isPlaying == false)
            EditorGUILayout.HelpBox("Screenshots Tools\n Editor, running both modes support！\n The current version v.1", MessageType.Error);

        EditorGUILayout.Space();

        shotOptionsSelect = EditorGUILayout.Popup("Capture mode", shotOptionsSelect, shotOptions, GUILayout.ExpandWidth(true));

        if (shotOptionsSelect == 0)
        {
            EditorGUILayout.HelpBox("The current schema supports post-processing ！", MessageType.Info);
            script.fileName = EditorGUILayout.TextField("Screen name", script.fileName);
            EditorGUILayout.TextField("The output directory:", dicPath);
            pixel = script.pixelSize;

            bool isPress1 = GUILayout.Button("Save the screenshot", GUILayout.ExpandWidth(true));
            if (isPress1)
            {
                //Make sure the resolution is always a multiple of 2
                if (pixel.x == 0 || pixel.y == 0)
                {
                    script.pixelSize = pixelMin;
                }
                if (pixel.x % 2 != 0)
                {
                    script.pixelSize = new Vector2(pixel.x + 1, pixel.y);
                }
                else if (pixel.y % 2 != 0)
                {
                    script.pixelSize = new Vector2(pixel.x, pixel.y + 1);
                }
                else if (pixel.x % 2 != 0 && pixel.y % 2 != 0)
                {
                    script.pixelSize = new Vector2(pixel.x + 1, pixel.y + 1);
                }


                script.GetCapytureScreenShot();

                serializedObject.ApplyModifiedProperties();

                EditorUtility.SetDirty(script);
                AssetDatabase.Refresh();
            }
        }
        else if (shotOptionsSelect == 1)
        {
            EditorGUILayout.HelpBox("Post-processing is not supported！", MessageType.Warning);
        }

        if (GUILayout.Button("Open the directory where the screenshots are"))
        {
            Debug.Log("Screenshot of success");
            System.Diagnostics.Process.Start(new System.Diagnostics.ProcessStartInfo()
            {
                FileName = script.DicPath,
                UseShellExecute = true,
                Verb = "open"
            });

        }
    }

}
