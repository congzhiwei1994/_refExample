// This script activates the depth normals texture to the attached camera, works in edit mode
// You may need this in cases where the texture is not available by default (ie: forward rendering mode)

using UnityEngine;

[ExecuteInEditMode]
public class ForceNormals : MonoBehaviour
{
	private void OnEnable()
	{
		Camera cam = GetComponent<Camera>();
		cam.depthTextureMode = cam.depthTextureMode | DepthTextureMode.DepthNormals;
	}
}
