
using System.Collections.Generic;
using System.IO;
using System.Text.RegularExpressions;
using UnityEngine;

public class MeshPainterStringUtility
{

    public static string meshPaintEditorFolder = "Assets/ThirdPartys/E3DMeshPaint/Editor/";
    public static string contolTexFolder = "Assets/ThirdPartys/E3DMeshPaint/Controler/";

    /// <summary>
    /// 可绘制shader 名称
    /// </summary>
    public static string shaderNameDatas = "Assets/ThirdPartys/E3DMeshPaint/ScriptsData/MeshPaintShaderDatas";
    /// <summary>
    /// 默认可绘制shader 名称
    /// </summary>
    public static string idleShaderNameDatas = "Assets/ThirdPartys/E3DMeshPaint/ScriptsData/DefaultShaderDatas";
    public static string fileExr = ".asset";

    //shader中使用的贴图
    public static string tex_1 = "_Splat1";
    public static string tex_2 = "_Splat2";
    public static string tex_3 = "_Splat3";
    public static string tex_4 = "_Splat4";
    /// <summary>
    /// 射线检测层级
    /// </summary>
    public static string rayCastLayer = "Ground";
    /// <summary>
    /// 区域控制图名字
    /// </summary>
    public static string shaderControlTexName = "_Control";

    /// <summary>
    /// 获取指定目录中的匹配目录
    /// </summary>
    /// <param name="dir">要搜索的目录</param>
    /// <param name="regexPattern">目录名模式（正则）。null表示忽略模式匹配，返回所有目录</param>
    /// <param name="recurse">是否搜索子目录</param>
    /// <param name="throwEx">是否抛异常</param>
    /// <returns></returns>
    private static string[] GetDirectories(string dir, string regexPattern = null, bool recurse = false, bool throwEx = false)
    {
        List<string> lst = new List<string>();

        try
        {
            foreach (string item in Directory.GetDirectories(dir))
            {
                try
                {
                    if (regexPattern == null || Regex.IsMatch(Path.GetFileName(item), regexPattern, RegexOptions.IgnoreCase | RegexOptions.Multiline))
                    { lst.Add(item); }

                    //递归
                    if (recurse) { lst.AddRange(GetDirectories(item, regexPattern, true)); }
                }
                catch { if (throwEx) { throw; } }
            }
        }
        catch { if (throwEx) { throw; } }

        return lst.ToArray();
    }

    public static bool Exists(string str)
    {
        string newStr = str.Substring(str.IndexOf("/"));
        string result = Application.dataPath + newStr;
        result = result.Substring(0, result.Length - 1);
        //Debug.Log(result);
        if (!Directory.Exists(result))
        {
            return false;
        }
        else
        {
            return true;
        }
    }

    public static string FindPath(string root,string condition)
    {
        string result = "";
        string[] allDir = MeshPainterStringUtility.GetDirectories(root, condition, true);
        string dir = allDir[0];
        string[] arr = dir.Split(new char[] { '/', '\\' });
        for (int i = 0; i < arr.Length; i++)
        {
            if(i ==0)
            {
                result = arr[i];
            }
            else
            {
                result = result + "/" + arr[i];
            }
        }
        //Debug.Log("结果:" + result);
        return result;
    }

    public static string RelativePath(string path)
    {
        string ad = Application.dataPath;
        string result = path.Substring(ad.LastIndexOf('/')+1);
        return result;
    }
}

