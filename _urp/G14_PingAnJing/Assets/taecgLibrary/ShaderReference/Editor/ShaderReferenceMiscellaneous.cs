/**
 * @file         ShaderReferenceMath.cs
 * @author       Hongwei Li(taecg@qq.com)
 * @created      2018-12-05
 * @updated      2020-03-09
 *
 * @brief        杂项，一些算法技巧
 */

#if UNITY_EDITOR
using System.Collections.Generic;
using UnityEditor;
using UnityEngine;

namespace taecg.tools.shaderReference
{
    public class ShaderReferenceMiscellaneous : EditorWindow
    {
        #region 数据成员
        private Vector2 scrollPos;
        #endregion

        public void DrawMainGUI()
        {
            scrollPos = EditorGUILayout.BeginScrollView(scrollPos);
            ShaderReferenceUtil.DrawTitle("UV");
            ShaderReferenceUtil.DrawOneContent("UV重映射到中心位置", "float2 centerUV = uv * 2 - 1\n将UV值重映射为(-1,-1)~(1,1)，也就是将UV的中心点从左下角移动到中间位置。");
            ShaderReferenceUtil.DrawOneContent("画圆", "float circle = smoothstep(_Radius, (_Radius + _CircleFade), length(uv * 2 - 1));\n利用UV来画圆，通过_Radius来调节大小，_CircleFade来调节边缘虚化程序。");
            ShaderReferenceUtil.DrawOneContent("画矩形", "float2 centerUV = abs(i.uv.xy * 2 - 1);\n" +
                "float rectangleX = smoothstep(_Width, (_Width + _RectangleFade), centerUV.x);\n" +
                "float rectangleY = smoothstep(_Heigth, (_Heigth + _RectangleFade), centerUV.y);\n" +
                "float rectangleClamp = clamp((rectangleX + rectangleY), 0.0, 1.0);\n" +
                "利用UV来画矩形，_Width调节宽度，_Height调节高度，_RectangleFade调节边缘虚化度。");
            ShaderReferenceUtil.DrawOneContent("黑白棋盘格", "float2 uv = i.uv;\n" +
                "uv = floor(uv) * 0.5;\n" +
                "float c = frac(uv.x + uv.y) * 2;\n" +
                "return c;");
            ShaderReferenceUtil.DrawOneContent("极坐标", "float2 centerUV = (i.uv * 2 - 1);\n" +
                "float atan2UV = 1 - abs(atan2(centerUV.g, centerUV.r) / 3.14);\n" +
                "利用UV来实现极坐标.");
            ShaderReferenceUtil.DrawOneContent("将0-1的值控制在某个自定义的区间内", "frac(x*n+n);\n比如frac(i.uv*3.33+3.33);就是将0-1的uv值重新定义为0.33-0.66");
            ShaderReferenceUtil.DrawOneContent("随机", "1.frac(sin(dot(i.uv.xy, float2(12.9898, 78.233))) * 43758.5453);\n2.frac(sin(x)*n);");
            ShaderReferenceUtil.DrawOneContent("旋转", "fixed t=_Time.y;\nfloat2 rot= cos(t)*i.uv+sin(t)*float2(i.uv.y,-i.uv.x);");
            ShaderReferenceUtil.DrawOneContent("序列图", "splitUV是把原有的UV重新定位到左上角的第一格UV上，_Sequence.xy表示的是纹理是由几x几的格子组成的,_Sequence.z表示的是走序列的快慢." +
                "\nfloat2 splitUV = uv * (1/_Sequence.xy) + float2(0,_Sequence.y - 1/_Sequence.y);" +
                "\nfloat time = _Time.y * _Sequence.z;" +
                "\nuv = splitUV + float2(floor(time *_Sequence.x)/_Sequence.x,1-floor(time)/_Sequence.y);");
            ShaderReferenceUtil.DrawOneContent("HSV2RGB方法01", "fixed3 hsv2rgb (fixed3 c)\n" +
                "{\n" +
                "\tfloat2 rot= cos(t)*i.uv+sin(t)*float2(i.uv.y,-i.uv.x);\n" +
                "\tfloat3 k = fmod (float3 (5, 3, 1) + c.x * 6, 6);\n" +
                "\treturn c.z - c.z * c.y * max (min (min (k, 4 - k), 1), 0);\n" +
                "}");
            ShaderReferenceUtil.DrawOneContent("HSV2RGB方法02(更优化)", "fixed3 hsv2rgb (fixed3 c)\n" +
                "{\n" +
                "\tfloat4 K = float4 (1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);\n" +
                "\tfloat3 p = abs (frac (c.xxx + K.xyz) * 6.0 - K.www);\n" +
                "\treturn c.z * lerp (K.xxx, saturate (p - K.xxx), c.y);\n" +
                "}");
            ShaderReferenceUtil.DrawTitle("顶点");
            ShaderReferenceUtil.DrawOneContent("模型中心点坐标", "float3 objCenterPos = mul( unity_ObjectToWorld, float4( 0, 0, 0, 1 ) ).xyz;\n" +
                "在Shader中获取当前模型的中心点，其实就是将(0,0,0)点从本地转换到世界空间坐标下即可，在制作对象从下往之类的效果时常用到。");
            ShaderReferenceUtil.DrawOneContent("BillBoard", "在Properties中添加:\n\n" +
            "[Enum(BillBoard,1,VerticalBillboard,0)]BillBoardType(\"BillBoard Type\",float) = 1\n\n" +
            "在顶点着色器中添加:\n\n" +
            "//将相机从世界空间转换到模型的本地空间中,而这个转换后的相机坐标即是点也是模型中心点(0,0,0)到相机的方向向量，如果按照相机空间来定义的话，可以把这个向量定义为相机空间下的Z值\n" +
            "float3  cameraOS_Z = mul(unity_WorldToObject, float4(_WorldSpaceCameraPos, 1));\n" +
            "//BillBoardType=0时,圆柱形BillBoard;BillBoard=1时,圆形BillBoard;\n" +
            "cameraOS_Z.y = cameraOS_Z.y * BillBoardType;\n" +
            "//归一化，使其为长度不变模为1的向量\n" +
            "cameraOS_Z = normalize(cameraOS_Z);\n" +
            "//假设相机空间下的Y轴向量为(0,1,0)\n" +
            "cameraOS_Y = float3(0,1,0);\n" +
            "//利用叉积求出相机空间下的X轴向量\n" +
            "float3 cameraOS_X = normalize(cross(cameraOS_Z,cameraOS_Y));\n" +
            "//再次利用叉积求出相机空间下的Y轴向量\n" +
            "cameraOS_Y = cross(cameraOS_X,cameraOS_Z);\n" +
            "//通过向量与常数相乘来把顶点的X轴与Y对应到cameraOS的X与Y轴向上\n" +
            "float3 billboardPositionOS = cameraOS_X * v.vertex.x + cameraOS_Y * v.vertex.y;\n" +
            "o.pos = UnityObjectToClipPos(billboardPositionOS);");
            ShaderReferenceUtil.DrawOneContent("网格阴影", "half4 worldPos = mul(unity_ObjectToWorld, v.vertex);\n" +
                "worldPos.y = 2.47;\n" +
                "worldPos.xz += fixed2(阴影X方向,阴影Z方向)*v.vertex.y;\n" +
                "o.pos = mul(UNITY_MATRIX_VP,worldPos);");

            ShaderReferenceUtil.DrawTitle("其它 ");
            ShaderReferenceUtil.DrawOneContent("菲涅尔 ", "fixed4 rimColor = fixed4 (0, 0.4, 1, 1);\n " +
                "half3 worldViewDir = normalize (UnityWorldSpaceViewDir (i.worldPos));\n " +
                "float ndotv = dot (i.normal, worldViewDir);\n " +
                "float fresnel = (0.2 + 2.0 * pow (1.0 - ndotv, 2.0));\n " +
                "fixed4 col = rimColor * fresnel;");
            ShaderReferenceUtil.DrawOneContent("XRay射线 ", "1. 新建一个Pass\n2.设置自己想要的Blend\n3.Zwrite Off关闭深度写入\n4.Ztest greater深度测试设置为大于 ");
            EditorGUILayout.EndScrollView();
        }
    }
}
#endif