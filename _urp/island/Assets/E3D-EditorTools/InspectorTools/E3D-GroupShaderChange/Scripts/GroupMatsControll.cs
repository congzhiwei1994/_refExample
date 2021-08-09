//******************************************************
//
//	File Name 	: 		GroupMatsControll.cs
//	
//	Author  	:		dust Taoist

//	CreatTime   :		8/16/2019 18:49
//******************************************************
using System.Collections;
using System.Collections.Generic;
using UnityEngine;


/// <summary>
/// Material group control
/// </summary>
public class GroupMatsControll : MonoBehaviour
{
    [HideInInspector]
    [Range(0, 1)]
    public float parame_1 = 0.5f;
    [HideInInspector]
    public string shaderProperName = "_SnowAmount";

    public List<Shader> shaderLists = new List<Shader>();

    [HideInInspector]
    public List<MatInfo> matInfos = new List<MatInfo>();
    [HideInInspector]
    public List<Material> targetM = new List<Material>();

    //=====================
    [HideInInspector]
    public List<FloatValueInfo> _floatValues = new List<FloatValueInfo>();
    [HideInInspector]
    public List<ColorInfo> _color = new List<ColorInfo>();
    [HideInInspector]
    public List<HDRColorInfo> _hdrColor = new List<HDRColorInfo>();
    [HideInInspector]
    public List<TextureInfo> _textures = new List<TextureInfo>();
    //=====================

    //=====================
    [HideInInspector]
    public List<string> _floatNames = new List<string>();
    [HideInInspector]
    public List<string> _colorNames = new List<string>();
    [HideInInspector]
    public List<string> _textureNames = new List<string>();
    //=====================

    /// <summary>
    ///Clear Data
    /// </summary>
    public void ClearData()
    {
        if (matInfos != null)
        {
            matInfos.Clear();
            matInfos = null;
        }
        if (targetM != null)
        {
            targetM.Clear();
            targetM = null;
        }

        if (_floatNames != null)
        {
            _floatNames.Clear();
            _floatNames = null;
        }
        if (_colorNames != null)
        {
            _colorNames.Clear();
            _colorNames = null;
        }

        if (_textureNames != null)
        {
            _textureNames.Clear();
            _textureNames = null;
        }
    }
    void Start()
    {
        FindeRenderMat();
        FindTagetShaders();
    }

    /// <summary>
    /// Clear the data and recollect the target shader
    /// </summary>
    public void OnInit()
    {
        ClearData();

        matInfos = new List<MatInfo>();
        targetM = new List<Material>();
        _floatNames = new List<string>();
        _colorNames = new List<string>();
        _textureNames = new List<string>();


        FindeRenderMat();
        FindTagetShaders();
    }
    /// <summary>
    /// Gets the render component, material sphere, of all subobjects under the current object
    /// </summary>
    void FindeRenderMat()
    {
        Renderer[] renders = transform.GetComponentsInChildren<Renderer>(true);
        if (renders != null)
        {
            if (shaderLists != null && shaderLists.Count > 0)
            {
                for (int i = 0; i < renders.Length; i++)
                {
                    Renderer tempRender = renders[i];
                    if (tempRender)
                    {
                        Material[] mats = tempRender.sharedMaterials;
                        MatInfo matinfo = new MatInfo(tempRender, mats);

                        if (!matInfos.Contains(matinfo))
                        {
                            matInfos.Add(matinfo);
                        }
                    }
                }
            }
        }
    }

    /// <summary>
    /// Find the shader you want to control
    /// </summary>
    void FindTagetShaders()
    {
        if (matInfos != null && matInfos.Count > 0)
        {
            for (int i = 0; i < matInfos.Count; i++)
            {
                Material[] mats = matInfos[i].mats;
                if (mats != null && mats.Length > 0)
                {
                    for (int j = 0; j < mats.Length; j++)
                    {
                        try   //An exception null pointer will be reported if try is not used.
                        {
                            Shader shader = mats[j].shader;

                            if (isInShaders(shader) == true)
                            {
                                if (!targetM.Contains(mats[j]))
                                {
                                    targetM.Add(mats[j]);
                                }
                            }
                            else
                            {
                                continue;
                            }
                        }
                        catch (System.Exception e)
                        {

                        }
                    }
                }
            }
        }
    }


    /// <summary>
    /// Given whether the shader is in the target shader list
    /// </summary>
    /// <param name="shader"></param>
    /// <returns></returns>
    bool isInShaders(Shader shader)
    {
        if (shader == null) return false;

        if (shaderLists == null || shaderLists.Count == 0) return false;

        for (int i = 0; i < shaderLists.Count; i++)
        {
            if (shader == shaderLists[i])
            {
                return true;
            }
            else { continue; }
        }

        return false;
    }

    void Update()
    {
        SetShaderPropertyValue();
    }

    /// <summary>
    /// Set the new shader value
    /// </summary>
    public void SetShaderPropertyValue()
    {
        if (targetM != null && targetM.Count > 0)
        {
            for (int i = 0; i < targetM.Count; i++)
            {
                targetM[i].SetFloat(shaderProperName, parame_1);
            }
        }
    }


    /// <summary>
    /// Set the new shader value
    /// </summary>
    public void  SetShaderPropertyValues()
    {
            SetFlot();
            SetColor();
            SetTexture();
    }



    void SetFlot()
    {
        if (_floatNames != null && _floatNames.Count > 0)
        {
            if (targetM != null && targetM.Count > 0 && _floatValues.Count > 0)                         //设置float
            {
                for (int i = 0; i < targetM.Count; i++)
                {
                    for (int j = 0; j < _floatValues.Count; j++)
                    {
                        targetM[i].SetFloat(_floatValues[j].name, _floatValues[j].value);
                    }
                }
            }
        }
        else
        {
            //Debug.Log("shader-Float！ Type does not exist");
        }

    }
    void SetColor()
    {
        if (_colorNames != null && _colorNames.Count > 0)
        {
            if (targetM != null && targetM.Count > 0 && _color.Count > 0)                              //设置Color 
            {
                for (int i = 0; i < targetM.Count; i++)
                {
                    for (int j = 0; j < _color.Count; j++)
                    {
                        if (_color[j].name.ToLower().Contains("hdr"))
                        {
                            targetM[i].SetColor(_color[j].name, _color[j].HDRColor);
                        }
                        else
                        {
                            targetM[i].SetColor(_color[j].name, _color[j].color);
                        }

                    }
                }
            }
        }
        else
        {
            // Debug.Log("shader-Color Type does not exist！");
        }
    }

    void SetTexture()
    {
        if (_textureNames != null && _textureNames.Count > 0)
        {
            if (targetM != null && targetM.Count > 0 && _textures.Count > 0)                        //设置Texture
            {
                for (int i = 0; i < targetM.Count; i++)
                {
                    for (int j = 0; j < _textures.Count; j++)
                    {
                        targetM[i].SetTexture(_textures[j].name, _textures[j].texture);
                    }
                }
            }
        }
        else
        {
            // Debug.Log("shader-Texture Type does not exist ！");
        }
    }
}

/// <summary>
/// Object material information
/// </summary>
[System.Serializable]
public class MatInfo
{
    public Renderer render;
    public Material[] mats;

    public MatInfo() { }

    public MatInfo(Renderer render, Material[] mats)
    {
        this.render = render;
        this.mats = mats;
    }
}