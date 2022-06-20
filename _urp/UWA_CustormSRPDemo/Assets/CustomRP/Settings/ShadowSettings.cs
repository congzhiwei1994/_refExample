using UnityEngine;
/// <summary>
/// 渲染管线中的阴影配置
/// </summary>
[System.Serializable]
public class ShadowSettings
{
	//阴影最大距离
	[Min(0.001f)]
	public float maxDistance = 100f;
	//阴影过渡距离
	[Range(0.001f, 1f)]
	public float distanceFade = 0.1f;
	//阴影图集大小
	public enum TextureSize
	{
		_256 = 256, _512 = 512, _1024 = 1024,
		_2048 = 2048, _4096 = 4096, _8192 = 8192
	}
    //PCF滤波模式
    public enum FilterMode
    {
        PCF2x2, PCF3x3, PCF5x5, PCF7x7
    }
   
   
    /// <summary>
	/// 定向光源的阴影配置
	/// </summary>
    [System.Serializable]
	public struct Directional
	{
		public TextureSize atlasSize;

        public FilterMode filter;

        //级联数量
        [Range(1, 4)]
		public int cascadeCount;
		//级联比例
		[Range(0f, 1f)]
		public float cascadeRatio1, cascadeRatio2, cascadeRatio3;

		public Vector3 CascadeRatios => new Vector3(cascadeRatio1, cascadeRatio2, cascadeRatio3);
		//级联过渡值
		[Range(0.001f, 1f)]
		public float cascadeFade;
		//级联混合模式
        public enum CascadeBlendMode
        {
            Hard, Soft, Dither
        }
        public CascadeBlendMode cascadeBlend;
    }
	//设置阴影配置的默认值
	public Directional directional = new Directional
	{
		atlasSize = TextureSize._1024,
        filter = FilterMode.PCF2x2,
        cascadeCount = 4,
		cascadeRatio1 = 0.1f,
		cascadeRatio2 = 0.25f,
		cascadeRatio3 = 0.5f,
		cascadeFade = 0.1f,
        cascadeBlend = Directional.CascadeBlendMode.Hard
    };

	
}
