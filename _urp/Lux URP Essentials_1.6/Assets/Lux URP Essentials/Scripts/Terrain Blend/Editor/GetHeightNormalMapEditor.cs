using UnityEngine;
using UnityEditor;
using System;
using System.Collections;
using System.Reflection;
using System.IO;

namespace LuxURPEssentials
{

	[CustomEditor (typeof(GetTerrainHeightNormalMap))]
	public class GetTerrainHeightNormalMapEditor : Editor {

		private SerializedObject GetTerrainHeightNormalMap;
		private SerializedProperty savePathTerrainHeightNormalMap;

		public override void OnInspectorGUI () {

			GetTerrainHeightNormalMap = new SerializedObject(target);
			GetTerrainHeightNormalMap script = (GetTerrainHeightNormalMap)target;
			script.GetTerData();
			savePathTerrainHeightNormalMap = GetTerrainHeightNormalMap.FindProperty("savePathTerrainHeightNormalMap");

			if (GUILayout.Button("Get Height Normal Map")) {
				CreateTerrainHeightNormal();
			}
			GetTerrainHeightNormalMap.ApplyModifiedProperties();
		}
	   
		void CreateTerrainHeightNormal() {
			GetTerrainHeightNormalMap script = (GetTerrainHeightNormalMap)target;
			TerrainData targetTerrainData = script.targetTerrainData;
			Texture2D tempTex = new Texture2D(targetTerrainData.heightmapResolution, targetTerrainData.heightmapResolution, TextureFormat.RGBA32, false, true);

			Color32[] cols = new Color32[tempTex.width * tempTex.height];
			for( int x = 0; x < tempTex.width; x++ ) {
				for( int y = 0; y < tempTex.height; y++ ) {
					// Bring x and y into the 0-1 Range used by GetInterpolatedHeight
					float sample_xpos = 1.0f * x / (tempTex.width - 1);
					float sample_ypos = 1.0f * y / (tempTex.height - 1);
					
					// Get and encode height
					float height = targetTerrainData.GetInterpolatedHeight(sample_xpos, sample_ypos) / targetTerrainData.size.y;
					// Encoding/decoding [0..1) floats into 8 bit/channel RG. Note that 1.0 will not be encoded properly.
					int height0 = Mathf.FloorToInt(height * 255.0f);
					int height1 = Mathf.FloorToInt((height * 255.0f - height0) * 255.0f);
					// Get normal
					Vector3 normal = targetTerrainData.GetInterpolatedNormal(sample_xpos, sample_ypos);
					float normal_x = (normal.x * 0.5f + 0.5f) * 255.0f;
					float normal_z = (normal.z * 0.5f + 0.5f) * 255.0f;
					cols[x + y * tempTex.width] = new Color32( (byte)height0, (byte)height1, (byte)normal_x, (byte)normal_z );
				}
			}
			tempTex.SetPixels32(cols);
			tempTex.Apply(false);

			string directory;
			string file = "Terrain Height Normal Map";
			if (savePathTerrainHeightNormalMap.stringValue =="") {
				directory = Application.dataPath;
			}
			else {
				directory = Path.GetDirectoryName(savePathTerrainHeightNormalMap.stringValue);
				file = Path.GetFileNameWithoutExtension(savePathTerrainHeightNormalMap.stringValue);
			}
			string filePath = EditorUtility.SaveFilePanel("Save Terrain Height Normal Map", directory, file, "png");
			if (!string.IsNullOrEmpty(filePath)) {
				filePath = FileUtil.GetProjectRelativePath(filePath);
				savePathTerrainHeightNormalMap.stringValue = filePath;

				byte[] bytes = tempTex.EncodeToPNG();
				System.IO.File.WriteAllBytes(filePath, bytes);
				AssetDatabase.Refresh();
				TextureImporter ti = AssetImporter.GetAtPath(filePath) as TextureImporter;
				
				ti.textureCompression = TextureImporterCompression.Uncompressed;
				ti.sRGBTexture = false;

				ti.wrapMode = TextureWrapMode.Clamp;
				ti.mipmapEnabled = false;
				ti.npotScale = TextureImporterNPOTScale.None;
				AssetDatabase.ImportAsset(filePath, ImportAssetOptions.ForceUpdate);
				AssetDatabase.Refresh();
			}
			DestroyImmediate(tempTex);
		}
	}
}