using UnityEngine;
using UnityEditor;

[CustomEditor(typeof(ApplyProceduralTextureProperties))]
public class ApplyProceduralTexturePropertiesEditor : Editor {
    public override void OnInspectorGUI() {
    	DrawDefaultInspector();

    	ApplyProceduralTextureProperties script = (ApplyProceduralTextureProperties)target;

    	if(GUILayout.Button("Apply")) {
    		script.SyncMatWithProceduralTextureAsset();
    	}
    }
}
