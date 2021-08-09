//******************************************************
//
//	文件名 (File Name) 	: 		ToolsCommon
//	
//	脚本创建者(Author) 	:		E3D

//	创建时间 (CreatTime):		2019/12/11/17/31/9
//******************************************************

namespace E3DCommonTools
{
    using System.Collections;
    using System.Collections.Generic;
    using UnityEngine;

    /// <summary>
    /// 截图图片格式0.
    /// </summary>
    public enum MyImageType_2018
    {
        JPG = 0,
        PNG,
#if UNITY_2018_1_OR_NEWER
        TGA
#else

#endif

    }
    public enum MyImageType_2017
    {
        JPG = 0,
        PNG,
    }

    /// <summary>
    /// 新分辨率
    /// </summary>
    public enum MyImageSize
    {
        _4096 = 4096,
        _2048 = 2048,
        _1080 = 1080,
        _1024 = 1024,
        _720 = 720,
        _512 = 512,
        _256 = 256,
        Custom = int.MaxValue
    }

    /// <summary>
    /// 截图类型
    /// </summary>
    public enum MyScreenShotImageType
    {
        /// <summary>
        /// 原图输出
        /// </summary>
        RGBA = 0,
        /// <summary>
        /// 深度图输出
        /// </summary>
        Depth,
        /// <summary>
        /// 深度法线
        /// </summary>
        DepthNormal
    }
}
