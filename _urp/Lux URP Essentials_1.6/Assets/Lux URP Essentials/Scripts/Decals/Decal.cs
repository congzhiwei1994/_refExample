#if UNITY_EDITOR
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

namespace LuxURPEssentials
{
	public class Decal : MonoBehaviour {
		LayerMask mask = ~0;
		public void AlignDecal() {
			Transform trans = GetComponent<Transform>();
			RaycastHit hit;
			if (Physics.Raycast(trans.position + new Vector3(0f, 1.0f, 0.0f), Vector3.down, out hit, 3.0f, mask.value)) {
				Vector3 proj = trans.forward - Vector3.Dot(trans.forward, hit.normal) * hit.normal;
                trans.rotation = Quaternion.LookRotation(proj, hit.normal);
			}
		}
	}
}
#endif