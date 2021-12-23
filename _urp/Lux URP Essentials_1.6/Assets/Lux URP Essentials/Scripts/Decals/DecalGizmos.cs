#if UNITY_EDITOR
using UnityEngine;
using System.Collections;
using UnityEditor;

namespace LuxURPEssentials
{
	public static class DecalGizmos {

		static void DrawGizmo(GameObject go, GizmoType type, float dtype) {
			bool selected = (type & GizmoType.Selected) > 0;

			if (selected) {
				Gizmos.DrawRay(go.transform.position, -go.transform.up);
			}

			var col = new Color(dtype, 0.7f, 1f, 1.0f);
			col.a = selected ? 0.4f : 0.2f;
			
			Gizmos.color = col;
			Gizmos.matrix = go.transform.localToWorldMatrix;
			Gizmos.DrawCube(Vector3.zero, Vector3.one);
			col.a = selected ? 0.5f : 0.1f;
			Gizmos.color = col;
			Gizmos.DrawWireCube(Vector3.zero, Vector3.one);

		}
			
		[DrawGizmo(GizmoType.NotInSelectionHierarchy | GizmoType.Selected | GizmoType.Pickable)]
		static void DrawGizmo(Decal decal, GizmoType type ) {
			if (DecalManager.DrawDecalGizmos) {
				DrawGizmo(decal.gameObject, type, 0.0f );
			}
		}
	}
}
#endif
