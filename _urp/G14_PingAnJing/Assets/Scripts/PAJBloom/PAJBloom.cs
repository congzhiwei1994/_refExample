using System;
using UnityEngine.Serialization;

namespace UnityEngine.Rendering.PostProcessing
{

    [Serializable]
    [PostProcess(typeof(PAJBloomRenderer), PostProcessEvent.BeforeStack, "Custom/PAJBloom")]
    public sealed class PAJBloom : PostProcessEffectSettings
    {
        public FloatParameter intensity = new FloatParameter { value = 0f };

        public FloatParameter blurSize = new FloatParameter { value = 0.5f };

        public FloatParameter bloomUpScale = new FloatParameter { value = 0.5f };

        /// <summary>
        /// Distorts the bloom to give an anamorphic look. Negative values distort vertically,
        /// positive values distort horizontally.
        /// </summary>
        [Range(-1f, 1f), Tooltip("Distorts the bloom to give an anamorphic look. Negative values distort vertically, positive values distort horizontally.")]
        public FloatParameter anamorphicRatio = new FloatParameter { value = 0f };


        /// <summary>
        /// Returns <c>true</c> if the effect is currently enabled and supported.
        /// </summary>
        /// <param name="context">The current post-processing render context</param>
        /// <returns><c>true</c> if the effect is currently enabled and supported</returns>
        public override bool IsEnabledAndSupported(PostProcessRenderContext context)
        {
            return enabled.value
                && intensity.value > 0f;
        }
    }

    [UnityEngine.Scripting.Preserve]
    internal sealed class PAJBloomRenderer : PostProcessEffectRenderer<PAJBloom>
    {
        static class ShaderIDs
        {
            internal static readonly int _Bloom_Intensity = Shader.PropertyToID("_Bloom_Intensity");
            internal static readonly int _Blur_Size = Shader.PropertyToID("_Blur_Size");
            internal static readonly int _Bloom_Up_Scale = Shader.PropertyToID("_Bloom_Up_Scale");
            internal static readonly int BloomTex = Shader.PropertyToID("_BloomTex");
        }

        enum Pass
        {
            Prefilter,
            Downsample,
            Upsample,
            Last,
        }

        // [down,up]
        Level[] m_Pyramid;
        const int k_MaxPyramidSize = 16; // Just to make sure we handle 64k screens... Future-proof!

        struct Level
        {
            internal int down;
            internal int up;
        }

        public override void Init()
        {
            m_Pyramid = new Level[k_MaxPyramidSize];

            for (int i = 0; i < k_MaxPyramidSize; i++)
            {
                m_Pyramid[i] = new Level
                {
                    down = Shader.PropertyToID("_BloomMipDown" + i),
                    up = Shader.PropertyToID("_BloomMipUp" + i)
                };
            }
        }

        public override void Render(PostProcessRenderContext context)
        {
            var cmd = context.command;
            cmd.BeginSample("PAJBloomPyramid");

            var sheet = context.propertySheets.Get(Shader.Find("Hidden/PostProcessing/PAJBloom"));

            // Negative anamorphic ratio values distort vertically - positive is horizontal
            float ratio = Mathf.Clamp(settings.anamorphicRatio, -1, 1);
            float rw = ratio < 0 ? -ratio : 0f;
            float rh = ratio > 0 ? ratio : 0f;

            // Do bloom on a half-res buffer, full-res doesn't bring much and kills performances on
            // fillrate limited platforms
            int tw = Mathf.FloorToInt(context.screenWidth / (2f - rw));
            int th = Mathf.FloorToInt(context.screenHeight / (2f - rh));
            bool singlePassDoubleWide = (context.stereoActive && (context.stereoRenderingMode == PostProcessRenderContext.StereoRenderingMode.SinglePass) && (context.camera.stereoTargetEye == StereoTargetEyeMask.Both));
            int tw_stereo = singlePassDoubleWide ? tw * 2 : tw;


            //float intensity = RuntimeUtilities.Exp2(settings.intensity.value / 10f) - 1f;
            float intensity = settings.intensity.value;
            // 初始化参数
            sheet.properties.SetFloat(ShaderIDs._Bloom_Intensity, intensity);
            sheet.properties.SetFloat(ShaderIDs._Blur_Size, settings.blurSize.value);
            sheet.properties.SetFloat(ShaderIDs._Bloom_Up_Scale, settings.bloomUpScale.value);

            // 直接设置
            const int iterations = 5;

            // Downsample
            var lastDown = context.source;
            for (int i = 0; i < iterations; i++)
            {
                int mipDown = m_Pyramid[i].down;
                int mipUp = m_Pyramid[i].up;
                int pass = i == 0 ? (int)Pass.Prefilter : (int)Pass.Downsample;

                context.GetScreenSpaceTemporaryRT(cmd, mipDown, 0, context.sourceFormat, RenderTextureReadWrite.Default, FilterMode.Bilinear, tw_stereo, th);
                context.GetScreenSpaceTemporaryRT(cmd, mipUp, 0, context.sourceFormat, RenderTextureReadWrite.Default, FilterMode.Bilinear, tw_stereo, th);
                cmd.BlitFullscreenTriangle(lastDown, mipDown, sheet, pass);

                lastDown = mipDown;
                tw_stereo = (singlePassDoubleWide && ((tw_stereo / 2) % 2 > 0)) ? 1 + tw_stereo / 2 : tw_stereo / 2;
                tw_stereo = Mathf.Max(tw_stereo, 1);
                th = Mathf.Max(th / 2, 1);
            }

            // Upsample
            int lastUp = m_Pyramid[iterations - 1].down;
            for (int i = iterations - 2; i >= 0; i--)
            {
                int mipDown = m_Pyramid[i].down;
                int mipUp = m_Pyramid[i].up;
                cmd.SetGlobalTexture(ShaderIDs.BloomTex, mipDown);
                cmd.BlitFullscreenTriangle(lastUp, mipUp, sheet, (int)Pass.Upsample);
                lastUp = mipUp;
            }

            cmd.SetGlobalTexture(ShaderIDs.BloomTex, lastUp);
            cmd.BlitFullscreenTriangle(context.source, context.destination, sheet, (int)Pass.Last);

            // Cleanup
            for (int i = 0; i < iterations; i++)
            {
                cmd.ReleaseTemporaryRT(m_Pyramid[i].down);
                cmd.ReleaseTemporaryRT(m_Pyramid[i].up);
            }

            cmd.EndSample("PAJBloomPyramid");
        }
    }
}

