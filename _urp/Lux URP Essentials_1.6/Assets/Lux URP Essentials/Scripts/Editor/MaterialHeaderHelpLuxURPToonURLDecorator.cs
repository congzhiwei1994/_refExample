using System;
using UnityEditor;
using UnityEngine;

namespace LuxURPEssentials
{

	public class MaterialHeaderHelpLuxURPToon_URLDecorator : MaterialPropertyDrawer {
		private string url;
		private GUIContent buttonGUIContent;

		public MaterialHeaderHelpLuxURPToon_URLDecorator(string url) {
			this.url = "https://docs.google.com/document/d/1GpJwOeaXh_K1SqGcDYgA51JnpUV6e5x8n35SebR3W5o/edit#heading=h." + url;
			var helpIcon = EditorGUIUtility.FindTexture("_Help");
			buttonGUIContent = new GUIContent(helpIcon, "Open Online Documentation");
		}

		public override void OnGUI(Rect position, MaterialProperty prop, String label, MaterialEditor editor) {
			var headerPos = new Rect(position.x, position.y, position.width - 20, 20);
			var btnPos = new Rect(position.x + headerPos.width, position.y, 20, 20);
			GUI.Label(headerPos, new GUIContent("Help"), EditorStyles.boldLabel);
			if (GUI.Button(btnPos, buttonGUIContent, EditorStyles.boldLabel)) {
				Help.BrowseURL(this.url);
			}
		}

		public override float GetPropertyHeight(MaterialProperty prop, string label, MaterialEditor editor) {
			return 20;
		}
	}
}