using UnityEngine;
using UnityEditor;

namespace LuxURPEssentials
{
	[CustomEditor(typeof(Decal))]
	public class DecalEditor : Editor {
	    public override void OnInspectorGUI() {
	    	Decal script = (Decal)target;
	        if (GUILayout.Button("Align")) {
	            script.AlignDecal();
	        }
	    }
	}
}