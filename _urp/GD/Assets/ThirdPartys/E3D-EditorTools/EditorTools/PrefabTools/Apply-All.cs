//******************************************************
//
//	File Name 	: 		ApplyPrefabsExtension.cs
//	
//	Author  	:		dust Taoist

//	CreatTime   :		8/16/2019 18:29
//******************************************************
using System.Text;
using System.IO;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;

public class ApplyPrefabsExtension : Editor
{
    [MenuItem("GameObject/Apply All", false, 12)]
    static void ApplySelectedPrefabs()
    {
        //Get all the selected gameobject objects
        GameObject[] selectedsGameobject = Selection.gameObjects;
        GameObject prefab = PrefabUtility.FindPrefabRoot(selectedsGameobject[0]);
        List<GameObject> _prefabObjs = new List<GameObject>();
        int _max = 0;
        float _current = 0;
        for (int i = 0; i < selectedsGameobject.Length; i++)
        {
            _max++;
        }
        for (int j = 0; j < selectedsGameobject.Length; j++)
        {
            //Determine whether the selected object is Prefab
            if (PrefabUtility.GetPrefabType(selectedsGameobject[j]) != PrefabType.PrefabInstance)
            {
                continue;
            }
            else
            {
                if (!_prefabObjs.Contains(selectedsGameobject[j]))
                {
                    _prefabObjs.Add(selectedsGameobject[j]);
                }
            }
        }

        for (int i = 0; i < _prefabObjs.Count; i++)
        {
            string jindu = string.Format("Generating, please be patient, current progress:{0}%", ((_current / _max) * 100).ToString("0.00"));

            UnityEngine.Object parentObject = PrefabUtility.GetPrefabParent(_prefabObjs[i]);
            PrefabUtility.ReplacePrefab(_prefabObjs[i], parentObject, ReplacePrefabOptions.ConnectToPrefab);
            EditorUtility.DisplayProgressBar("Apply applies the progress bar", jindu, _current / _max);
            _current++;
        }
        EditorUtility.ClearProgressBar();
        AssetDatabase.Refresh();
        Debug.Log("Operation is completed");
    }
}
