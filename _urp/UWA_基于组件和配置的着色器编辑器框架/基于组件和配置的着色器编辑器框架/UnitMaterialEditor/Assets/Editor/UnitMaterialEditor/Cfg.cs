using System;
using UnityEditor;
using UnityEngine;
using UnityEngine.Rendering;

namespace UME {

    public partial class UnitMaterialEditor {

        /// <summary>
        /// 材质编辑器配置中使用的关键词
        /// </summary>
        public static class Cfg {
            /// <summary>
            /// 为单属性编辑器SingleProp固定初始值
            /// </summary>
            public const String Key_FixedValue = "keep";
            /// <summary>
            /// 在指定条件下，为单属性编辑器SingleProp固定初始值
            /// </summary>
            public const String Key_FixedIf = "keep_if";
            /// <summary>
            /// 单属性编辑器，用于升级属性值用
            /// </summary>
            public const String Key_UpgradeFrom = "upgrade_from";
            /// <summary>
            /// 用于条件性的指定编辑器功能开启
            /// </summary>
            public const String Key_EnableIf = "enable_if";
            /// <summary>
            /// 为编辑器指定标签
            /// </summary>
            public const String Key_GUILabel = "label";
            /// <summary>
            /// 为单属性编辑器指定GUI类型，用于覆盖默认属性编辑器类型
            /// </summary>
            public const String Key_PropGUIType = "gui";
            /// <summary>
            /// 为单属性编辑器指定条件性重置属性功能，默认情况下，当一个编辑器组件隐藏时会将属性重置回默认值
            /// 但是有时候，一个属性可以有多种通途，当一种用途的编辑器组件条件性隐藏时，我们并不希望它的值被重置
            /// </summary>
            public const String Key_ConditionalResetIf = "conditional_reset_if";
            /// <summary>
            /// 为单属性编辑器指定自动重置属性功能
            /// </summary>
            public const String Key_AutoReset = "auto_reset";
            /// <summary>
            /// 为属性编辑器提供精度：low， half， high
            /// </summary>
            public const String Key_Precision = "precision";
            /// <summary>
            /// Range映射区间，用于把有些shader属性不是range类型的强制使用一个自定义范围
            /// </summary>
            public const String Key_Range = "range";
            /// <summary>
            /// Range重新映射区间，有时候为了让编辑器面板上显示出来的值域更适合使用习惯，需要重新把shader中实际运算使用的定义域重新映射到新的范围
            /// 比如shader中表示为比例[0,1]的域，重新定义为便于理解的百分比范围[0,100]，这样的好处是不用在shader中去实时转换比例
            /// </summary>
            public const String Key_MapRange = "map_range";
            /// <summary>
            /// 为HelpBox指定内容
            /// </summary>
            public const String Key_Text = "text";
            /// <summary>
            /// 指定单属性编辑器强制为toggle类型
            /// </summary>
            public const String Value_PropGUIType_Toggle = "toggle";
            /// <summary>
            /// 指定Vector单属性编辑器使用Rect类型UI，把一个Vector类型的属性采用RectField编辑器覆盖
            /// </summary>
            public const String Value_PropGUIType_Rect = "rect";
            /// <summary>
            /// 把Color类型属性指定通道单独拆分为Slider编辑器
            /// </summary>
            public const String Value_PropGUIType_ColorPrefix = "color_";
            public const String Value_PropGUIType_ColorR = "color_r";
            public const String Value_PropGUIType_ColorG = "color_g";
            public const String Value_PropGUIType_ColorB = "color_b";
            public const String Value_PropGUIType_ColorA = "color_a";

            public const String Value_Precision_Low = "low";
            public const String Value_Precision_Half = "half";
            public const String Value_Precision_High = "high";

            public const String Value_CullMode_Off = "off";
            public const String Value_CullMode_Front = "front";
            public const String Value_CullMode_Back = "back";

            /// <summary>
            /// 指定编辑器类型
            /// </summary>
            public const String Key_Editor = "editor";
            /// <summary>
            /// 编辑器参数集
            /// </summary>
            public const String Key_Args = "args";
            /// <summary>
            /// 编辑器ID
            /// </summary>
            public const String Key_ID = "id";
            public const String Key_Name = "name";
            
            /// <summary>
            /// 混合模式限定，用户限定编辑器在特定混合模式下启用
            /// </summary>
            public const String ArgsKey_Mode = "mode";
            public const String ArgsKey_OP = "op";
            public const String ArgsKey_OP_ArgPrefix = "arg";
            public const String ArgsKey_OP_Arg0 = "arg0";
            public const String ArgsKey_OP_Ref = "ref";

            /// <summary>
            /// 混合模式编辑器可以指定可用的模式选项
            /// </summary>
            public const String ArgsKey_Options = "options";

            /// <summary>
            /// 属性名绑定前缀
            /// 当前只用到了StencilSettings中，这样可以为某些多pass配置不同的模板参数分组属性编辑器绑定
            /// 通过来指定前缀来绑定属性分组
            /// 如：{ "editor" : "StencilSettings", "args" : { "name" : "Outline_StencilSettings", "prefix" : "Outline" } },
            /// 上面例子，的编辑器组件，会自定绑定到带有"Outline_"前缀的模板参数组上
            /// </summary>
            public const String ArgsKey_PropPrefix = "prefix";

            /// <summary>
            /// 编辑器初始值参数预设，目前用于StencilSettings配置固定几种使用模式，目前支持：maskout， mask
            /// 用于做一些遮罩和被遮罩的设置
            /// </summary>
            public const String ArgsKey_Preset = "preset";

            /// <summary>
            /// 反转值标记
            /// </summary>
            public const String Command_Value_Invert = "invert";

            public const String ArgsKey_CustomTag_Tags = "tags";
            public const String ArgsKey_CustomTag_Type = "type";
            public const String ArgsKey_CustomTag_Values = "values";

            public const String ArgsKey_CustomTag_Readonly = "readonly";
            /// <summary>
            /// 用于把有些现有的CustomTag迁移到另外一个
            /// </summary>
            public const String ArgsKey_CustomTag_UpgradeTo = "upgrade_to";
            public const String ArgsKey_CustomTag_CopyTo = "copy_to";

            public const String ArgsKey_UpdateKeyword = "keyword";

            /// <summary>
            /// 用于UpdateKeyword组件
            /// 比如：{ "editor" : "UpdateKeyword", "id" : "_UNITY_REFLECTION_PROBE_OVERRIDE_ON", "args" : { "name" : "_unity_SpecCube0_Override", "keyword" : "_UNITY_REFLECTION_PROBE_OVERRIDE_ON", "keyword_property" : { "name" : "_unity_reflection_probe_override", "true" : 1, "false" : 0 } } },
            /// 上面用例说明：当材质属性_unity_SpecCube0_Override求值为真的时候，定义_UNITY_REFLECTION_PROBE_OVERRIDE_ON关键字，并且把另外一个关联属性_unity_reflection_probe_override值设置为1
            /// 实际shader代码中可以使用_unity_reflection_probe_override的值来静态分支代码功能，从而避免生成_UNITY_REFLECTION_PROBE_OVERRIDE_ON的变体
            /// </summary>
            public const String ArgsKey_UpdateKeywordProperty = "keyword_property";
            /// <summary>
            /// 标记Keyword是否是需要强制进行有效性检查，有时候有一些关键词只是起个标记作用，实际上并没有实际变体生成
            /// </summary>
            public const String ArgsKey_UpdateKeyword_Mandatory = "mandatory";

            public const String ArgsKey_SingleProp_Texture_Linear = "linear";

            public const String ArgsKey_SingleProp_Texture_WrapMode = "wrapmode";

            public const String ArgsKey_SingleProp_Texture_Readable = "readable";

            public const String EditorCopyBufferTag = "<UnitMaterialEditor.systemCopyBuffer>";
        }
    }
}
//EOF
