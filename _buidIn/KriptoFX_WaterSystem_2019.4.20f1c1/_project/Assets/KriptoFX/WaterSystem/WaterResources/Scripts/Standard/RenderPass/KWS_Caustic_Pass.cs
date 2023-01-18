using UnityEngine;
using UnityEngine.Rendering;

namespace KWS
{
    public class KWS_Caustic_Pass
    {
        public bool IsInitialized;
        KWS_Caustic_CommandPass pass = new KWS_Caustic_CommandPass();
        CommandBuffer           cmd;
        CameraEvent             camEvent = CameraEvent.BeforeForwardAlpha;

        public void Execute(Camera cam, WaterSystem water)
        {
            if (cmd == null) cmd = new CommandBuffer() {name = "Water.Caustic_Pass"};
            cmd.Clear();

            IsInitialized = true;
            pass.Initialize(water, BuiltinRenderTextureType.CameraTarget);
            KWS_SPR_CoreUtils.SetRenderTarget(cmd, pass.GetTargetColorBuffer());
            pass.Execute(cam, cmd);

            cam.AddCommandBuffer(camEvent, cmd);
        }

        public void FrameCleanup(Camera cam)
        {
            if (cam.cameraType != CameraType.Game && cam.cameraType != CameraType.SceneView) return;

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