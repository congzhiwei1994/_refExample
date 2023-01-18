using UnityEngine;
using UnityEngine.Rendering;

namespace KWS
{
    public class KWS_MaskDepthNormal_Pass
    {
        public bool IsInitialized;
        KWS_MaskDepthNormal_CommandPass pass = new KWS_MaskDepthNormal_CommandPass();
        CommandBuffer                   cmd;
        CameraEvent                     camEvent = CameraEvent.BeforeForwardAlpha;

        public void Execute(Camera cam, WaterSystem water)
        {
            if (cmd == null) cmd = new CommandBuffer() {name = "Water.MaskDepthNormal_Pass"};
            cmd.Clear();

            IsInitialized = true;
            pass.Initialize(water);
            KWS_SPR_CoreUtils.SetRenderTarget(cmd, pass.GetTargetColorBuffer(), pass.GetTargetDepthBuffer());
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