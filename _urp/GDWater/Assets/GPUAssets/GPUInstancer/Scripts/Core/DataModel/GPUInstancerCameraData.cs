using System;
using UnityEngine;

namespace GPUInstancer
{
    [Serializable]
    public class GPUInstancerCameraData
    {
        public Camera mainCamera;
        public GPUInstancerHiZOcclusionGenerator hiZOcclusionGenerator;
        public float[] mvpMatrixFloats;
        public float[] mvpMatrix2Floats;
        public Vector3 cameraPosition = Vector3.zero;
        public bool hasOcclusionGenerator = false;
        public float halfAngle;
        public bool renderOnlySelectedCamera = false;

        public GPUInstancerCameraData() : this(null) { }

        public GPUInstancerCameraData(Camera mainCamera)
        {
            this.mainCamera = mainCamera;
            mvpMatrixFloats = new float[16];
            CalculateHalfAngle();
        }

        public void SetCamera(Camera mainCamera)
        {
            this.mainCamera = mainCamera;
            CalculateHalfAngle();
        }

        public void CalculateCameraData()
        {
            hasOcclusionGenerator = hiZOcclusionGenerator != null && hiZOcclusionGenerator.hiZDepthTexture != null;

            Matrix4x4 mvpMatrix =
                (hasOcclusionGenerator && hiZOcclusionGenerator.isVREnabled
                ? mainCamera.GetStereoProjectionMatrix(Camera.StereoscopicEye.Left) : mainCamera.projectionMatrix) * mainCamera.worldToCameraMatrix;

            if (mvpMatrixFloats == null || mvpMatrixFloats.Length != 16)
                mvpMatrixFloats = new float[16];
            mvpMatrix.Matrix4x4ToFloatArray(mvpMatrixFloats);

            if (hasOcclusionGenerator && hiZOcclusionGenerator.isVREnabled && GPUInstancerConstants.gpuiSettings.testBothEyesForVROcclusion)
            {
                Matrix4x4 mvpMatrix2 = mainCamera.GetStereoProjectionMatrix(Camera.StereoscopicEye.Right) * mainCamera.worldToCameraMatrix;
                if (mvpMatrix2Floats == null || mvpMatrix2Floats.Length != 16)
                    mvpMatrix2Floats = new float[16];
                mvpMatrix2.Matrix4x4ToFloatArray(mvpMatrix2Floats);
            }

            cameraPosition = mainCamera.transform.position;
        }

        public void CalculateHalfAngle()
        {
            if (mainCamera != null)
                halfAngle = Mathf.Tan(Mathf.Deg2Rad * mainCamera.fieldOfView * 0.25f);
        }

        public Camera GetRenderingCamera()
        {
            if (renderOnlySelectedCamera)
                return mainCamera;
            return null;
        }
    }
}