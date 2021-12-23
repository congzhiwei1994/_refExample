using UnityEngine;
using System.Collections;
using UnityEditor;

public class LuxURPVectorTwoInverseDrawer : MaterialPropertyDrawer {

	public override void OnGUI (Rect position, MaterialProperty prop, string label, MaterialEditor editor) {
		
	//	Needed since Unity 2019
		EditorGUIUtility.labelWidth = 0;

		Vector4 vec4value = new Vector4(prop.vectorValue.y, prop.vectorValue.x, 0, 0);

		float near = prop.vectorValue.y;
		float far = prop.vectorValue.x;

		GUILayout.Space(-18);
		EditorGUI.BeginChangeCheck();
		EditorGUILayout.BeginVertical();
			EditorGUILayout.BeginHorizontal();
				EditorGUILayout.PrefixLabel(label);
				GUILayout.Space(-1);
				vec4value = EditorGUILayout.Vector2Field ("", vec4value);
				
			EditorGUILayout.EndHorizontal();
				near = EditorGUILayout.FloatField ("n", near);
				far = EditorGUILayout.FloatField ("f", far);
		EditorGUILayout.EndVertical();
		// GUILayout.Space(2);
		if (EditorGUI.EndChangeCheck ()) {
			prop.vectorValue = vec4value; //new Vector4(vec4value.x, vec4value.y, 0, 0);
			prop.vectorValue = new Vector4(far, near, 0, 0);
		}
	}
}