using UnityEngine;
using UnityEngine.Rendering;
/// <summary>
/// 阴影管理类
/// </summary>
public class Shadows
{

	const string bufferName = "Shadows";

	CommandBuffer buffer = new CommandBuffer
	{
		name = bufferName
	};

	ScriptableRenderContext context;

	CullingResults cullingResults;

	ShadowSettings settings;
	//可投射阴影的定向光源最大数量
	const int maxShadowedDirectionalLightCount = 4;
	//最大级联数量
	const int maxCascades = 4;
	//定向光的阴影数据
	struct ShadowedDirectionalLight
	{
        //可见光索引
		public int visibleLightIndex;
		//斜度比例偏差值
		public float slopeScaleBias;
		//近平面偏移
		public float nearPlaneOffset;
	}
	//存储可投射阴影的定向光源的数据
	ShadowedDirectionalLight[] ShadowedDirectionalLights = new ShadowedDirectionalLight[maxShadowedDirectionalLightCount];
	//已存储的可投射阴影的定向光数量
	int ShadowedDirectionalLightCount;

	static int dirShadowAtlasId = Shader.PropertyToID("_DirectionalShadowAtlas");
    
    static int dirShadowMatricesId = Shader.PropertyToID("_DirectionalShadowMatrices");

	static int cascadeCountId = Shader.PropertyToID("_CascadeCount");
	static int cascadeCullingSpheresId = Shader.PropertyToID("_CascadeCullingSpheres");
	static int cascadeDataId = Shader.PropertyToID("_CascadeData");
    //存储级联数据
	static Vector4[] cascadeData = new Vector4[maxCascades];

    //存储级联包围球数据
	static Vector4[] cascadeCullingSpheres = new Vector4[maxCascades];

	static int shadowDistanceFadeId = Shader.PropertyToID("_ShadowDistanceFade");
    
    static int shadowAtlasSizeId = Shader.PropertyToID("_ShadowAtlasSize");
    //定向光源的PCF滤波模式
    static string[] directionalFilterKeywords = {
        "_DIRECTIONAL_PCF3",
        "_DIRECTIONAL_PCF5",
        "_DIRECTIONAL_PCF7",
    };
    //级联混合模式
    static string[] cascadeBlendKeywords = {
        "_CASCADE_BLEND_SOFT",
        "_CASCADE_BLEND_DITHER"
    };
    //存储光源的阴影转换矩阵
    static Matrix4x4[] dirShadowMatrices = new Matrix4x4[maxShadowedDirectionalLightCount * maxCascades];
    public void Setup(
		ScriptableRenderContext context, CullingResults cullingResults,
		ShadowSettings settings
	)
	{
		this.context = context;
		this.cullingResults = cullingResults;
		this.settings = settings;

		ShadowedDirectionalLightCount = 0;
	}
    /// <summary>
    /// 执行缓冲区命令并清除缓冲区
    /// </summary>
    void ExecuteBuffer()
	{
		context.ExecuteCommandBuffer(buffer);
		buffer.Clear();
	}
	/// <summary>
    /// 存储定向光源的阴影数据
    /// </summary>
    /// <param name="light"></param>
    /// <param name="visibleLightIndex"></param>
    /// <returns></returns>
	public Vector3 ReserveDirectionalShadows(Light light, int visibleLightIndex) {

		if (ShadowedDirectionalLightCount < maxShadowedDirectionalLightCount && light.shadows != LightShadows.None && light.shadowStrength > 0f

			&& cullingResults.GetShadowCasterBounds(visibleLightIndex,out Bounds b))
		{
			ShadowedDirectionalLights[ShadowedDirectionalLightCount] = new ShadowedDirectionalLight{ visibleLightIndex = visibleLightIndex,slopeScaleBias = light.shadowBias, 
				nearPlaneOffset = light.shadowNearPlane };
            //返回阴影强度、阴影图块的偏移索引、法线偏差
            return new Vector3(light.shadowStrength, settings.directional.cascadeCount * ShadowedDirectionalLightCount++, light.shadowNormalBias);
        }
		return Vector3.zero;
    }
	/// <summary>
    /// 渲染阴影
    /// </summary>
	public void Render()
    {
        if (ShadowedDirectionalLightCount > 0)
        {
			RenderDirectionalShadows();
		}
    }
	/// <summary>
    /// 渲染定向光阴影
    /// </summary>
    void RenderDirectionalShadows() {
        int atlasSize = (int)settings.directional.atlasSize;
        buffer.GetTemporaryRT(dirShadowAtlasId, atlasSize, atlasSize, 32, FilterMode.Bilinear, RenderTextureFormat.Shadowmap);
        //指定渲染的阴影数据存储到阴影图集中
        buffer.SetRenderTarget(dirShadowAtlasId, RenderBufferLoadAction.DontCare, RenderBufferStoreAction.Store);
        //清除深度缓冲区
        buffer.ClearRenderTarget(true, false, Color.clear);

		buffer.BeginSample(bufferName);
        ExecuteBuffer();
		//要分割的图块数量和大小
		int tiles = ShadowedDirectionalLightCount * settings.directional.cascadeCount;
		int split = tiles <= 1 ? 1 : tiles <= 4 ? 2 : 4;
        int tileSize = atlasSize / split;
        //遍历所有光源渲染阴影贴图
        for (int i = 0; i < ShadowedDirectionalLightCount; i++)
		{
			RenderDirectionalShadows(i,split, tileSize);
		}

		buffer.SetGlobalInt(cascadeCountId, settings.directional.cascadeCount);
		buffer.SetGlobalVectorArray(cascadeCullingSpheresId, cascadeCullingSpheres);
		//发送级联数据
		buffer.SetGlobalVectorArray(cascadeDataId, cascadeData);
		//发送阴影转换矩阵
		buffer.SetGlobalMatrixArray(dirShadowMatricesId, dirShadowMatrices);
		//最大阴影距离和淡入距离发送GPU
		float f = 1f - settings.directional.cascadeFade;
		buffer.SetGlobalVector(shadowDistanceFadeId,new Vector4(1f / settings.maxDistance, 1f / settings.distanceFade,1f / (1f - f * f)));

        //设置关键字
        SetKeywords(directionalFilterKeywords, (int)settings.directional.filter - 1);
        SetKeywords(cascadeBlendKeywords, (int)settings.directional.cascadeBlend - 1);
        //传递图集大小和纹素大小
        buffer.SetGlobalVector( shadowAtlasSizeId, new Vector4(atlasSize, 1f / atlasSize));

        buffer.EndSample(bufferName);
		ExecuteBuffer();
	}
	/// <summary>
    /// 渲染单个定向光源阴影
    /// </summary>
    /// <param name="index"></param>
    /// <param name="split"></param>
    /// <param name="tileSize"></param>
	void RenderDirectionalShadows(int index, int split, int tileSize)
	{
		ShadowedDirectionalLight light = ShadowedDirectionalLights[index];
		var shadowSettings = new ShadowDrawingSettings(cullingResults, light.visibleLightIndex);

		int cascadeCount = settings.directional.cascadeCount;
		int tileOffset = index * cascadeCount;
		Vector3 ratios = settings.directional.CascadeRatios;
        float cullingFactor = Mathf.Max(0f, 0.8f - settings.directional.cascadeFade);
        for (int i=0;i<cascadeCount;i++)
        {
			//计算视图和投影矩阵和裁剪空间的立方体
			cullingResults.ComputeDirectionalShadowMatricesAndCullingPrimitives(light.visibleLightIndex, i, cascadeCount,ratios, tileSize, light.nearPlaneOffset,
				out Matrix4x4 viewMatrix, out Matrix4x4 projectionMatrix, out ShadowSplitData splitData);
			//得到第一个光源的包围球数据
            if (index == 0)
            {
				//设置级联数据
				SetCascadeData(i, splitData.cullingSphere, tileSize);
			}
            
            //剔除偏差
            splitData.shadowCascadeBlendCullingFactor = cullingFactor;
            //剔除投影对象的数据
            shadowSettings.splitData = splitData;
			//设置视口图块
			int tileIndex = tileOffset + i;
			//得到从世界空间到阴影纹理图块空间的转换矩阵
			dirShadowMatrices[tileIndex] = ConvertToAtlasMatrix(projectionMatrix * viewMatrix,SetTileViewport(tileIndex, split, tileSize), split);
			//设置视图投影矩阵
			buffer.SetViewProjectionMatrices(viewMatrix, projectionMatrix);
            //设置斜度比例偏差值
            buffer.SetGlobalDepthBias(0, light.slopeScaleBias);
            //绘制阴影
            ExecuteBuffer();
			context.DrawShadows(ref shadowSettings);
            buffer.SetGlobalDepthBias(0f, 0f);
        }
		
	}

    /// <summary>
    /// 设置级联数据
    /// </summary>
    /// <param name="index"></param>
    /// <param name="cullingSphere"></param>
    /// <param name="tileSize"></param>
	void SetCascadeData(int index, Vector4 cullingSphere, float tileSize)
	{
		//包围球半径除以阴影图块大小=近似纹素大小
		float texelSize = 2f * cullingSphere.w / tileSize;

        float filterSize = texelSize * ((float)settings.directional.filter + 1f);
        //得到半径的平方值
        cullingSphere.w -= filterSize;
        cullingSphere.w *= cullingSphere.w;
		cascadeCullingSpheres[index] = cullingSphere;
		cascadeData[index] = new Vector4(1f / cullingSphere.w, filterSize * 1.4142136f);
	}

	/// <summary>
    /// 释放申请的RT内存
    /// </summary>
	public void Cleanup()
	{       
        buffer.ReleaseTemporaryRT(dirShadowAtlasId);
		ExecuteBuffer();
	}
    /// <summary>
    /// 设置视口的图块
    /// </summary>
    /// <param name="index"></param>
    /// <param name="split"></param>
    /// <param name="tileSize"></param>
    /// <returns></returns>
    Vector2 SetTileViewport(int index, int split,float tileSize)
    {
        //计算索引图块的偏移位置
        Vector2 offset = new Vector2(index % split, index / split);
        //设置渲染视口，拆分成多个图块
        buffer.SetViewport(new Rect( offset.x * tileSize, offset.y * tileSize, tileSize, tileSize ));
        return offset;
    }
    /// <summary>
    /// 得到从世界空间到阴影纹理图块空间的转换矩阵
    /// </summary>
    /// <param name="m"></param>
    /// <param name="offset"></param>
    /// <param name="scale"></param>
    /// <returns></returns>
     Matrix4x4 ConvertToAtlasMatrix(Matrix4x4 m, Vector2 offset, int split)
    {
        //如果使用了反向Zbuffer
        if (SystemInfo.usesReversedZBuffer)
        {
            m.m20 = -m.m20;
            m.m21 = -m.m21;
            m.m22 = -m.m22;
            m.m23 = -m.m23;
        }
        //设置矩阵坐标
        float scale = 1f / split;
        m.m00 = (0.5f * (m.m00 + m.m30) + offset.x * m.m30) * scale;
        m.m01 = (0.5f * (m.m01 + m.m31) + offset.x * m.m31) * scale;
        m.m02 = (0.5f * (m.m02 + m.m32) + offset.x * m.m32) * scale;
        m.m03 = (0.5f * (m.m03 + m.m33) + offset.x * m.m33) * scale;
        m.m10 = (0.5f * (m.m10 + m.m30) + offset.y * m.m30) * scale;
        m.m11 = (0.5f * (m.m11 + m.m31) + offset.y * m.m31) * scale;
        m.m12 = (0.5f * (m.m12 + m.m32) + offset.y * m.m32) * scale;
        m.m13 = (0.5f * (m.m13 + m.m33) + offset.y * m.m33) * scale;
        m.m20 = 0.5f * (m.m20 + m.m30);
        m.m21 = 0.5f * (m.m21 + m.m31);
        m.m22 = 0.5f * (m.m22 + m.m32);
        m.m23 = 0.5f * (m.m23 + m.m33);
        return m;
    }
    /// <summary>
    /// 设置关键字
    /// </summary>
    /// <param name="keywords"></param>
    /// <param name="enabledIndex"></param>
    void SetKeywords(string[] keywords, int enabledIndex)
    {
       // int enabledIndex = (int)settings.directional.filter - 1;
        for (int i = 0; i < keywords.Length; i++)
        {
            if (i == enabledIndex)
            {
                buffer.EnableShaderKeyword(keywords[i]);
            }
            else
            {
                buffer.DisableShaderKeyword(keywords[i]);
            }
        }
    }
}