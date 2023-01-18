using UnityEngine;
using UnityEngine.Rendering;

namespace KWS
{
    public class KWS_Underwater_Pass
    {
        public bool IsInitialized;

        KWS_Underwater_CommandPass pass = new KWS_Underwater_CommandPass();
        CommandBuffer              cmd;
        CameraEvent                camEvent = CameraEvent.AfterForwardAlpha;

        public void Execute(Camera cam, WaterSystem water)
        {
            if (cmd == null) cmd = new CommandBuffer() {name = "Water.Underwater_Pass"};
            cmd.Clear();

            if (!IsUnderwaterVisible(cam, water.WorldSpaceBounds)) return;
            
            IsInitialized = true;
            pass.Initialize(water);
            pass.SetColorBuffer(BuiltinRenderTextureType.CameraTarget);
            KWS_SPR_CoreUtils.SetRenderTarget(cmd, pass.GetTargetColorBuffer());
            pass.Execute(cam, cmd, water);

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

        private Vector4[] nearPlane = new Vector4[4];

        bool IsUnderwaterVisible(Camera cam, Bounds waterBounds)
        {
            nearPlane[0] = cam.ViewportToWorldPoint(new Vector3(0, 0, cam.nearClipPlane));
            nearPlane[1] = cam.ViewportToWorldPoint(new Vector3(1, 0, cam.nearClipPlane));
            nearPlane[2] = cam.ViewportToWorldPoint(new Vector3(0, 1, cam.nearClipPlane));
            nearPlane[3] = cam.ViewportToWorldPoint(new Vector3(1, 1, cam.nearClipPlane));

            if (IsPointInsideAABB(nearPlane[0], waterBounds)
                || IsPointInsideAABB(nearPlane[1], waterBounds)
                || IsPointInsideAABB(nearPlane[2], waterBounds)
                || IsPointInsideAABB(nearPlane[3], waterBounds))
            {
                return true;
            }
            else
            {
                return false;
            }
        }

        bool IsPointInsideAABB(Vector3 point, Bounds box)
        {
            return (point.x >= box.min.x && point.x <= box.max.x) &&
                   (point.y >= box.min.y && point.y <= box.max.y) &&
                   (point.z >= box.min.z && point.z <= box.max.z);
        }
    }
}