using System.Collections;
using System.Collections.Generic;
using UnityEngine;
/// <summary>
/// 缓存ScriptableObject数据
/// </summary>
[CreateAssetMenu(menuName ="E3D/CreatMeshShadersData")]
public class MeshShaderType : ScriptableObject
{
    [SerializeField]
    /// <summary>
    /// 可绘制层级
    /// </summary>
    public List<string> layers = new List<string>();

    [SerializeField]
    /// <summary>
    /// 所有可绘制shader
    /// </summary>
    public List<CustomData> shaders = new List<CustomData> ();

    public List<string> UpdateLayers(List<string> list)
    {
        layers.Clear();
        for (int i = 0; i < list.Count; i++)
        {
            layers.Add(list[i]);
        }
        return layers;
    }

    public List<CustomData> UpdateShaders(List<CustomData> list)
    {
        shaders.Clear();
        for (int i = 0; i < list.Count; i++)
        {
            shaders.Add(list[i]);
        }
        return shaders;
    }
}

[System.Serializable]
public class CustomData
{
	public string shaderName;
}
