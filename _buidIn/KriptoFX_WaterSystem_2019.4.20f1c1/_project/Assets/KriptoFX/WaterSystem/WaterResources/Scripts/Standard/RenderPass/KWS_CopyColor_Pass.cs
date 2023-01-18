using UnityEngine;
using UnityEngine.Rendering;

namespace KWS
{
    public class KWS_CopyColor_Pass
    {
        public bool IsInitialized;
        KWS_CopyColor_CommandPass pass = new KWS_CopyColor_CommandPass();
        CommandBuffer             cmd;
        CameraEvent               camEvent = CameraEvent.BeforeForwardAlpha;

        public void Execute(Camera cam, WaterSystem water)
        {
            if (cmd == null) cmd = new CommandBuffer() {name = "Water.CopyColor_Pass"};
            cmd.Clear();

            IsInitialized = true;
            pass.Initialize(water, BuiltinRenderTextureType.CurrentActive);
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