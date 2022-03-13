using UnityEngine;
using UnityEditor;
using System.Collections;
using System.Collections.Generic;
using System.IO;

public class FBXExporterUI : EditorWindow
{
	#region variables
	private bool addObjectsInHierarchy = true;
	private Vector2 scrollPos = new Vector2(0, 0);
	private string pathForFBX = "";
	private string fbxName = "FBXMesh";
	private string folderPathForFBX = "";
    private bool nameSetByUser = false;
	#endregion

	[ MenuItem("E3D-EditorTools/ExportFBX") ]
	public static void ShowWindow()
	{
        FBXExporterUI window = (FBXExporterUI)EditorWindow.GetWindow( typeof( FBXExporterUI ), false, "FBX Exporter");
		window.Show();
	}

	void OnEnable()
	{
        pathForFBX = "Assets/WRP_FBXExporter/Exports/"+fbxName+".fbx";
        nameSetByUser = false;
	}
	
	void OnGUI()
	{
		EditorGUILayout.Separator();
		GUILayout.Label( "Select options and hit apply..." );
		EditorGUILayout.Separator();

        addObjectsInHierarchy = EditorGUILayout.Toggle("Add Objects in heirarchy", addObjectsInHierarchy);

		EditorGUILayout.Separator();EditorGUILayout.Separator();EditorGUILayout.Separator();

        GameObject[] objectsToCombine = FBXExporter.GetObjectsToCombine(Selection.gameObjects, addObjectsInHierarchy);

        if(nameSetByUser==false)
            SetNameAndPath(objectsToCombine);

		string objectsToString = "";
		for (int i = 0; i < objectsToCombine.Length; i++)
		{
			objectsToString+=objectsToCombine[i].name;
			if(i<objectsToCombine.Length-1)
				objectsToString+="\n";
		}
		EditorGUILayout.LabelField("Selected Objects : "+objectsToCombine.Length);
		scrollPos = EditorGUILayout.BeginScrollView(scrollPos, GUILayout.Width (200), GUILayout.Height (80));

        EditorGUILayout.TextArea(objectsToString);

		EditorGUILayout.EndScrollView();

		EditorGUILayout.Separator();

		EditorGUILayout.BeginHorizontal();
        pathForFBX = EditorGUILayout.TextArea(pathForFBX, GUILayout.MaxWidth(250));
		if(GUILayout.Button( "Browse" ))
			pathForFBX = GetFilePath();
		EditorGUILayout.EndHorizontal();

		if( GUILayout.Button( "Export" ) )
		{
			folderPathForFBX = pathForFBX.Replace("Assets", "");
			folderPathForFBX = folderPathForFBX.Replace("/"+fbxName+".fbx", "");

            FBXExporter.ExportFBX(folderPathForFBX, fbxName, Selection.gameObjects, addObjectsInHierarchy);
		}
	}

    private void SetNameAndPath(GameObject[] actualObjects)
    {
        fbxName = "FBXMesh";
        if(addObjectsInHierarchy)
        {
            if(Selection.gameObjects!=null)
                if(Selection.gameObjects.Length>0)
                    fbxName = Selection.gameObjects[0].name;
        }
        else
        {
            if(actualObjects!=null)
             if(actualObjects.Length>0)
                    fbxName = actualObjects[0].name;
        }
        pathForFBX = "Assets/WRP_FBXExporter/Exports/"+fbxName+".fbx";
    }

	private string GetFilePath()
	{
		string newPathForFBX = EditorUtility.SaveFilePanelInProject("Export file path", fbxName + ".fbx", "fbx", "Export to a FBX file");
		if(newPathForFBX=="")
			return pathForFBX;

		fbxName = GetNewFBXName(newPathForFBX);
        nameSetByUser = true;
		return newPathForFBX;
	}

	private string GetNewFBXName(string newPath)
	{
		string[] tempStringArray = newPath.Split('/');
		string newFBXName = tempStringArray[tempStringArray.Length-1];
		newFBXName = newFBXName.Replace(".fbx", "");
		return newFBXName;
	}
}