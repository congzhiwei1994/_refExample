//******************************************************
//
//	文件名 (File Name) 	: 		TerrainShaderPropertyBridgeEditor
//	
//	脚本创建者(Author) 	:		Ejoy_小林

//	创建时间 (CreatTime):		#CreateTime#
//******************************************************


using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;

[CustomEditor(typeof(TerrainShaderPropertyBridge))]
public class TerrainShaderPropertyBridgeEditor : Editor
{
    private Terrain _cachedTerrain;
    private TerrainLayer[] _cachedTerrainLayers = new TerrainLayer[0];
    private Vector4 _smoothness;

    void OnEnable()
    {
        _cachedTerrain = GameObject.FindObjectOfType<Terrain>();
        _cachedTerrainLayers = _cachedTerrain.terrainData.terrainLayers;     
    }

    void OnDisable()
    {
        if (_cachedTerrain != null)
            _cachedTerrain = null;

        if (_cachedTerrainLayers != null)
            _cachedTerrainLayers = null;
    }
    void SetTerrainLayerSmoothness()
    {
        float[] newSmoothness = new float[4];
        newSmoothness[0] = _smoothness.x;
        newSmoothness[1] = _smoothness.y;
        newSmoothness[2] = _smoothness.z;
        newSmoothness[3] = _smoothness.w;
        if (_cachedTerrainLayers.Length > 0 && newSmoothness.Length >= _cachedTerrainLayers.Length)
        {
            for (int i = 0; i < _cachedTerrainLayers.Length; i++)
            {
                _cachedTerrainLayers[i].smoothness = newSmoothness[i];
            }
        }
    }
    public override void OnInspectorGUI()
    {
        base.OnInspectorGUI();
        if (GUILayout.Button("更新LayerSmoothness"))
        {
            _smoothness.x = (_cachedTerrain.materialTemplate.GetFloat("_Smooth0"));
            _smoothness.y = (_cachedTerrain.materialTemplate.GetFloat("_Smooth1"));
            //_smoothness.z = (_cachedTerrain.materialTemplate.GetFloat("_Smooth2"));
            //_smoothness.w = (_cachedTerrain.materialTemplate.GetFloat("_Smooth3"));
            SetTerrainLayerSmoothness();
        }
    }
}