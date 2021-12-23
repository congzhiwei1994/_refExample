using UnityEngine;
using System.Collections;
using UnityEditor;

public class LuxURPCameraFadeDrawer : MaterialPropertyDrawer {

	public override void OnGUI (Rect position, MaterialProperty prop, string label, MaterialEditor editor) {
		
	//	Needed since Unity 2019
		EditorGUIUtility.labelWidth = 0;

		Vector4 vec4value = prop.vectorValue;

		GUILayout.Space(-18);
		EditorGUI.BeginChangeCheck();
		EditorGUILayout.BeginVertical();
			//EditorGUILayout.PrefixLabel(label);
			vec4value.z = EditorGUILayout.FloatField("     Near Dist", vec4value.z);
			vec4value.w = EditorGUILayout.FloatField("     Far Dist", vec4value.w);
		EditorGUILayout.EndVertical();
		if (EditorGUI.EndChangeCheck ()) {
			vec4value.z = (vec4value.z < 0.0f) ? 0.0f : vec4value.z;
			vec4value.x = vec4value.z;
			vec4value.y = 1.0f / (vec4value.w - vec4value.z);
			prop.vectorValue = vec4value;
		}
	}
}