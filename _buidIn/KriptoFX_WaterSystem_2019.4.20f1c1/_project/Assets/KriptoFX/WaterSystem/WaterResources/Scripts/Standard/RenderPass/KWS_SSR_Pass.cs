using UnityEngine;
using UnityEngine.Rendering;

namespace KWS
{
    public class KWS_SSR_Pass
    {
        public bool IsInitialized;
        bool                isCanUpdate;
        KWS_SSR_CommandPass pass = new KWS_SSR_CommandPass();
        CommandBuffer       cmd;
        CameraEvent camEvent = CameraEvent.BeforeForwardAlpha;

        public void Execute(Camera cam, WaterSystem water)
        {
            if (cmd == null) cmd = new CommandBuffer() {name = "Water.SSR_Pass"};
            cmd.Clear();

            IsInitialized = true;
            pass.Initialize(water, cam.actualRenderingPath == RenderingPath.Forward ? BuiltinRenderTextureType.Depth : BuiltinRenderTextureType.ResolvedDepth);
            KWS_SPR_CoreUtils.SetRenderTarget(cmd, pass.GetTargetColorBuffer());
            pass.Execute(cam, cmd);

            cam.AddCommandBuffer(camEvent, cmd);
        }

        public void FrameCleanup(Camera cam)
        {
            if (cmd != null)
            {
                cam.RemoveCommandBuffer(camEvent, cmd);
            }
        }

        public void Release()
        {
            pass.Release();
            IsInitialized = false;
        }
    }
}