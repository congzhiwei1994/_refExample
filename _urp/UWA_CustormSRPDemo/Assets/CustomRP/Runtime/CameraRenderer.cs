using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
/// <summary>
/// 相机渲染管理类：单独控制每个相机的渲染
/// </summary>
public partial class CameraRenderer
{

    ScriptableRenderContext context;

    Camera camera;

    const string bufferName = "Render Camera";

    CommandBuffer buffer = new CommandBuffer
    {
        name = bufferName
    };
    //存储相机剔除后的结果
    CullingResults cullingResults;
    static ShaderTagId unlitShaderTagId = new ShaderTagId("SRPDefaultUnlit");
    static ShaderTagId litShaderTagId = new ShaderTagId("CustomLit");
    //光照实例
    Lighting lighting = new Lighting();
    /// <summary>
    /// 相机渲染
    /// </summary>
    public void Render(ScriptableRenderContext context, Camera camera,
        bool useDynamicBatching, bool useGPUInstancing,ShadowSettings shadowSettings)
    {
        this.context = context;
        this.camera = camera;
        //设置buffer缓冲区的名字
        PrepareBuffer();
        // 在Game视图绘制的几何体也绘制到Scene视图中
        PrepareForSceneWindow();

        if (!Cull(shadowSettings.maxDistance))
        {
            return;
        }
        buffer.BeginSample(SampleName);
        ExecuteBuffer();

        lighting.Setup(context, cullingResults, shadowSettings);
        buffer.EndSample(SampleName);
        Setup();

        //绘制几何体
        DrawVisibleGeometry(useDynamicBatching, useGPUInstancing);
        //绘制SRP不支持的内置shader类型
        DrawUnsupportedShaders();

        //绘制Gizmos
        DrawGizmos();
        // 释放申请的RT内存空间
        lighting.Cleanup();

        //提交命令缓冲区
        Submit();
    }

    /// <summary>
    /// 绘制几何体
    /// </summary>
    void DrawVisibleGeometry(bool useDynamicBatching, bool useGPUInstancing)
    {
        //设置绘制顺序和指定渲染相机
        var sortingSettings = new SortingSettings(camera)
        {
            criteria = SortingCriteria.CommonOpaque
        };
        //设置渲染的shader pass和渲染排序
        var drawingSettings = new DrawingSettings(unlitShaderTagId, sortingSettings)
        {
            //设置渲染时批处理的使用状态
            enableDynamicBatching = useDynamicBatching,
            enableInstancing = useGPUInstancing
        };
        //渲染CustomLit表示的pass块
        drawingSettings.SetShaderPassName(1, litShaderTagId);
        ////只绘制RenderQueue为opaque不透明的物体
        var filteringSettings = new FilteringSettings(RenderQueueRange.opaque);
        //1.绘制不透明物体
        context.DrawRenderers(cullingResults, ref drawingSettings, ref filteringSettings);
        
        //2.绘制天空盒
        context.DrawSkybox(camera);

        sortingSettings.criteria = SortingCriteria.CommonTransparent;
        drawingSettings.sortingSettings = sortingSettings;
        //只绘制RenderQueue为transparent透明的物体
        filteringSettings.renderQueueRange = RenderQueueRange.transparent;
        //3.绘制透明物体
        context.DrawRenderers(cullingResults, ref drawingSettings, ref filteringSettings);

    }
    /// <summary>
    /// 提交命令缓冲区
    /// </summary>
    void Submit()
    {
        buffer.EndSample(SampleName);
        ExecuteBuffer();
        context.Submit();
    }
    /// <summary>
    /// 设置相机的属性和矩阵
    /// </summary>
    void Setup()
    {
        context.SetupCameraProperties(camera);
        //得到相机的clear flags
        CameraClearFlags flags = camera.clearFlags;
        //设置相机清除状态
        buffer.ClearRenderTarget(flags <= CameraClearFlags.Depth, flags == CameraClearFlags.Color, 
            flags == CameraClearFlags.Color ? camera.backgroundColor.linear : Color.clear);
        buffer.BeginSample(SampleName);     
        ExecuteBuffer();
        
    }
    /// <summary>
    /// 执行缓冲区命令
    /// </summary>
    void ExecuteBuffer()
    {
        context.ExecuteCommandBuffer(buffer);
        buffer.Clear();
    }
    /// <summary>
    /// 剔除
    /// </summary>
    /// <returns></returns>
    bool Cull(float maxShadowDistance)
    {
        ScriptableCullingParameters p;

        if (camera.TryGetCullingParameters(out p))
        {
            //得到最大阴影距离,和相机远裁剪面距离作比较，取最小的那个作为阴影距离
            p.shadowDistance = Mathf.Min(maxShadowDistance, camera.farClipPlane);
            cullingResults = context.Cull(ref p);
            return true;
        }
        return false;
    }
}
