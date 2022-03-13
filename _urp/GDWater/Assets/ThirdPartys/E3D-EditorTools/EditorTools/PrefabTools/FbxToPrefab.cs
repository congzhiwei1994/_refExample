//******************************************************
//
//	File Name 	: 		FbxToPrefab.cs
//	
//	Author  	:		dust Taoist

//	CreatTime   :		8/16/2019 18:14
//******************************************************
using System.Text;
using System.IO;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;

/// <summary>
/// Fbx To Prefab
/// </summary>
public class FbxToPrefab : Editor
{
    [MenuItem("Assets/Fbx To Prefab(No Split)")]
    public static void OneFbxToPrefab()
    {
        GameObject selectedGameObject = Selection.activeGameObject;
        string selectedAssetPath = AssetDatabase.GetAssetPath(selectedGameObject);
        string _targetPath = selectedAssetPath.Substring(0, selectedAssetPath.LastIndexOf('/'));

        GameObject cloneObj = GameObject.Instantiate<GameObject>(selectedGameObject);
        cloneObj.name = cloneObj.name.Replace("(Clone)", string.Empty);
        string genPrefabFullName = string.Concat(_targetPath, "/", cloneObj.name, ".prefab");

        Object prefabObj = PrefabUtility.CreateEmptyPrefab(genPrefabFullName);
        GameObject prefab = PrefabUtility.ReplacePrefab(cloneObj, prefabObj);
        GameObject.DestroyImmediate(cloneObj);

        Debug.Log("Finish");
    }

    [MenuItem("Assets/Fbx To Prefab(Split)")]
    private static void BatchPrefab()
    {
        float process = 0;
        int allLenth = 0;
        UnityEngine.Object _obj = Selection.activeObject;

        Transform parent = ((GameObject)_obj).transform;
        //Get current the path of Fbx 
        string _objPath = AssetDatabase.GetAssetPath(_obj);
        //intercept to generate prefabricated paths
        string _targetPath = _objPath.Substring(0, _objPath.LastIndexOf('/'));

        if (parent == null)
        {
            Debug.LogError("No object is currently selected");
            return;
        }

        UnityEngine.Object tempPrefab;

        foreach (Transform t in parent)
        {
            allLenth++;
        }
        foreach (Transform t in parent)
        {
            string jindu = string.Format("正在生成，请耐心等待，当前进度:{0}%", ((process / allLenth) * 100).ToString("0.00"));
            tempPrefab = PrefabUtility.CreateEmptyPrefab(_targetPath + "/" + t.name + ".prefab");
            tempPrefab = PrefabUtility.ReplacePrefab(t.gameObject, tempPrefab);
            EditorUtility.DisplayCancelableProgressBar("生成进度条", jindu, process / allLenth);
            process++;
        }
        EditorUtility.ClearProgressBar();
        AssetDatabase.Refresh();

        if (allLenth == 0)
        {
            OneFbxToPrefab();
        }
        else
        {
            Debug.Log("Finish");
        }
    }

    /// <summary>
    /// Cache all file paths
    /// </summary>
    static List<string> _changeFbxFiles = new List<string>();

    [MenuItem("Assets/More Fbx To Prefab(No Split)")]
    public static void MoreFbxToPrefab()
    {
        //Clear the cache
        _changeFbxFiles.Clear();

        //Gets the file selected with the mouse
        foreach (var obj in Selection.objects)
        {
            //Add file path to cache
            _changeFbxFiles.Add(AssetDatabase.GetAssetPath(obj));
        }

        // Remove overlapping directory files
        for (int i = _changeFbxFiles.Count - 1; i >= 0; --i)
        {
            for (int j = 0; j < _changeFbxFiles.Count; ++j)
            {
                if (i != j && _changeFbxFiles[i].Contains(_changeFbxFiles[j]))
                {
                    _changeFbxFiles.RemoveAt(i);
                    break;
                }
            }
        }


        for (int i = _changeFbxFiles.Count - 1; i >= 0; --i)
        {
            string file = _changeFbxFiles[i];
            GameObject cloneObj = AssetDatabase.LoadAssetAtPath<GameObject>(file);
            cloneObj.name = cloneObj.name.Replace("(Clone)", string.Empty);

            string genPrefabFullName = Path.GetDirectoryName(file); ;
            genPrefabFullName = string.Concat(genPrefabFullName, "/", cloneObj.name, ".prefab");
            Object prefabObj = PrefabUtility.CreateEmptyPrefab(genPrefabFullName);
            GameObject prefab = PrefabUtility.ReplacePrefab(cloneObj, prefabObj);

            //Destroy Orignal Resources
            if (prefab != null)
            {
                _changeFbxFiles.RemoveAt(i);
                GameObject.DestroyImmediate(cloneObj, true);

            }
            else
            {
                Debug.LogError(" Change error ");
            }
        }
        //Refresh Resources
        AssetDatabase.Refresh();

        _changeFbxFiles.Clear();
    }
}
