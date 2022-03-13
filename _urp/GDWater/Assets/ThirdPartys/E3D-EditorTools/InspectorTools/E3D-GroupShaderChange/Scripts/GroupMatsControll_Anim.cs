//******************************************************
//
//	File Name 	: 		GroupMatsControll_Anim.cs
//	
//	Author  	:		dust Taoist

//	CreatTime   :		8/16/2019 18:55
//******************************************************
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class GroupMatsControll_Anim : MonoBehaviour {

    [Range(0, 1)]
    public float parame_1 = 0.5f;
    public string shaderProperName = "_SnowAmount";

    public List<Shader> shaderLists = new List<Shader>();

    public List<MatInfo> matInfos = new List<MatInfo>();

    public List<Material> targetM = new List<Material>();

    /// <summary>
    /// Clear Data
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

        FindeRenderMat();
        FindTagetShaders();
    }
    /// <summary>
    ///  Gets the render component, material sphere, of all subobjects under the current object
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
                        try   //Not using a try will flag an exception null pointer.
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
}
