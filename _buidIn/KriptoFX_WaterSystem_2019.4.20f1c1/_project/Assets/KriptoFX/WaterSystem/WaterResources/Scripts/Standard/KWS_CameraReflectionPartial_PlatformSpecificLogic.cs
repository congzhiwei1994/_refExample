using UnityEngine;

namespace KWS
{
    public partial class KWS_CameraReflection
    {
        void SubscribeBeforeCameraRendering()
        {
            Camera.onPreCull += OnBeforeCameraRendering;
        }

        void UnsubscribeBeforeCameraRendering()
        {
            Camera.onPreCull -= OnBeforeCameraRendering;
        }

        void SubscribeAfterCameraRendering()
        {
            Camera.onPostRender += OnAfterCameraRendering;
        }

        void UnsubscribeAfterCameraRendering()
        {
            Camera.onPostRender -= OnAfterCameraRendering;
        }

        void InitializeCameraParamsSRP()
        {

        }

        void CopyCameraParamsSRP(Camera currentCamera, int cullingMask, bool invertFaceCulling)
        {

        }

        void CameraRender(Camera cam)
        {
            cam.Render();
        }
    }
}
