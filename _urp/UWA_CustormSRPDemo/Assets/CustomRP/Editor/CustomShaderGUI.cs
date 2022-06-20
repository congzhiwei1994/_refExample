using UnityEditor;
using UnityEngine;
using UnityEngine.Rendering;
/// <summary>
/// 扩展材质面板
/// </summary>
public class CustomShaderGUI : ShaderGUI
{
    MaterialEditor editor;
    Object[] materials;
    MaterialProperty[] properties;
    bool showPresets;
    //投影模式:开启投影、裁剪投影、抖动投影、关闭投影
    enum ShadowMode
    {
        On, Clip, Dither, Off
    }

    public override void OnGUI(MaterialEditor materialEditor, MaterialProperty[] properties)
    {
        EditorGUI.BeginChangeCheck();
        base.OnGUI(materialEditor, properties);
        editor = materialEditor;
        materials = materialEditor.targets;
        this.properties = properties;

        EditorGUILayout.Space();
        showPresets = EditorGUILayout.Foldout(showPresets, "Presets", true);
        if (showPresets)
        {
            OpaquePreset();
            ClipPreset();
            FadePreset();
            TransparentPreset();
        }
        //如果材质属性有被更改，检查阴影模式的设置状态
        if (EditorGUI.EndChangeCheck())
        {
            SetShadowCasterPass();
        }
    }
    /// <summary>
    /// 设置材质属性
    /// </summary>
    /// <param name="name"></param>
    /// <param name="value"></param>
    /// <returns></returns>
    bool SetProperty(string name, float value)
    {
        MaterialProperty property = FindProperty(name, properties, false);
        if (property != null)
        {
            property.floatValue = value;
            return true;
        }
        return false;
    }
    /// <summary>
    /// 设置关键字状态
    /// </summary>
    /// <param name="keyword"></param>
    /// <param name="enabled"></param>
    void SetKeyword(string keyword, bool enabled)
    {
        if (enabled)
        {
            foreach (Material m in materials)
            {
                m.EnableKeyword(keyword);
            }
        }
        else
        {
            foreach (Material m in materials)
            {
                m.DisableKeyword(keyword);
            }
        }
    }
    /// <summary>
    /// 相关属性存在时可以设置关键字开关
    /// </summary>
    /// <param name="name"></param>
    /// <param name="keyword"></param>
    /// <param name="value"></param>
    void SetProperty(string name, string keyword, bool value)
    {
        if (SetProperty(name, value ? 1f : 0f))
        {
            SetKeyword(keyword, value);
        }
    }
    bool Clipping
    {
        set => SetProperty("_Clipping", "_CLIPPING", value);
    }

    bool PremultiplyAlpha
    {
        set => SetProperty("_PremulAlpha", "_PREMULTIPLY_ALPHA", value);
    }

    BlendMode SrcBlend
    {
        set => SetProperty("_SrcBlend", (float)value);
    }

    BlendMode DstBlend
    {
        set => SetProperty("_DstBlend", (float)value);
    }

    bool ZWrite
    {
        set => SetProperty("_ZWrite", value ? 1f : 0f);
    }
    RenderQueue RenderQueue
    {
        set
        {
            foreach (Material m in materials)
            {
                m.renderQueue = (int)value;
            }
        }
    }
    bool PresetButton(string name)
    {
        if (GUILayout.Button(name))
        {
           
            editor.RegisterPropertyChangeUndo(name);
            return true;
        }
        return false;
    }
    /// <summary>
    /// 不透明材质默认设置
    /// </summary>
    void OpaquePreset()
    {
        if (PresetButton("Opaque"))
        {
            Clipping = false;
            PremultiplyAlpha = false;
            SrcBlend = BlendMode.One;
            DstBlend = BlendMode.Zero;
            ZWrite = true;
            RenderQueue = RenderQueue.Geometry;
        }
    }
    /// <summary>
    /// 裁切材质默认设置
    /// </summary>
    void ClipPreset()
    {
        if (PresetButton("Clip"))
        {
            Clipping = true;
            PremultiplyAlpha = false;
            SrcBlend = BlendMode.One;
            DstBlend = BlendMode.Zero;
            ZWrite = true;
            RenderQueue = RenderQueue.AlphaTest;
        }
    }
    /// <summary>
    /// 标准透明材质默认设置
    /// </summary>
    void FadePreset()
    {
        if (PresetButton("Fade"))
        {
            Clipping = false;
            PremultiplyAlpha = false;
            SrcBlend = BlendMode.SrcAlpha;
            DstBlend = BlendMode.OneMinusSrcAlpha;
            ZWrite = false;
            RenderQueue = RenderQueue.Transparent;
        }
    }
    //如果shader的预乘属性不存在，不需要显示该渲染模式的按钮
    bool HasProperty(string name) => FindProperty(name, properties, false) != null;
    bool HasPremultiplyAlpha => HasProperty("_PremulAlpha");
    /// <summary>
    /// 受光正确的透明材质默认设置
    /// </summary>
    void TransparentPreset()
    {
        if (HasPremultiplyAlpha && PresetButton("Transparent"))
        {
            Clipping = false;
            PremultiplyAlpha = true;
            SrcBlend = BlendMode.One;
            DstBlend = BlendMode.OneMinusSrcAlpha;
            ZWrite = false;
            RenderQueue = RenderQueue.Transparent;
        }
    }

    ShadowMode Shadows
    {
        set
        {
            if (SetProperty("_Shadows", (float)value))
            {
                SetKeyword("_SHADOWS_CLIP", value == ShadowMode.Clip);
                SetKeyword("_SHADOWS_DITHER", value == ShadowMode.Dither);
            }
        }
    }
    /// <summary>
    /// 设置材质的ShadowCaster pass块是否启用
    /// </summary>
    void SetShadowCasterPass()
    {
        MaterialProperty shadows = FindProperty("_Shadows", properties, false);
        if (shadows == null || shadows.hasMixedValue)
        {
            return;
        }
        bool enabled = shadows.floatValue < (float)ShadowMode.Off;
        foreach (Material m in materials)
        {
            m.SetShaderPassEnabled("ShadowCaster", enabled);
        }
    }
}