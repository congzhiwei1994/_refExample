using UnityEngine;
using UnityEngine.Rendering;
using static KWS.KWS_CoreUtils;

namespace KWS
{
    public class KW_PyramidBlur
    {
        private string BlurShaderName = "Hidden/KriptoFX/KWS/BlurGaussian";
        const int kMaxIterations = 8;
        Material _blurMaterial;

        public void Release()
        {
            KW_Extensions.SafeDestroy(_blurMaterial);
        }
       
        private readonly int _sampleScale = Shader.PropertyToID("_SampleScale");

        public void ComputeBlurPyramid(float blurRadius, KWS_RTHandle source, KWS_RTHandle target, CommandBuffer cmd)
        {
            var tempBuffersDown = new RenderTexture[kMaxIterations];
            var tempBuffersUp = new RenderTexture[kMaxIterations];

            if (_blurMaterial == null) _blurMaterial = CreateMaterial(BlurShaderName);

            var targetRT = target.rt;
            RenderTexture last = null;

            int cw = source.rt.width;
            int ch = source.rt.height;
            int tw = target.rt.width;
            int th = target.rt.height;

            Debug.Assert(cw == tw && ch == th);

            //if (target.useScaling)
            //{

            //    cmd.SetViewport(new Rect(0.0f, 0.0f, scaledViewportSize.x, scaledViewportSize.y));
            //}
            var scaledViewportSize = source.GetScaledSize(source.rtHandleProperties.currentViewportSize);
            var logh = Mathf.Log(Mathf.Max(scaledViewportSize.x, scaledViewportSize.y), 2) + blurRadius - 8;
            var logh_i = (int)logh;
            var iterations = Mathf.Clamp(logh_i, 2, kMaxIterations);

            cmd.SetGlobalFloat(_sampleScale, 0.5f + logh - logh_i);

            var lastWidth = scaledViewportSize.x;
            var lastHeight = scaledViewportSize.y;

            for (var level = 0; level < iterations; level++)
            {
                tempBuffersDown[level] = RenderTexture.GetTemporary(lastWidth, lastHeight, targetRT.depth, targetRT.format);
                var downPassTarget = iterations == 1 ? target : tempBuffersDown[level];

                var sourceRTHandleScale = level == 0 ? source.rtHandleProperties.rtHandleScale : Vector4.one;
                cmd.BlitTriangle(level == 0 ? source.rt : last, sourceRTHandleScale, downPassTarget, _blurMaterial);

                lastWidth = lastWidth / 2;
                lastHeight = lastHeight / 2;
                last = tempBuffersDown[level];
            }

            for (var level = iterations - 2; level >= 0; level--)
            {
                tempBuffersUp[level] = RenderTexture.GetTemporary(tempBuffersDown[level].width, tempBuffersDown[level].height, 0, targetRT.format);

                if (level != 0)
                {
                    cmd.BlitTriangle(last, tempBuffersUp[level], _blurMaterial, 1);
                    last = tempBuffersUp[level];
                }
                else
                {
                    cmd.BlitTriangleRTHandle(last, Vector4.one, target, _blurMaterial, KWS.ClearFlag.None, Color.clear, 1);
                }
            }
            foreach (var temp in tempBuffersDown) if (temp != null) RenderTexture.ReleaseTemporary(temp);
            foreach (var temp in tempBuffersUp) if (temp != null) RenderTexture.ReleaseTemporary(temp);
        }
    }
}