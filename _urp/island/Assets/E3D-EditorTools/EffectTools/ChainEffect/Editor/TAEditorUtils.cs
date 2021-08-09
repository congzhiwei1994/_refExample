using UnityEngine;
using UnityEditor;

namespace E3DChain {

	[CustomPropertyDrawer(typeof(QualityBool))]
	public class QualityBoolDrawer : PropertyDrawer {
		public override void OnGUI(Rect position, SerializedProperty property, GUIContent label) {
			EditorGUI.BeginProperty(position, label, property);
			var m = property.FindPropertyRelative("Mask");
			EditorGUI.BeginChangeCheck();
			var v = EditorGUI.MaskField(position, label, m.intValue, QualitySettings.names);
			if (EditorGUI.EndChangeCheck()) {
				m.intValue = v;
			}
			EditorGUI.EndProperty();
		}
	}

} 