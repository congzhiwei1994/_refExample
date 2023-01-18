using UnityEngine;

namespace KWS
{
    [ExecuteAlways]
    public class KWS_WaterPassHandler : MonoBehaviour
    {
        public WaterSystem WaterInstance;
        bool isCanUpdate;

        KWS_MaskDepthNormal_Pass            maskDepthNormal_Pass    = new KWS_MaskDepthNormal_Pass();
        KWS_CopyColor_Pass                  copyColor_Pass          = new KWS_CopyColor_Pass();
        KWS_VolumetricLighting_Pass         volumetricLighting_Pass = new KWS_VolumetricLighting_Pass();
        KWS_SSR_Pass                        ssr_Pass                = new KWS_SSR_Pass();
        KWS_Caustic_Pass                    caustic_Pass            = new KWS_Caustic_Pass();
        KWS_Underwater_Pass                 underwater_Pass         = new KWS_Underwater_Pass();
        private KWS_DrawToDepth_Pass        drawToDepth_Pass        = new KWS_DrawToDepth_Pass();

        public void MyPreCull(Camera cam)
        {
            if (!isCanUpdate) return;
            if (!KWS_CoreUtils.CanRenderWaterForCurrentCamera(cam)) return;

            if (!WaterInstance.IsWaterVisible) return;

            var cameraSize = KWS_CoreUtils.GetCameraScreenSizeLimited(cam);
            KWS_RTHandles.SetReferenceSize(cameraSize.x, cameraSize.y, MSAASamples.None);

            if (WaterInstance.UseVolumetricLight || WaterInstance.UseCausticEffect || WaterInstance.UseUnderwaterEffect) maskDepthNormal_Pass.Execute(cam, WaterInstance);
            if (WaterInstance.UseCausticEffect) caustic_Pass.Execute(cam, WaterInstance);
            if (WaterInstance.UseVolumetricLight) volumetricLighting_Pass.Execute(cam, WaterInstance);
            copyColor_Pass.Execute(cam, WaterInstance);
            if (WaterInstance.ReflectionMode == WaterSystem.ReflectionModeEnum.ScreenSpaceReflection) ssr_Pass.Execute(cam, WaterInstance);
            if (WaterInstance.UseUnderwaterEffect) underwater_Pass.Execute(cam, WaterInstance);
            if (WaterInstance.DrawToPosteffectsDepth) drawToDepth_Pass.Execute(cam, WaterInstance);

        }

        public void MyPostRender(Camera cam)
        {
            if (!isCanUpdate) return;
            if (!KWS_CoreUtils.CanRenderWaterForCurrentCamera(cam)) return;

            if (WaterInstance.UseVolumetricLight || WaterInstance.UseCausticEffect || WaterInstance.UseUnderwaterEffect) maskDepthNormal_Pass.FrameCleanup(cam);
            else if (maskDepthNormal_Pass.IsInitialized) maskDepthNormal_Pass.Release();

            if (WaterInstance.UseCausticEffect) caustic_Pass.FrameCleanup(cam);
            else if (caustic_Pass.IsInitialized) caustic_Pass.Release();

            if (WaterInstance.UseVolumetricLight) volumetricLighting_Pass.FrameCleanup(cam);
            else if (volumetricLighting_Pass.IsInitialized) volumetricLighting_Pass.Release();

            copyColor_Pass.FrameCleanup(cam);

            if (WaterInstance.ReflectionMode == WaterSystem.ReflectionModeEnum.ScreenSpaceReflection) ssr_Pass.FrameCleanup(cam);
            else if (ssr_Pass.IsInitialized) ssr_Pass.Release();

            if (WaterInstance.UseUnderwaterEffect) underwater_Pass.FrameCleanup(cam);
            else if (underwater_Pass.IsInitialized) underwater_Pass.Release();

            if (WaterInstance.DrawToPosteffectsDepth) drawToDepth_Pass.FrameCleanup(cam);
            else if (drawToDepth_Pass.IsInitialized) drawToDepth_Pass.Release();
        }


        private void OnEnable()
        {
            Camera.onPreCull += MyPreCull;
            Camera.onPostRender += MyPostRender;
            isCanUpdate = true;
        }

        void OnDisable()
        {
            Camera.onPreCull -= MyPreCull;
            Camera.onPostRender -= MyPostRender;
            isCanUpdate = false;

            maskDepthNormal_Pass.Release();
            volumetricLighting_Pass.Release();
            caustic_Pass.Release();
            copyColor_Pass.Release();
            ssr_Pass.Release();
            underwater_Pass.Release();
            drawToDepth_Pass.Release();
        }


    }
}
