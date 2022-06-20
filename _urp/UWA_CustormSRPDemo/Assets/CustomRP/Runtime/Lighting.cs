using Unity.Collections;
using UnityEngine;
using UnityEngine.Rendering;
/// <summary>
/// 灯光管理类
/// </summary>
public class Lighting
{

	const string bufferName = "Lighting";

	CommandBuffer buffer = new CommandBuffer
	{
		name = bufferName
	};
    //设置最大可见定向光数量
    const int maxDirLightCount = 4;


    static int dirLightCountId = Shader.PropertyToID("_DirectionalLightCount");
    static int dirLightColorsId = Shader.PropertyToID("_DirectionalLightColors");
    static int dirLightDirectionsId = Shader.PropertyToID("_DirectionalLightDirections");
    static int dirLightShadowDataId = Shader.PropertyToID("_DirectionalLightShadowData");
    //存储定向光的颜色和方向
    static Vector4[] dirLightColors = new Vector4[maxDirLightCount];
    static Vector4[] dirLightDirections = new Vector4[maxDirLightCount];
    //存储定向光的阴影数据
    static Vector4[] dirLightShadowData = new Vector4[maxDirLightCount];
    //存储相机剔除后的结果
    CullingResults cullingResults;

    Shadows shadows = new Shadows();
    //初始化设置
    public void Setup(ScriptableRenderContext context, CullingResults cullingResults,ShadowSettings shadowSettings)
	{
        this.cullingResults = cullingResults;
        buffer.BeginSample(bufferName);
        //阴影的初始化设置
        shadows.Setup(context, cullingResults, shadowSettings);
        //存储并发送所有光源数据
        SetupLights();
        //渲染阴影
        shadows.Render();
        buffer.EndSample(bufferName);
		context.ExecuteCommandBuffer(buffer);
		buffer.Clear();
	}
	/// <summary>
    /// 存储定向光的数据
    /// </summary>
    /// <param name="index"></param>
    /// <param name="visibleIndex"></param>
    /// <param name="visibleLight"></param>
    /// <param name="light"></param>
	void SetupDirectionalLight(int index, ref VisibleLight visibleLight) {
        dirLightColors[index] = visibleLight.finalColor;
        //通过VisibleLight.localToWorldMatrix属性找到前向矢量,它在矩阵第三列，还要进行取反
        dirLightDirections[index] = -visibleLight.localToWorldMatrix.GetColumn(2);
        //存储阴影数据
        dirLightShadowData[index] = shadows.ReserveDirectionalShadows(visibleLight.light, index);
    }
    /// <summary>
    /// 存储并发送所有光源数据
    /// </summary>
    /// <param name="useLightsPerObject"></param>
    /// <param name="renderingLayerMask"></param>
    void SetupLights() {
        //得到所有影响相机渲染物体的可见光数据
        NativeArray<VisibleLight> visibleLights = cullingResults.visibleLights;
        
        int dirLightCount = 0;
        for (int i = 0; i < visibleLights.Length; i++)
        {
            VisibleLight visibleLight = visibleLights[i];

            if (visibleLight.lightType == LightType.Directional)
            {
                //VisibleLight结构很大,我们改为传递引用不是传递值，这样不会生成副本
                SetupDirectionalLight(dirLightCount++,ref visibleLight);
                //当超过灯光限制数量中止循环
                if (dirLightCount >= maxDirLightCount)
                {
                    break;
                }
            }
        }

        buffer.SetGlobalInt(dirLightCountId, dirLightCount);
        buffer.SetGlobalVectorArray(dirLightColorsId, dirLightColors);
        buffer.SetGlobalVectorArray(dirLightDirectionsId, dirLightDirections);
        buffer.SetGlobalVectorArray(dirLightShadowDataId, dirLightShadowData);
    }
    //释放申请的RT内存
    public void Cleanup()
    {
        shadows.Cleanup();
    }
}
