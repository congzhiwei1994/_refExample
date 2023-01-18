using UnityEngine;
using UnityEngine.Rendering;

namespace KWS
{
    public class KWS_DrawToDepth_Pass
    {
        public bool IsInitialized;
        KWS_DrawToDepth_CommandPass pass = new KWS_DrawToDepth_CommandPass();
        CommandBuffer               cmd;
        CameraEvent                 camEvent = CameraEvent.AfterForwardAlpha;

        public void Execute(Camera cam, WaterSystem water)
        {
            if(cmd == null) cmd = new CommandBuffer() { name = "Water.DrawToDepth_Pass" };
            cmd.Clear();

            IsInitialized = true;
            var depthID = (cam.actualRenderingPath == RenderingPath.Forward) ? new RenderTargetIdentifier(BuiltinRenderTextureType.Depth) : new RenderTargetIdentifier(BuiltinRenderTextureType.ResolvedDepth);
            pass.Initialize(water, depthID);
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
