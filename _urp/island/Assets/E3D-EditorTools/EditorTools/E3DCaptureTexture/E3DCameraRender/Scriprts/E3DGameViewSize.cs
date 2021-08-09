//******************************************************
//
//	文件名 (File Name) 	: 		CustomGameViewSize
//	
//	脚本创建者(Author) 	:		E3D

//	创建时间 (CreatTime):		2019/12/10/16/21/29
//******************************************************

using System;
using System.Collections;
using System.Reflection;
using UnityEngine;
using UnityEditor;

/// <summary>
/// Game视图分辨率控制
/// 参考官方插件Recorder
/// </summary>
public static class E3DGameViewSize
{
    static object s_InitialSizeObj;
    public static int modifiedResolutionCount;
    const int miscSize = 1;

    const string playGameViewType = "UnityEditor.PlayModeView,UnityEditor";
    const string playGetGameViewFuncName = "GetMainPlayModeView";


    const string gameViewType = "UnityEditor.GameView,UnityEditor";
    const string getGameViewFuncName = "GetMainGameView";
    //版本宏定义。标识2019.3或者更新的版本
#if UNITY_2019_3_OR_NEWER
    static Type s_GameViewType = Type.GetType(playGameViewType);
    static string s_GetGameViewFuncName = playGetGameViewFuncName;
#else
    static Type s_GameViewType = Type.GetType(gameViewType);
    static string s_GetGameViewFuncName = getGameViewFuncName;
#endif

    static EditorWindow GetMainGameView()
    {
        var getMainGameVirw = s_GameViewType.GetMethod(s_GetGameViewFuncName, BindingFlags.NonPublic | BindingFlags.Static);
        if (getMainGameVirw == null)
        {
            Debug.LogError(string.Format("Can't find the main Game View : {0} function was not found in {1} type ! Did API change ?",
                s_GetGameViewFuncName, s_GameViewType));
            return null;
        }
        var res = getMainGameVirw.Invoke(null, null);
        return (EditorWindow)res;
    }

    public static void GetGameRenderSize(out int width, out int height)
    {
        var gameView = GetMainGameView();
        if (gameView == null)
        {
            width = height = miscSize;
            return;
        }

        var prop = gameView.GetType().GetProperty("targetSize", BindingFlags.NonPublic | BindingFlags.Instance);
        var size = (Vector2)prop.GetValue(gameView, new object[] { });
        width = (int)size.x;
        height = (int)size.y;
    }

    const string gameViewSize = "UnityEditor.GameViewSize,UnityEditor";
    const string gameViewSizeType = "UnityEditor.GameViewSizeType,UnityEditor";

    static object Group()
    {
        var T = Type.GetType("UnityEditor.GameViewSizes,UnityEditor");
        var sizes = T.BaseType.GetProperty("instance", BindingFlags.Public | BindingFlags.Static);
        var instance = sizes.GetValue(null, new object[] { });

        var currentGroup = instance.GetType().GetProperty("currentGroup", BindingFlags.Public | BindingFlags.Instance);
        var group = currentGroup.GetValue(instance, new object[] { });
        return group;
    }

    /// <summary>
    /// 设置自定义
    /// </summary>
    /// <param name="widthAndHeight"></param>
    /// <returns></returns>
    public static object SetCustomSizwWEH(int widthAndHeight)
    {
        return SetCustomSize(widthAndHeight, widthAndHeight);
    }

    public static object SetCustomSize(int width, int height)
    {
        var sizeObj = FindGameViewSizeObj();
        if (sizeObj != null)
        {
            sizeObj.GetType().GetField("m_Width", BindingFlags.NonPublic | BindingFlags.Instance).SetValue(sizeObj, width);
            sizeObj.GetType().GetField("m_Height", BindingFlags.NonPublic | BindingFlags.Instance).SetValue(sizeObj, height);
        }
        else
        {
            //没有的话就添加
            sizeObj = AddSize(width, height);
        }

        return sizeObj;
    }

    #region Find Size
 /// <summary>
    /// 选中已有的分辨率
    /// </summary>
    /// <param name="width"></param>
    /// <param name="height"></param>
    /// <returns></returns>
    public static int FindSize(int width, int height)
    {
        var T = Type.GetType("UnityEditor.GameViewSizes,UnityEditor");
        var sizes = T.BaseType.GetProperty("instance", BindingFlags.Public | BindingFlags.Static);
        var getGroup = T.GetMethod("GetGroup");
        var instance = sizes.GetValue(null, new object[] { });

        var group = getGroup.Invoke(instance, new object[] { (int)0 });
        var groupType = group.GetType();
        var getBuiltinCount = groupType.GetMethod("GetBuiltinCount");
        var getCustomCount = groupType.GetMethod("GetCustomCount");
        int sizesCount = (int)getBuiltinCount.Invoke(group, null) + (int)getCustomCount.Invoke(group, null);
        var getGameViewSize = groupType.GetMethod("GetGameViewSize");
        var gvsType = getGameViewSize.ReturnType;
        var widthProp = gvsType.GetProperty("width");
        var heightProp = gvsType.GetProperty("height");
        var indexValue = new object[1];
        for (int i = 0; i < sizesCount; i++)
        {
            indexValue[0] = i;
            var size = getGameViewSize.Invoke(group, indexValue);
            int sizeWidth = (int)widthProp.GetValue(size, null);
            int sizeHeight = (int)heightProp.GetValue(size, null);
            if (sizeWidth == width && sizeHeight == height)
                return i;
        }
        return -1;
    }


    public static void SetSize(int index)
    {
        var gvWndType = typeof(Editor).Assembly.GetType("UnityEditor.GameView");
        var selectedSizeIndexProp = gvWndType.GetProperty("selectedSizeIndex",
                BindingFlags.Instance | BindingFlags.Public | BindingFlags.NonPublic);
        var gvWnd = EditorWindow.GetWindow(gvWndType);
        selectedSizeIndexProp.SetValue(gvWnd, index, null);
    }
    #endregion

    static object FindGameViewSizeObj()
    {
        var group = Group();

        var customs = group.GetType().GetField("m_Custom", BindingFlags.NonPublic | BindingFlags.Instance).GetValue(group);

        var itr = (IEnumerator)customs.GetType().GetMethod("GetEnumerator").Invoke(customs, new object[] { });
        while (itr.MoveNext())
        {
            var txt = (string)itr.Current.GetType().GetField("m_BaseText", BindingFlags.NonPublic | BindingFlags.Instance).GetValue(itr.Current);
            if (txt == "(Recording resolution)")
                return itr.Current;
        }

        return null;
    }

    static object NewSizeObj(int width, int height, string name = "New Resolution")
    {
        var T = Type.GetType(gameViewSize);
        var tt = Type.GetType(gameViewSizeType);

        var c = T.GetConstructor(new[] { tt, typeof(int), typeof(int), typeof(string) });
        var sizeObj = c.Invoke(new object[] { 1, width, height, name });
        return sizeObj;
    }

    /// <summary>
    /// 添加一个Game 矩形分辨率
    /// </summary>
    /// <param name="widthAndHeight">宽高相等</param>
    /// <returns></returns>
    public static object AddSizeWidthEqualHeigh(int widthAndHeight)
    {
      return  AddSize(widthAndHeight,widthAndHeight);
    }
    public static object AddSize(int width, int height)
    {
        var sizeObj = NewSizeObj(width, height);

        var group = Group();
        var obj = group.GetType().GetMethod("AddCustomSize", BindingFlags.Public | BindingFlags.Instance);
        obj.Invoke(group, new[] { sizeObj });

        return sizeObj;
    }

    static int IndexOf(object sizeObj)
    {
        var group = Group();
        var method = group.GetType().GetMethod("IndexOf", BindingFlags.Public | BindingFlags.Instance);
        var index = (int)method.Invoke(group, new[] { sizeObj });

        var builtinList = group.GetType().GetField("m_Builtin", BindingFlags.NonPublic | BindingFlags.Instance).GetValue(group);
        method = builtinList.GetType().GetMethod("Contains");
        if ((bool)method.Invoke(builtinList, new[] { sizeObj }))
            return index;

        method = group.GetType().GetMethod("GetBuiltinCount");
        index += (int)method.Invoke(group, new object[] { });
        return index;
    }
    public static void SelectSize(object size)
    {
        var index = IndexOf(size);

        var gameView = GetMainGameView();
        if (gameView == null) return;

        var obj = gameView.GetType().GetMethod("SizeSelectionCallback", BindingFlags.Public | BindingFlags.Instance);
        obj.Invoke(gameView, new[] { index, size });
    }

    public static object currentSize
    {
        get
        {
            var gv = GetMainGameView();
            if (gv == null)
                return new[] { miscSize, miscSize };

            var prop = gv.GetType().GetProperty("currentGameViewSize", BindingFlags.NonPublic | BindingFlags.Instance);
            return prop.GetValue(gv, new object[] { });
        }
    }

    /// <summary>
    /// 备份当前大小
    /// </summary>
    public static void BackupCurrentSize()
    {
        s_InitialSizeObj = currentSize;
    }

    /// <summary>
    /// 恢复大小
    /// </summary>
    public static void RestoreSize()
    {
        SelectSize(s_InitialSizeObj);
        s_InitialSizeObj = null;
    }

}
