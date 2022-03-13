//******************************************************
//
//	文件名 (File Name) 	: 		ToolsCommon
//	
//	脚本创建者(Author) 	:		Ejoy_小林

//	创建时间 (CreatTime):		2019/12/11/17/31/9
//******************************************************

namespace ClTools
{
    using System.Collections;
    using System.Collections.Generic;
    using UnityEngine;

    /// <summary>
    /// 截图图片格式
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
        _4K = 4096,
        _2K = 2048,
        _1080p = 1080,
        _720p = 720,
        _480p = 480,
        _240p = 240,
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
