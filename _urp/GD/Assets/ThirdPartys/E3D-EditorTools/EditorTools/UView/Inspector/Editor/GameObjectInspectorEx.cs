﻿//******************************************************
//  2019/1/25  -- 修改初始化显示
//******************************************************
using System.Reflection;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;

[CustomEditor(typeof(GameObject))]
public class GameObjectInspectorEx : Editor
{
    private Editor m_GameObjectInspector;

    private string[] m_PreviewModeDesc = new string[] { "模型", "UV1", "UV2", "UV3", "UV4" };

    private int m_PreviewMode;

    /// <summary>
    /// UV颜色
    /// </summary>
    private Color m_UvColor = Color.green;

    [SerializeField] private UVPreview m_UVPreview;

    private List<Texture2D> m_Textures;

    private GUIContent m_TexContent;

    private MethodInfo m_OnHeaderGUI;

    private int m_RendersCount = 0;

    void OnEnable()
    {
        //增加判断。只有在编辑器且非运行状态下才能预览对象UV相关信息
#if UNITY_EDITOR
        //if (Application.isEditor && Application.isPlaying != true)
        {
            System.Type gameObjectorInspectorType = typeof(Editor).Assembly.GetType("UnityEditor.GameObjectInspector");
            m_OnHeaderGUI = gameObjectorInspectorType.GetMethod("OnHeaderGUI",
                BindingFlags.NonPublic | BindingFlags.Instance);
            m_GameObjectInspector = Editor.CreateEditor(target, gameObjectorInspectorType);
            //===============================================================================//
            //string[] checkerBoardAssets = AssetDatabase.FindAssets("CheckerBoard");
            //string checkerBoardPath = AssetDatabase.GUIDToAssetPath(checkerBoardAssets[0]);
            //string[] boardLineAssets = AssetDatabase.FindAssets("BoardLine");
            //string boardLinePath = AssetDatabase.GUIDToAssetPath(boardLineAssets[0]);
            //m_UVPreview = new UVPreview(checkerBoardPath, boardLinePath);
            m_UVPreview = new UVPreview(Shader.Find("Hidden/Internal/GUI/CheckerBoard"), Shader.Find("Hidden/Internal/GUI/BoardLine"));
            if (target)
                m_UVPreview.Add((GameObject)target, true);
            m_Textures = CollectTextures((GameObject)target);
            m_TexContent = new GUIContent("贴图");

            Renderer[] renderers = ((GameObject)target).GetComponentsInChildren<Renderer>();
            m_RendersCount = renderers.Length;

            //******************************************************
            //--修改初始化显示为1UV +diffuse
            //m_PreviewMode = 1;
            //if (m_Textures.Count > 0)
            //    m_UVPreview.SetTexture(m_Textures[0]);
            //******************************************************
            m_PreviewMode = PlayerPrefs.GetInt("PreviewMode");
        }
#endif
    }

    void OnDisable()
    {
        if (m_GameObjectInspector)
            DestroyImmediate(m_GameObjectInspector);
        m_GameObjectInspector = null;
        if (m_UVPreview != null)
            m_UVPreview.Release();
        m_UVPreview = null;
    }

    protected override void OnHeaderGUI()
    {
        if (m_OnHeaderGUI != null)
        {
            m_OnHeaderGUI.Invoke(m_GameObjectInspector, null);
        }
    }

    public override void OnInspectorGUI()
    {
        m_GameObjectInspector.OnInspectorGUI();
    }

    public override bool HasPreviewGUI()
    {
        if (m_GameObjectInspector.HasPreviewGUI())
            return true;
        return m_RendersCount > 0;
    }


    public override void DrawPreview(Rect previewArea)
    {
        GUI.Box(new Rect(previewArea.x, previewArea.y, previewArea.width, 17), string.Empty, GUI.skin.FindStyle("toolbar"));

        m_PreviewMode = GUI.Toolbar(new Rect(previewArea.x + 5, previewArea.y, 50 * 4, 17), m_PreviewMode,
            m_PreviewModeDesc, GUI.skin.FindStyle("toolbarbutton"));

        if (m_PreviewMode != 0)
        {
            m_UvColor = EditorGUI.ColorField(
                new Rect(previewArea.x + previewArea.width - 50, previewArea.y + 2, 40, 13),
                m_UvColor);
            if (GUI.Button(new Rect(previewArea.x + previewArea.width - 120, previewArea.y, 70, 17), m_TexContent,
                GUI.skin.FindStyle("ToolbarDropDown")))
            {
                DropDownTextures(new Rect(previewArea.x + previewArea.width - 120, previewArea.y, 70, 17));

            }
            if (GUI.Button(new Rect(previewArea.x + previewArea.width - 190, previewArea.y, 70, 17), "光照贴图",
               GUI.skin.FindStyle("ToolbarDropDown")))
            {
                DropDownLightMaps(new Rect(previewArea.x + previewArea.width - 120, previewArea.y, 70, 17));
            }
        }

        Rect previewRect = new Rect(previewArea.x, previewArea.y + 17, previewArea.width, previewArea.height - 17);
        if (m_PreviewMode == 0)
        {
            m_GameObjectInspector.DrawPreview(previewRect);
        }
        else
        {
            m_UVPreview.DrawPreview(previewRect, m_UvColor, (UVPreview.UVIndex)(m_PreviewMode - 1), false);
        }
        PlayerPrefs.SetInt("PreviewMode", m_PreviewMode);
    }

    public override void OnPreviewGUI(Rect r, GUIStyle background)
    {
        m_GameObjectInspector.OnPreviewGUI(r, background);
    }

    public override string GetInfoString()
    {
        return m_GameObjectInspector.GetInfoString();
    }

    public override GUIContent GetPreviewTitle()
    {
        return m_GameObjectInspector.GetPreviewTitle();
    }

    public override void OnInteractivePreviewGUI(Rect r, GUIStyle background)
    {
        m_GameObjectInspector.OnInteractivePreviewGUI(r, background);
    }

    public override void OnPreviewSettings()
    {
        m_GameObjectInspector.OnPreviewSettings();
    }

    public override void ReloadPreviewInstances()
    {
        m_GameObjectInspector.ReloadPreviewInstances();
    }

    public override Texture2D RenderStaticPreview(string assetPath, Object[] subAssets, int width, int height)
    {
        return m_GameObjectInspector.RenderStaticPreview(assetPath, subAssets, width, height);
    }

    public override bool RequiresConstantRepaint()
    {
        return m_GameObjectInspector.RequiresConstantRepaint();
    }

    public override bool UseDefaultMargins()
    {
        return m_GameObjectInspector.UseDefaultMargins();
    }

    private List<Texture2D> CollectTextures(GameObject target)
    {
        List<Texture2D> result = new List<Texture2D>();
        MeshRenderer[] meshRenderers = target.GetComponentsInChildren<MeshRenderer>();
        SkinnedMeshRenderer[] skinnedMeshRenderers = target.GetComponentsInChildren<SkinnedMeshRenderer>();
        List<Material> mats = new List<Material>();
        for (int i = 0; i < meshRenderers.Length; i++)
        {
            if (meshRenderers[i].sharedMaterial)
            {
                if (!mats.Contains(meshRenderers[i].sharedMaterial))
                    mats.Add(meshRenderers[i].sharedMaterial);
            }
        }
        for (int i = 0; i < skinnedMeshRenderers.Length; i++)
        {
            if (skinnedMeshRenderers[i].sharedMaterial)
            {
                if (!mats.Contains(skinnedMeshRenderers[i].sharedMaterial))
                    mats.Add(skinnedMeshRenderers[i].sharedMaterial);
            }
        }
        if (mats.Count > 0)
        {
            //===========================================================================//
            //MaterialProperty[] matProperties = MaterialEditor.GetMaterialProperties(mats.ToArray());
            //for (int i = 0; i < matProperties.Length; i++)
            //{
            //    Debug.Log(matProperties[i].name);
            //    if (matProperties[i].type == MaterialProperty.PropType.Texture &&
            //        matProperties[i].textureDimension == UnityEngine.Rendering.TextureDimension.Tex2D && matProperties[i].textureValue != null)
            //    {
            //        result.Add((Texture2D)matProperties[i].textureValue);
            //    }
            //}
            //===========================================================================//
            //Debug.Log("===========================================================================");
            Material[] matGroup = mats.ToArray();
            Material[] tempMatGroup = new Material[1];
            for (int i = 0; i < matGroup.Length; i++)
            {
                Material mg = matGroup[i];
                Shader ms = mg.shader;
                string sn = mg.shader.name;
                int pc = ShaderUtil.GetPropertyCount(ms);
                //Debug.Log(sn + " = " + pc);
                for (int j = 0; j < pc; j++)
                {
                    string pn = ShaderUtil.GetPropertyName(matGroup[i].shader, j);
                    //Debug.Log(sn + " Property:" + pn);
                    if (matGroup[i].HasProperty(pn))
                    {
                        tempMatGroup[0] = matGroup[i];
                        MaterialProperty mp = MaterialEditor.GetMaterialProperty(tempMatGroup, pn);
                        if (mp.type == MaterialProperty.PropType.Texture &&
                   mp.textureDimension == UnityEngine.Rendering.TextureDimension.Tex2D && mp.textureValue != null)
                        {
                            result.Add((Texture2D)mp.textureValue);
                        }
                    }
                }
            }
        }
        return result;
    }

    private void DropDownTextures(Rect rect)
    {
        if (m_Textures == null || m_Textures.Count == 0)
            return;
        GenericMenu menu = new GenericMenu();
        //menu.AddItem(new GUIContent("Empty"), m_TexContent.image == null, ClearTexture);
        menu.AddItem(new GUIContent("Empty"), m_TexContent.image == null, ClearTexture);
        menu.AddSeparator("");
        for (int i = 0; i < m_Textures.Count; i++)
        {
            menu.AddItem(new GUIContent(m_Textures[i].name, m_Textures[i]), m_TexContent.image == m_Textures[i],
                SelectTexture, m_Textures[i]);
        }
        menu.DropDown(rect);
    }

    private void DropDownLightMaps(Rect rect)
    {
        if (LightmapSettings.lightmaps.Length > 0)
        {
            GenericMenu menu = new GenericMenu();
            for (int i = 0; i < LightmapSettings.lightmaps.Length; i++)
            {
                menu.AddItem(new GUIContent("Index:" + i), false, SetLightMap, new LightMapData(i, false));
                menu.AddItem(new GUIContent("Index:" + i + ",Directional"), false, SetLightMap,
                    new LightMapData(i, true));
            }
            menu.DropDown(rect);
        }
    }

    private void ClearTexture()
    {
        m_UVPreview.ClearTexture();
        m_TexContent = new GUIContent("贴图");
    }

    private void SelectTexture(System.Object texture)
    {
        if (texture == null)
            return;
        Texture2D tex = (Texture2D)texture;
        m_TexContent = new GUIContent(tex.name, tex);
        m_UVPreview.SetTexture(tex);
    }

    private void SetLightMap(object index)
    {
        LightMapData id = (LightMapData)index;
        m_UVPreview.SetLightMap(id.index, id.isDirectional);
    }

    private struct LightMapData
    {
        public int index;
        public bool isDirectional;

        public LightMapData(int index, bool isDirectional)
        {
            this.index = index;
            this.isDirectional = isDirectional;
        }
    }
}
