using UnityEngine;
using UnityEngine.Experimental.Rendering;
using UnityEngine.Rendering;

namespace KWS
{
    public static partial class KWS_CoreUtils
    {
        static bool CanRenderWaterForCurrentCamera_PlatformSpecific(Camera cam)
        {
            return true;
        }

        public static Vector2 GetCameraRTHandleViewPortSize(Camera cam)
        {
            return new Vector2(cam.pixelRect.width, cam.pixelRect.height);
          
        }
    }
}