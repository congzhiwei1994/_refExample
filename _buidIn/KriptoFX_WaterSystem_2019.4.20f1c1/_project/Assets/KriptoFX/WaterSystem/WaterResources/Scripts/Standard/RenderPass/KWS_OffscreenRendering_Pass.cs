using UnityEngine;
using UnityEngine.Rendering;

namespace KWS
{
    public class KWS_OffscreenRendering_Pass
    {
        //public bool IsInitialized;
        //KWS_OffscreenRendering_CommandPass pass = new KWS_OffscreenRendering_CommandPass();
        //CommandBuffer                      cmd;
        //CameraEvent                        camEvent = CameraEvent.BeforeForwardAlpha;

        //public void Execute(Camera cam, WaterSystem water)
        //{
        //    if (cmd == null) cmd = new CommandBuffer() {name = "Water.OffscreenRendering_Pass"};
        //    cmd.Clear();

        //    IsInitialized = true;
        //    pass.Initialize(water);
        //    pass.SetColorBuffer(BuiltinRenderTextureType.CameraTarget);
        //    KWS_SPR_CoreUtils.SetRenderTarget(cmd, pass.GetTargetColorTexture());
        //    pass.Execute(cam, cmd);

        //    KWS_SPR_CoreUtils.SetRenderTarget(cmd, BuiltinRenderTextureType.CameraTarget);
        //    pass.Execute_DrawToCameraBuffer(cam, cmd);

        //    cam.AddCommandBuffer(camEvent, cmd);
        //}

        //public void FrameCleanup(Camera cam)
        //{
        //    if (cmd != null)
        //    {
        //        cam.RemoveCommandBuffer(camEvent, cmd);
        //    }
        //}

        //public void Release()
        //{
        //    pass.Release();
        //    IsInitialized = false;
        //}
    }
}