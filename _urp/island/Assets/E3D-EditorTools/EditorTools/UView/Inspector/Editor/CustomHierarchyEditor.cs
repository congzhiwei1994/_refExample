//******************************************************
//
//	文件名 (File Name) 	: 		CustomHierarchyEditor.cs
//	
//	脚本创建者(Author) 	:		微尘道人

//	创建时间 (CreatTime):		2019年8月12日 14:30
//******************************************************
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;
using System;

/// <summary>
/// Hierarchy面板扩展
/// </summary>
public class CustomHierarchyEditor
{
    [InitializeOnLoadMethod]
    static void StartInitializeOnLoadMethod()
    {
        EditorApplication.hierarchyWindowItemOnGUI = (EditorApplication.HierarchyWindowItemCallback)Delegate.Combine(
            EditorApplication.hierarchyWindowItemOnGUI,
            new EditorApplication.HierarchyWindowItemCallback(OnHierarchyGUI)
            );

        EditorApplication.hierarchyWindowChanged += OnHierarchyChangeCallBack;

    }

    static void OnHierarchyGUI(int instanceID, Rect selectRect)
    {
        
    }

    /// <summary>
    /// Hierarchy面板动态改变
    /// </summary>
    static void OnHierarchyChangeCallBack()
    {
    }
}
