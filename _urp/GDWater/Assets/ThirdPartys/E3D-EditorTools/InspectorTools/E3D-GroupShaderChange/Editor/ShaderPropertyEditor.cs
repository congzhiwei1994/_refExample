//******************************************************
//
//	File Name 	: 		ShaderPropertyEditor.cs
//	
//	Author  	:		dust Taoist

//	CreatTime   :		8/16/2019 18:31
//******************************************************
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;
using System;

[CustomEditor(typeof(GroupMatsControll))]
public class ShaderPropertyEditor : Editor
{

    private GroupMatsControll _self;
    private float tempParamValue;

    ShaderProperEnum shaderProperEnum = ShaderProperEnum.None;
    private bool isCreatNewColor = true;
    private bool isCreatFloat = true;
    private bool isCreatTexture = true;
    private void OnEnable()
    {
        if (!skin) skin = Resources.Load("Skin") as GUISkin;
        Debug.Log("焦点");
        _self = (GroupMatsControll)target;
        _self.OnInit();
        tempParamValue = _self.parame_1;

        GetShaderProperty();
    }

    private void GetShaderProperty()
    {
        if (_self && _self.shaderLists != null && _self.shaderLists.Count > 0)
        {
            for (int i = 0; i < _self.shaderLists.Count; i++)
            {
                GetShaderAttribute(_self.shaderLists[i], ref _self._textureNames, 1);
                GetShaderAttribute(_self.shaderLists[i], ref _self._floatNames, 2);
                GetShaderAttribute(_self.shaderLists[i], ref _self._colorNames, 3);
            }
        }

        if (_self._floatNames != null && _self._floatNames.Count > 0)
        {
            floatNames = _self._floatNames.ToArray();
        }

        if (_self._colorNames != null && _self._colorNames.Count > 0)
        {
            colorNames = _self._colorNames.ToArray();
        }

        if (_self._textureNames != null && _self._textureNames.Count > 0)
        {
            textureNames = _self._textureNames.ToArray();
        }
    }

    private void OnDisable()
    {
        if (_self)
            _self.ClearData();

        Debug.Log("invisible");
    }
    GUISkin skin;
    Vector2 float_1 = new Vector2(0, 1);
    Vector2 float_10 = new Vector2(0, 10);
    Vector2 float_100 = new Vector2(0, 100);
    Vector2 float_001 = new Vector2(0, 0.001f);

    /// <summary>
    /// override InsepctorGUI
    /// </summary>
    public override void OnInspectorGUI()
    {
        _self.OnInit();
        GetShaderProperty();
        EditorGUILayout.HelpBox("Dynamically replaces the specified shader material property \n", MessageType.Info);
        base.OnInspectorGUI();
        if (_self && _self.parame_1 != tempParamValue)
        {
            _self.SetShaderPropertyValue();
        }

        if (_self)
        {
            try
            {
                _self.SetShaderPropertyValues();
            }
            catch (Exception e)
            {
                Debug.LogError("There was an error setting the batch property" + e);
            }

        }

        GUILayout.Space(10);

        //isCreatNew = EditorGUILayout.Foldout(isCreatNew, "Creat ");

        //if (isCreatNew)
        //{
        EditorGUILayout.BeginVertical();
        EditorGUI.indentLevel += 1;
        shaderProperEnum = (ShaderProperEnum)EditorGUILayout.EnumPopup("Attribute Type", shaderProperEnum);

        #region  ----Attribute does not exist----
        switch (shaderProperEnum)
        {
            case ShaderProperEnum.None:
                break;
            case ShaderProperEnum.FloatValue_0_1:
                if (_self._floatNames == null || _self._floatNames.Count <= 0)
                    EditorGUILayout.HelpBox("The texture property FloatValue_0_1 does not exist and cannot be created ！"
                                            , MessageType.Error);
                break;
            case ShaderProperEnum.FloatValue_0_10:
                if (_self._floatNames == null || _self._floatNames.Count <= 0)
                    EditorGUILayout.HelpBox("The texture property FloatValue_0_10 does not exist and cannot be created ！"
                                            , MessageType.Error);
                break;
            case ShaderProperEnum.FloatValue_0_100:
                if (_self._floatNames == null || _self._floatNames.Count <= 0)
                    EditorGUILayout.HelpBox("The texture property FloatValue_0_100 does not exist and cannot be created ！"
                                            , MessageType.Error);
                break;
            case ShaderProperEnum.FloatValue_0_001:
                if (_self._floatNames == null || _self._floatNames.Count <= 0)
                    EditorGUILayout.HelpBox("The texture property FloatValue_00_1 does not exist and cannot be created ！"
                                            , MessageType.Error);
                break;
            case ShaderProperEnum.Color:
                if (_self._colorNames == null || _self._colorNames.Count <= 0)
                    EditorGUILayout.HelpBox("The material property Color does not exist and cannot be created ！"
                                            , MessageType.Error);
                break;
            case ShaderProperEnum.HDRColor:

                bool isHDR = false;
                if (_self._colorNames.Count > 0)
                {
                    for (int i = 0; i < _self._colorNames.Count; i++)
                    {
                        if (_self._colorNames[i].ToLower().Contains("hdr"))
                        {
                            isHDR = true;
                            break;
                        }
                    }
                }
                if (_self._colorNames == null || _self._colorNames.Count <= 0 || isHDR == false)
                    EditorGUILayout.HelpBox("The material property HDR Color does not exist and cannot be created ！"
                                            , MessageType.Error);
                break;
            case ShaderProperEnum.Texture:
                if (_self._textureNames == null || _self._textureNames.Count <= 0)
                    EditorGUILayout.HelpBox(" Texture does not exist and cannot be created ！"
                                            , MessageType.Error);
                break;
            default:
                break;
        }
        #endregion
        #region ----创建控制属性----
        if (GUILayout.Button("Creat Shader Attribute"))
        {
            switch (shaderProperEnum)
            {
                case ShaderProperEnum.None:
                    break;
                case ShaderProperEnum.FloatValue_0_1:
                    FloatValueInfo floatTemp = new FloatValueInfo();
                    floatTemp.valueRange = float_1;
                    AddProperty(ref _self._floatValues, floatTemp);
                    break;
                case ShaderProperEnum.FloatValue_0_10:

                    FloatValueInfo floatTemp_10 = new FloatValueInfo();
                    floatTemp_10.valueRange = float_10;
                    AddProperty(ref _self._floatValues, floatTemp_10);

                    break;
                case ShaderProperEnum.FloatValue_0_100:

                    FloatValueInfo floatTemp_100 = new FloatValueInfo();
                    floatTemp_100.valueRange = float_100;
                    AddProperty(ref _self._floatValues, floatTemp_100);

                    break;
                case ShaderProperEnum.FloatValue_0_001:

                    FloatValueInfo floatTemp_001 = new FloatValueInfo();
                    floatTemp_001.valueRange = float_001;
                    AddProperty(ref _self._floatValues, floatTemp_001);

                    break;
                case ShaderProperEnum.Color:

                    ColorInfo colorTemp = new ColorInfo();
                    AddProperty(ref _self._color, colorTemp);

                    break;
                case ShaderProperEnum.HDRColor:
                    ColorInfo hdrColorTemp = new ColorInfo();

                    AddProperty(ref _self._color, hdrColorTemp);

                    break;
                case ShaderProperEnum.Texture:

                    TextureInfo texTemp = new TextureInfo();
                    AddProperty(ref _self._textures, texTemp);

                    break;
                default:
                    break;
            }
            Debug.Log("Currently clicked" + shaderProperEnum.ToString());
        }
        #endregion

        EditorGUI.indentLevel -= 1;
        EditorGUILayout.EndVertical();
        // }

        GUILayout.Space(10);
        HorizontalLine(GUI.skin, Color.gray);

        FloatValueArr();
        ColorValueArr();
        TexValueArr();
        EditorUtility.SetDirty(_self);
    }
    /// <summary>
    /// Horizontal underline under editor
    /// </summary>
    /// <param name="skin"></param>
    /// <param name="color"></param>
    public static void HorizontalLine(GUISkin skin, Color color)
    {
        GUIStyle splitter = new GUIStyle(skin.box);
        splitter.border = new RectOffset(1, 1, 1, 1);
        splitter.stretchWidth = true;
        splitter.margin = new RectOffset(3, 3, 7, 7);


        Color restoreColor = GUI.contentColor;
        GUI.contentColor = color;
        GUILayout.Box("", splitter, GUILayout.Height(1.0f));

        GUI.contentColor = restoreColor;
    }



    #region  ---- Float processing ----
    private string[] floatNames;
    /// <summary>
    /// float attribute
    /// </summary>
    private void FloatValueArr()
    {
        isCreatFloat = EditorGUILayout.Foldout(isCreatFloat, "Float Modual");
        if (isCreatFloat)
        {
            if (_self && _self._floatValues != null && _self._floatValues.Count > 0 && floatNames != null && floatNames.Length > 0)
            {
                EditorGUILayout.BeginVertical(GUI.skin.box);
                EditorGUI.indentLevel += 1;

                //Custom style
                GUIStyle titleStyle = new GUIStyle(EditorStyles.centeredGreyMiniLabel);
                titleStyle.fontSize = 20;
                titleStyle.richText = true;
                GUILayout.Box("<color=#008000ff>Float Attribute</color>", titleStyle);

                GUILayout.Space(10);

                EditorGUILayout.BeginVertical();

                for (int i = 0; i < _self._floatValues.Count; i++)
                {
                    EditorGUILayout.TextField(i.ToString());
                    EditorGUI.indentLevel += 1;
                    _self._floatValues[i].index = EditorGUILayout.Popup("Select Attribute: ", _self._floatValues[i].index, floatNames);
                    _self._floatValues[i].name = EditorGUILayout.TextField("Name: ", floatNames[_self._floatValues[i].index]);
                    _self._floatValues[i].value = EditorGUILayout.Slider("Value: ", _self._floatValues[i].value, _self._floatValues[i].valueRange.x, _self._floatValues[i].valueRange.y);
                    EditorGUI.indentLevel -= 1;
                }

                EditorGUILayout.EndVertical();

                GUILayout.Space(10);
                EditorGUILayout.BeginHorizontal();
                if (_self._floatValues.Count > 0 && GUILayout.Button("Clear Last Data", GUILayout.Width(200)))
                {
                    if (_self._floatValues != null && _self._floatValues.Count > 0)
                    {
                        _self._floatValues.RemoveAt(_self._floatValues.Count - 1);
                    }
                }
                EditorGUILayout.EndHorizontal();

                EditorGUI.indentLevel -= 1;
                EditorGUILayout.EndVertical();
            }
        }
    }
    #endregion


    #region ---- Color  Value processing----

    string[] colorNames;
    private void ColorValueArr()
    {
        isCreatNewColor = EditorGUILayout.Foldout(isCreatNewColor, "Color Modual");
        if (isCreatNewColor)
        {
            if (_self && _self._color != null && _self._color.Count > 0 && colorNames != null && colorNames.Length > 0)
            {
                EditorGUILayout.BeginVertical(GUI.skin.box);
                EditorGUI.indentLevel += 1;

                //Custom style
                GUIStyle titleStyle = new GUIStyle(EditorStyles.centeredGreyMiniLabel);
                titleStyle.fontSize = 20;
                titleStyle.richText = true;
                GUILayout.Box("<color=#008000ff>Color Attribute</color>", titleStyle);

                GUILayout.Space(10);

                EditorGUILayout.BeginVertical();


                for (int i = 0; i < _self._color.Count; i++)
                {
                    EditorGUILayout.TextField(i.ToString());
                    EditorGUI.indentLevel += 1;
                    _self._color[i].index = EditorGUILayout.Popup("Select Attribute: ", _self._color[i].index, colorNames);
                    _self._color[i].name = EditorGUILayout.TextField("Name: ", colorNames[_self._color[i].index]);
                    if (_self._color[i].name.ToLower().Contains("hdr"))
                    {
                        GUIContent guicont = new GUIContent();
                        guicont.text = "HDRColor: ";
                        ColorPickerHDRConfig p = new ColorPickerHDRConfig(1, 10, 0, 0);
                        _self._color[i].HDRColor = EditorGUILayout.ColorField(guicont, _self._color[i].HDRColor, true, true, true, p);
                    }
                    else
                    {
                        _self._color[i].color = EditorGUILayout.ColorField("Color: ", _self._color[i].color);
                    }
                    EditorGUI.indentLevel -= 1;
                }



                EditorGUILayout.EndVertical();

                GUILayout.Space(10);
                EditorGUILayout.BeginHorizontal();
                if (_self._color.Count > 0 && GUILayout.Button("Clear Last Data", GUILayout.Width(200)))
                {
                    if (_self._color != null && _self._color.Count > 0)
                    {
                        _self._color.RemoveAt(_self._color.Count - 1);
                    }
                }
                EditorGUILayout.EndHorizontal();

                EditorGUI.indentLevel -= 1;
                EditorGUILayout.EndVertical();
            }
        }
    }
    #endregion


    #region ---- Texture 处理 ----
    string[] textureNames;
    private void TexValueArr()
    {
        isCreatTexture = EditorGUILayout.Foldout(isCreatTexture, "Texture Modual");
        if (isCreatTexture)
        {
            if (_self && _self._textures != null && _self._textures.Count > 0 && textureNames != null && textureNames.Length > 0)
            {

                EditorGUILayout.BeginVertical(GUI.skin.box);
                EditorGUI.indentLevel += 1;

                GUIStyle titleStyle = new GUIStyle(EditorStyles.centeredGreyMiniLabel);
                titleStyle.fontSize = 20;
                titleStyle.richText = true;
                GUILayout.Box("<color=#008000ff>Texture Attribute</color>", titleStyle);

                GUILayout.Space(10);

                EditorGUILayout.BeginVertical();

                for (int i = 0; i < _self._textures.Count; i++)
                {
                    EditorGUILayout.TextField(i.ToString());
                    EditorGUI.indentLevel += 1;
                    _self._textures[i].index = EditorGUILayout.Popup("Select Attribute: ", _self._textures[i].index, textureNames);
                    _self._textures[i].name = EditorGUILayout.TextField("Name: ", textureNames[_self._textures[i].index]);

                    EditorGUILayout.BeginHorizontal();

                    EditorGUILayout.BeginVertical();
                    EditorGUILayout.LabelField("Texture: ", GUILayout.Width(85));
                    EditorGUILayout.EndVertical();

                    EditorGUILayout.BeginVertical();
                    _self._textures[i].texture = (Texture2D)EditorGUILayout.ObjectField(_self._textures[i].texture, typeof(Texture2D), true);
                    EditorGUILayout.EndVertical();

                    EditorGUILayout.EndHorizontal();

                    EditorGUI.indentLevel -= 1;
                }

                EditorGUILayout.EndVertical();

                GUILayout.Space(10);
                EditorGUILayout.BeginHorizontal();
                if (_self._textures.Count > 0 && GUILayout.Button("Clear Last Data", GUILayout.Width(200)))
                {
                    if (_self._textures != null && _self._textures.Count > 0)
                    {
                        _self._textures.RemoveAt(_self._textures.Count - 1);
                    }
                }
                EditorGUILayout.EndHorizontal();

                EditorGUI.indentLevel -= 1;
                EditorGUILayout.EndVertical();
            }
        }
    }
    #endregion



    /// <summary>
    /// The new attribute
    /// </summary>
    /// <typeparam name="T"></typeparam>
    /// <param name="t"></param>
    private void AddProperty<T>(ref List<T> t, T temp)
    {
        if (t != null && temp != null)
        {
            t.Add(temp);
        }
    }


    /// <summary>
    /// Gets the shader texture properties under the specified material
    /// </summary>
    /// <param name="mat"></param>
    void GetMatShaderTextures(Material mat, /*ref string shaderName,*/ ref List<string> shaderPreproList)
    {
        if (mat == null || shaderPreproList == null) return;

        Shader shader = mat.shader;

        //Gets all the attributes in the shader
        for (int i = 0; i < ShaderUtil.GetPropertyCount(shader); i++)
        {
            //First determine if the current property is of texture.
            if (ShaderUtil.GetPropertyType(shader, i) == ShaderUtil.ShaderPropertyType.TexEnv)
            {
                //Gets the shader property name
                string properName = ShaderUtil.GetPropertyName(shader, i);

                if (!shaderPreproList.Contains(properName))
                {
                    shaderPreproList.Add(properName);
                }
                else
                {
                    //Texture empty-->Skip
                    continue;
                }
            }
        }
    }

    /// <summary>
    /// Gets the property name of the specified shader
    /// </summary>
    /// <param name="shader"></param>
    /// <param name="shaderProperNameList"></param>
    void GetShaderAttribute(Shader shader, ref List<string> shaderProperNameList, int type = 1)
    {
        if (shader == null || shaderProperNameList == null) return;

        //Gets all the attributes in the shader
        for (int i = 0; i < ShaderUtil.GetPropertyCount(shader); i++)
        {
            if (type == 1)
            {
                //.First determine if the current property is of texture
                if (ShaderUtil.GetPropertyType(shader, i) == ShaderUtil.ShaderPropertyType.TexEnv)
                {
                    //Gets the shader property name
                    string properName = ShaderUtil.GetPropertyName(shader, i);

                    if (!shaderProperNameList.Contains(properName))
                    {
                        shaderProperNameList.Add(properName);
                    }
                    else
                    {
                        continue;
                    }
                }
            }
            else if (type == 2)
            {
                if (ShaderUtil.GetPropertyType(shader, i) == ShaderUtil.ShaderPropertyType.Float || ShaderUtil.GetPropertyType(shader, i) == ShaderUtil.ShaderPropertyType.Range)
                {
                    //Gets the shader property name
                    string properName = ShaderUtil.GetPropertyName(shader, i);

                    if (!shaderProperNameList.Contains(properName))
                    {
                        shaderProperNameList.Add(properName);
                    }
                    else
                    {
                        continue;
                    }
                }
            }
            else if (type == 3)
            {
                if (ShaderUtil.GetPropertyType(shader, i) == ShaderUtil.ShaderPropertyType.Color)
                {
                    //Gets the shader property name
                    string properName = ShaderUtil.GetPropertyName(shader, i);

                    if (!shaderProperNameList.Contains(properName))
                    {
                        shaderProperNameList.Add(properName);
                    }
                    else
                    {
                        continue;
                    }
                }
            }

        }
    }


}
