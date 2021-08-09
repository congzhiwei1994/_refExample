//******************************************************
//
//	File Name 	: 		ProjectFileEditorCtrl.cs
//	
//	Author  	:		dust Taoist

//	CreatTime   :		8/16/2019 18:03
//******************************************************
using System.Text;
using System.IO;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;

/// <summary>
/// Project view, file cut/paste, get current path
/// </summary>
public class ProjectFileEditorCtrl : Editor
{
    /// <summary>
    /// Cache All Files Path
    /// </summary>
    static List<string> _cutFiles = new List<string>();

    [MenuItem("Assets/Cut Files")]
    public static void CutFiles()
    {
        //Clear the cache
        _cutFiles.Clear();

        //Gets the file selected with the mouse
        foreach (var obj in Selection.objects)
        {
            //Add file path to cache
            _cutFiles.Add(AssetDatabase.GetAssetPath(obj));
        }

        // Remove overlapping directory files
        for (int i = _cutFiles.Count - 1; i >= 0; --i)
        {
            for (int j = 0; j < _cutFiles.Count; ++j)
            {
                if (i != j && _cutFiles[i].Contains(_cutFiles[j]))
                {
                    _cutFiles.RemoveAt(i);
                    break;
                }
            }
        }
    }

    public static void RefreshCutFiles()
    {
        _cutFiles.Clear();
    }

    [MenuItem("Assets/Paste Files")]
    public static void PasteFiles()
    {
        //The pasting path is empty and returns directly
        if (Selection.objects.Length != 1)
        {
            return;
        }
        //Gets the path to the first object
        string dir = AssetDatabase.GetAssetPath(Selection.objects[0]);

        for (int i = _cutFiles.Count - 1; i >= 0; --i)
        {
            string file = _cutFiles[i];
            string target = Path.Combine(dir, Path.GetFileName(file));// Generate the paste path for the cut file
            string validate = AssetDatabase.ValidateMoveAsset(file, target);// Verify mobile resources
            if (validate == string.Empty && AssetDatabase.MoveAsset(file, target) == string.Empty) //  Move Resources
            {
                _cutFiles.RemoveAt(i);
            }
            else
            {
                Debug.LogError("Move File Error:" + validate);
            }
        }
        //Refresh the resource view
        AssetDatabase.Refresh();

        RefreshCutFiles();  
    }

    [MenuItem("Assets/Current Resource Path")]
    static void GetSelectObjPath()
    {
        var _obj = Selection.activeObject;
        var _objPath = AssetDatabase.GetAssetPath(_obj);
        string str = _obj ? "Current resource path：" + _objPath: "Current resource path:Asset";
        Debug.Log(str);
    }
}
