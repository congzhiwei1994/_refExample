using System.Collections.Generic;
using UnityEditor;
using UnityEngine;

namespace E3DChain {

	public class TAEditor : Editor {

		protected enum EnumLayoutItemType {
			blank, prop
		}

		protected struct LayoutItemEntry {
			public EnumLayoutItemType type;
			public string name;
			public string disp;
			public string tips;
		}

		protected SerializedObject _serObj;
		private Dictionary<string, SerializedProperty> _serProps = new Dictionary<string, SerializedProperty>();
		private List<LayoutItemEntry> _entries = new List<LayoutItemEntry>();

		protected void layoutProperty(string name, string disp, string tips = null) {
			_entries.Add(new LayoutItemEntry { type = EnumLayoutItemType.prop, name = name, disp = disp, tips = tips });
		}

		protected void layoutBlank(int size = -1) {
			_entries.Add(new LayoutItemEntry { type = EnumLayoutItemType.blank });
		}

		protected void layoutBegin() {
			_serObj = new SerializedObject(target);
			_serProps.Clear();
			_entries.Clear();
		}

		protected void layoutEnd() {
			if (_serObj == null) return;

			foreach (var pi in _entries) {
				switch (pi.type) {
					case EnumLayoutItemType.prop:
						var sp = _serObj.FindProperty(pi.name);
						_serProps[pi.name] = sp;
						break;
				}
			}
		}

        protected void layoutField() {
			_serObj.Update();
			foreach (var pi in _entries) {
				switch (pi.type) {
					case EnumLayoutItemType.blank:
						EditorGUILayout.Separator();
						break;
					case EnumLayoutItemType.prop:
						EditorGUILayout.PropertyField(_serProps[pi.name], new GUIContent(pi.disp, pi.tips));
						break;
				}
			}
			_serObj.ApplyModifiedProperties();
        }

        protected void toggleField(string label, ref bool value) {
            EditorGUI.BeginChangeCheck();
            var v = EditorGUILayout.Toggle(label, value);
            if (EditorGUI.EndChangeCheck()) {
                Undo.RecordObject(target, "Inspector");
                value = v;
            }
        }

        protected void rangeField(string label, ref int value, int min, int max) {
			EditorGUI.BeginChangeCheck();
			int v = EditorGUILayout.IntSlider(label, value, min, max);
			if (EditorGUI.EndChangeCheck()) {
				Undo.RecordObject(target, "Inspector");
				value = v;
			}
        }

        protected void rangeField(string label, ref float value, float min, float max) {
			EditorGUI.BeginChangeCheck();
			float v = EditorGUILayout.Slider(label, value, min, max);
			if (EditorGUI.EndChangeCheck()) {
				Undo.RecordObject(target, "Inspector");
				value = v;
			}
        }

        protected void minmaxField(string label, ref float min, ref float max, float minLimit, float maxLimit) {
            EditorGUI.BeginChangeCheck();
            float vmin = min;
            float vmax = max;
            EditorGUILayout.MinMaxSlider(new GUIContent(label), ref vmin, ref vmax, minLimit, maxLimit);
            if (EditorGUI.EndChangeCheck()) {
                min = vmin;
                max = vmax;
                Undo.RecordObject(target, "Inspector");
            }
        }

        protected void enumField<T>(string label, ref T value) {
			EditorGUI.BeginChangeCheck();
			System.Enum v = EditorGUILayout.EnumPopup(label, value as System.Enum);
			if (EditorGUI.EndChangeCheck()) {
				Undo.RecordObject(target, "Inspector");
				value = (T)(object)v;
			}
        }

        protected void layerField(string label, ref int value) {
			EditorGUI.BeginChangeCheck();
			int v = EditorGUILayout.LayerField(label, value);
			if (EditorGUI.EndChangeCheck()) {
				Undo.RecordObject(target, "Inspector");
				value = v;
			}
        }

        protected void propField(string label, string prop) {
            var sprop = _serObj.FindProperty(prop);
            if (sprop != null) {
                _serObj.Update();
                EditorGUILayout.PropertyField(sprop, new GUIContent(label));
                _serObj.ApplyModifiedProperties();
            }
        }

        protected void textureField(Texture2D texture) {

            GUILayout.Space(200);

            Rect rect = new Rect();
            rect = GUILayoutUtility.GetLastRect();
            rect.x = 20;
            rect.width = 200;
            rect.height = 200;

            GUI.DrawTexture(rect, texture, ScaleMode.StretchToFill);
            GUI.color = Color.white;

            GUILayout.Space(10);
        }

        public override void OnInspectorGUI() {
            if (_serObj == null) {
                base.OnInspectorGUI();
                EditorGUILayout.HelpBox("No layout info!", MessageType.Info);
            } else {
                layoutField();
            }
		}

	}

}