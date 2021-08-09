using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;


[CustomEditor(typeof(MeshShaderType))]
public class MeshShaderTypeEditor : Editor
{
    SerializedProperty layers;
    SerializedProperty shaderNames;

    private void OnEnable()
    {
        layers = serializedObject.FindProperty("layers");
        shaderNames = serializedObject.FindProperty("shaders");
    }
    public override void OnInspectorGUI()
    {
        serializedObject.Update();
        EditorGUILayout.LabelField("Controllable level:");
            EditorGUI.indentLevel+=2;
            EditorGUILayout.PropertyField(layers, true);                //Note that arrays, lists, etc. need to have a serializable flag, and you need to pass the true parameter.
        EditorGUI.indentLevel-=2;
        EditorGUILayout.LabelField("Drawable shader:");
        EditorGUI.indentLevel += 2;
        EditorGUILayout.PropertyField(shaderNames, true);                //Note that arrays, lists, etc. need to have a serializable flag, and you need to pass the true parameter.
        EditorGUI.indentLevel -= 2;

        //Submit changes
        serializedObject.ApplyModifiedProperties();
    }
    
}
