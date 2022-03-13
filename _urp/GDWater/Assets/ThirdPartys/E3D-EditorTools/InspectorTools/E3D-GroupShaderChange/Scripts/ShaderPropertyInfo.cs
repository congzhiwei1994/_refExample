//******************************************************
//
//	File Name 	: 		ShaderPropertyInfo.cs
//	
//	Author  	:		dust Taoist

//	CreatTime   :		8/16/2019 18:57
//******************************************************
using System.Collections;
using System.Collections.Generic;
using UnityEngine;


/// <summary>
/// Optionally drop down the shader properties menu
/// </summary>
public enum ShaderProperEnum
{
    None=0,
    /// <summary>
    /// Float---0-1
    /// </summary>
    FloatValue_0_1 = 1,

    /// <summary>
    /// Float---0-10
    /// </summary>
    FloatValue_0_10 = 2,
    /// <summary>
    /// Float---0-100
    /// </summary>
    FloatValue_0_100 = 3,
    /// <summary>
    /// Float---0-0.001
    /// </summary>
    FloatValue_0_001 = 4,



    /// <summary>
    /// The normal color
    /// </summary>
    Color = 5,
    /// <summary>
    /// HDR clor
    /// </summary>
    HDRColor=6,
    /// <summary>
    /// Map properties
    /// </summary>
    Texture = 7,
}
/// <summary>
/// Global shader control properties
/// </summary>
[System.Serializable]
public class ShaderPropertyInfo
{
    public ShaderPropertyInfo(){}

    public ShaderPropertyInfo(string name,float value,Color color, Color HDRColor, Texture texture = null)
    {
        this.name = name;
        this.value = value;
        this.color = color;
        this.HDRColor = HDRColor;
        this.texture = texture;
    }

    /// <summary>
    ///The property name
    /// </summary>
    public string name;

    /// <summary>
    /// floating-point
    /// </summary>
    public float value;

    /// <summary>
    /// Ordinary color
    /// </summary>
    public Color color;

    /// <summary>
    /// HDR Clore
    /// </summary>
    [ColorUsage(true, true, 1, 10, 0, 1)]
    public Color HDRColor;

    /// <summary>
    /// The texture used
    /// </summary>
    public Texture texture;
}


[System.Serializable]
public class FloatValueInfo
{

    public FloatValueInfo() { }

    public FloatValueInfo(string name, float value,Vector2 ver)
    {
        this.name = name;
        this.value = value;
        this.valueRange = ver;
    }
    /// <summary>
    /// The property name
    /// </summary>
    public string name;

    /// <summary>
    /// float
    /// </summary>
    public float value;
    /// <summary>
    /// Floating point range
    /// </summary>
    public Vector2 valueRange;

    /// <summary>
    ///Used to store the order of the current name in an existing list
    /// </summary>
    public int index;

}
[System.Serializable]
public class ColorInfo
{
    public ColorInfo() { }

    public ColorInfo(string name, Color color)
    {
        this.name = name;
        this.color = color;
    }

    /// <summary>
    /// The property name
    /// </summary>
    public string name;
    /// <summary>
    /// Ordinary color
    /// </summary>
    public Color color = Color.white;

    /// <summary>
    /// Used to store the order of the current name in an existing list
    /// </summary>
    public int index;
    /// <summary>
    /// HDR Clor
    /// </summary>
    [ColorUsage(true, true, 1, 10, 0, 1)]
    public Color HDRColor =Color.white;

}
[System.Serializable]
public class HDRColorInfo
{

    public HDRColorInfo() { }

    public HDRColorInfo(string name, Color HDRColor)
    {
        this.name = name;
        this.HDRColor = HDRColor;
    }
    /// <summary>
    /// The property name
    /// </summary>
    public string name;

    /// <summary>
    /// HDR Color
    /// </summary>
    [ColorUsage(true, true, 1, 10, 0, 1)]
    public Color HDRColor;

    /// <summary>
    /// Used to store the order of the current name in an existing list
    /// </summary>
    public int index;

}
[System.Serializable]
public class TextureInfo
{
    public TextureInfo() { }

    public TextureInfo(string name, Texture2D texture = null)
    {
        this.name = name;
        this.texture = texture;
    }

    /// <summary>
    ///  The property name
    /// </summary>
    public string name;

    /// <summary>
    /// The texture used
    /// </summary>
    public Texture2D texture;

    /// <summary>
    /// Used to store the order of the current name in an existing list
    /// </summary>
    public int index;
}



/// <summary>
/// Variable attribute class
/// </summary>
[System.Serializable]
public class ShaderProperTypeName
{
    /// <summary>
    /// Floating point variable name
    /// </summary>
    public string floatName;
    /// <summary>
    /// Color variable name
    /// </summary>
    public string colorName;
    /// <summary>
    /// Texture variable name
    /// </summary>
    public string textureName;
}