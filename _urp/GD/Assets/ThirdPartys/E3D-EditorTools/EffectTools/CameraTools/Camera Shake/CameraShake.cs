//
// Copyright 2012 Thinksquirrel Software, LLC. All rights reserved.
//
using UnityEngine;
using System.Collections;
using System.Collections.Generic;

[AddComponentMenu("Utilities/Camera Shake")]

    public class CameraShake : MonoBehaviour
    {
        /// <summary>
                                        		/// The cameras to shake.
                                        		/// </summary>
        public List<Camera> cameras = new List<Camera>();
        /// <summary>
                                        		/// The maximum number of shakes to perform.
                                        		/// </summary>
        public int numberOfShakes = 2;
        /// <summary>
                                        		/// The amount to shake in each direction.
                                        		/// </summary>
        public Vector3 shakeAmount = Vector3.one;
        /// <summary>
                                        		/// The amount to rotate in each direction.
                                        		/// </summary>
        public Vector3 rotationAmount = Vector3.one;
        /// <summary>
                                        		/// The initial distance for the first shake.
                                        		/// </summary>
        public float distance = 00.10f;
        /// <summary>
                                        		/// The speed multiplier for the shake.
                                        		/// </summary>
        public float speed = 50.00f;
        /// <summary>
                                        		/// The decay speed (between 0 and 1). Higher values will stop shaking sooner.
                                        		/// </summary>
        public float decay = 00.20f;
        /// <summary>
                                        		/// The modifier applied to speed in order to shake the GUI.
                                        		/// </summary>
        public float guiShakeModifier = 01.00f;
        /// <summary>
                                        		/// If true, multiplies the final shake speed by the time scale.
                                        		/// </summary>
        public bool multiplyByTimeScale = true;
        // Shake rect (for GUI)
        private Rect shakeRect;
        // States
        private bool shaking = false;
        private bool cancelling = false;
        internal class ShakeState
        {
            internal readonly Vector3 startPosition;
            internal readonly Quaternion startRotation;
            internal readonly Vector2 guiStartPosition;
            internal Vector3 shakePosition;
            internal Quaternion shakeRotation;
            internal Vector2 guiShakePosition;
            internal ShakeState(Vector3 position, Quaternion rotation, Vector2 guiPosition)
            {
                startPosition = position;
                startRotation = rotation;
                guiStartPosition = guiPosition;
                shakePosition = position;
                shakeRotation = rotation;
                guiShakePosition = guiPosition;
            }
        }

        private Dictionary<Camera, List<ShakeState>> states = new Dictionary<Camera, List<ShakeState>>();
        private Dictionary<Camera, int> shakeCount = new Dictionary<Camera, int>();
        // Minimum shake values
        private const bool checkForMinimumValues = true;
        private const float minShakeValue = 0.001f;
        private const float minRotationValue = 0.001f;
#region Singleton

        /// <summary>
                                        		/// The Camera Shake singleton instance.
                                        		/// </summary>
        public static CameraShake instance;
        void Awake()
        {
            instance = this;
        }

        void OnDestroy()
        {
            instance = null;
        }

        private void OnEnable()
        {
            if (cameras.Count < 1)
            {
				var			camera = GetComponent<Camera>();

                if (camera)
                    cameras.Add(camera);
            }

            if (cameras.Count < 1)
            {
                if (Camera.main)
                    cameras.Add(Camera.main);
            }

            if (cameras.Count < 1)
            {
                Debug.LogError("Camera Shake: No cameras assigned in the inspector!");
            }

        }

#endregion
#region Static properties
        public static bool isShaking
        {
            get
            {
                return instance != null ? instance.IsShaking() : false;
            }
        }

        public static bool isCancelling
        {
            get
            {
                return instance != null ? instance.IsCancelling() : false;
            }
        }

#endregion
#region Static methods
        public static void Shake()
        {
            instance.DoShake();
        }

        public static void Shake(int numberOfShakes, Vector3 shakeAmount, Vector3 rotationAmount, float distance, float speed, float decay, float guiShakeModifier, bool multiplyByTimeScale)
        {
            instance.DoShake(numberOfShakes, shakeAmount, rotationAmount, distance, speed, decay, guiShakeModifier, multiplyByTimeScale);
        }

        public static void Shake(System.Action callback)
        {
            instance.DoShake(callback);
        }

        public static void Shake(int numberOfShakes, Vector3 shakeAmount, Vector3 rotationAmount, float distance, float speed, float decay, float guiShakeModifier, bool multiplyByTimeScale, System.Action callback)
        {
            instance.DoShake(numberOfShakes, shakeAmount, rotationAmount, distance, speed, decay, guiShakeModifier, multiplyByTimeScale, callback);
        }

        public static void CancelShake()
        {
            instance.DoCancelShake();
        }

        public static void CancelShake(float time)
        {
            instance.DoCancelShake(time);
        }

        public static void BeginShakeGUI()
        {
            instance.DoBeginShakeGUI();
        }

        public static void EndShakeGUI()
        {
            instance.DoEndShakeGUI();
        }

        public static void BeginShakeGUILayout()
        {
            instance.DoBeginShakeGUILayout();
        }

        public static void EndShakeGUILayout()
        {
            instance.DoEndShakeGUILayout();
        }

#endregion
#region Events

        /// <summary>
                                        		/// Occurs when a camera starts shaking.
                                        		/// </summary>
        public event System.Action cameraShakeStarted;
        /// <summary>
                                        		/// Occurs when a camera has completely stopped shaking and has been reset to its original position.
                                        		/// </summary>
        public event System.Action allCameraShakesCompleted;
        public event System.Action<Camera, Vector3, Quaternion> cameraShake;
#endregion
#region Public methods
        public bool IsShaking()
        {
            return shaking;
        }

        public bool IsCancelling()
        {
            return cancelling;
        }

        public void DoShake()
        {
            Vector3 seed = Random.insideUnitSphere;
            foreach (Camera cam in cameras)
            {
                StartCoroutine(DoShake_Internal(cam, seed, this.numberOfShakes, this.shakeAmount, this.rotationAmount, this.distance, this.speed, this.decay, this.guiShakeModifier, this.multiplyByTimeScale, null));
            }
        }

        public void DoShake(int numberOfShakes, Vector3 shakeAmount, Vector3 rotationAmount, float distance, float speed, float decay, float guiShakeModifier, bool multiplyByTimeScale)
        {
            Vector3 seed = Random.insideUnitSphere;
            foreach (Camera cam in cameras)
            {
                StartCoroutine(DoShake_Internal(cam, seed, numberOfShakes, shakeAmount, rotationAmount, distance, speed, decay, guiShakeModifier, multiplyByTimeScale, null));
            }
        }

        public void DoShake(System.Action callback)
        {
            Vector3 seed = Random.insideUnitSphere;
            foreach (Camera cam in cameras)
            {
                StartCoroutine(DoShake_Internal(cam, seed, this.numberOfShakes, this.shakeAmount, this.rotationAmount, this.distance, this.speed, this.decay, this.guiShakeModifier, this.multiplyByTimeScale, callback));
            }
        }

        public void DoShake(int numberOfShakes, Vector3 shakeAmount, Vector3 rotationAmount, float distance, float speed, float decay, float guiShakeModifier, bool multiplyByTimeScale, System.Action callback)
        {
            Vector3 seed = Random.insideUnitSphere;
            foreach (Camera cam in cameras)
            {
                StartCoroutine(DoShake_Internal(cam, seed, numberOfShakes, shakeAmount, rotationAmount, distance, speed, decay, guiShakeModifier, multiplyByTimeScale, callback));
            }
        }

        public void DoCancelShake()
        {
            if (shaking && !cancelling)
            {
                shaking = false;
                this.StopAllCoroutines();
                foreach (Camera cam in cameras)
                {
                    if (shakeCount.ContainsKey(cam))
                    {
                        shakeCount[cam] = 0;
                    }

                    ResetState(cam.transform, cam);
                }
            }
        }

        public void DoCancelShake(float time)
        {
            if (shaking && !cancelling)
            {
                this.StopAllCoroutines();
                this.StartCoroutine(DoResetState(cameras, shakeCount, time));
            }
        }

        public void DoBeginShakeGUI()
        {
            CheckShakeRect();
            GUI.BeginGroup(shakeRect);
        }

        public void DoEndShakeGUI()
        {
            GUI.EndGroup();
        }

        public void DoBeginShakeGUILayout()
        {
            CheckShakeRect();
            GUILayout.BeginArea(shakeRect);
        }

        public void DoEndShakeGUILayout()
        {
            GUILayout.EndArea();
        }

#endregion
#region Private methods
        private IEnumerator DoShake_Internal(Camera cam, Vector3 seed, int numberOfShakes, Vector3 shakeAmount, Vector3 rotationAmount, float distance, float speed, float decay, float guiShakeModifier, bool multiplyByTimeScale, System.Action callback)
        {
            // Wait for async cancel operations to complete
            if (cancelling)
                yield return null;
            // Set random values
            var mod1 = seed.x > .5f ? 1 : -1;
            var mod2 = seed.y > .5f ? 1 : -1;
            var mod3 = seed.z > .5f ? 1 : -1;
            // First shake
            if (!shaking)
            {
                shaking = true;
                if (cameraShakeStarted != null)
                    cameraShakeStarted();
            }

            if (shakeCount.ContainsKey(cam))
                shakeCount[cam]++;
            else
                shakeCount.Add(cam, 1);
            // Pixel width is always based on the first camera
            float pixelWidth = GetPixelWidth(cameras[0].transform, cameras[0]);
            // Set other values
            Transform cachedTransform = cam.transform;
            Vector3 camOffset = Vector3.zero;
            Quaternion camRot = Quaternion.identity;
            int currentShakes = numberOfShakes;
            float shakeDistance = distance;
            float rotationStrength = 1;
            float startTime = Time.time;
            float scale = multiplyByTimeScale ? Time.timeScale : 1;
            float pixelScale = pixelWidth * guiShakeModifier * scale;
            Vector3 start1 = Vector2.zero;
            Quaternion startR = Quaternion.identity;
            Vector2 start2 = Vector2.zero;
            ShakeState state = new ShakeState(cachedTransform.position, cachedTransform.rotation, new Vector2(shakeRect.x, shakeRect.y));
            List<ShakeState> stateList;
            if (states.TryGetValue(cam, out stateList))
            {
                stateList.Add(state);
            }
            else
            {
                stateList = new List<ShakeState>();
                stateList.Add(state);
                states.Add(cam, stateList);
            }

            // Main loop
            while (currentShakes > 0)
            {
                if (checkForMinimumValues)
                {
                    // Early break when rotation is less than the minimum value.
                    if (rotationAmount.sqrMagnitude != 0 && rotationStrength <= minRotationValue)
                        break;
                    // Early break when shake amount is less than the minimum value.
                    if (shakeAmount.sqrMagnitude != 0 && distance != 0 && shakeDistance <= minShakeValue)
                        break;
                }

                var timer = (Time.time - startTime) * speed;
                state.shakePosition = start1 + new Vector3(mod1 * Mathf.Sin(timer) * (shakeAmount.x * shakeDistance * scale), mod2 * Mathf.Cos(timer) * (shakeAmount.y * shakeDistance * scale), mod3 * Mathf.Sin(timer) * (shakeAmount.z * shakeDistance * scale));
                state.shakeRotation = startR * Quaternion.Euler(mod1 * Mathf.Cos(timer) * (rotationAmount.x * rotationStrength * scale), mod2 * Mathf.Sin(timer) * (rotationAmount.y * rotationStrength * scale), mod3 * Mathf.Cos(timer) * (rotationAmount.z * rotationStrength * scale));
                state.guiShakePosition = new Vector2(start2.x - (mod1 * Mathf.Sin(timer) * (shakeAmount.x * shakeDistance * pixelScale)), start2.y - (mod2 * Mathf.Cos(timer) * (shakeAmount.y * shakeDistance * pixelScale)));
                camOffset = GetGeometricAvg(stateList, true);
                camRot = GetAvgRotation(stateList);
                NormalizeQuaternion(ref camRot);
                Matrix4x4 m = Matrix4x4.TRS(camOffset, camRot, new Vector3(1, 1, -1));
                cam.worldToCameraMatrix = m * cachedTransform.worldToLocalMatrix;
                var avg = GetGeometricAvg(stateList, false);
                shakeRect.x = avg.x;
                shakeRect.y = avg.y;
                if (timer > Mathf.PI * 2)
                {
                    startTime = Time.time;
                    shakeDistance *= (1 - Mathf.Clamp01(decay));
                    rotationStrength *= (1 - Mathf.Clamp01(decay));
                    currentShakes--;
                }

                if (cameraShake != null)
                    cameraShake(cam, camOffset, camRot);
                yield return null;
            }

            // End conditions
            shakeCount[cam]--;
            // Last shake
            if (shakeCount[cam] == 0)
            {
                shaking = false;
                ResetState(cam.transform, cam);
                if (allCameraShakesCompleted != null)
                {
                    allCameraShakesCompleted();
                }
            }
            else
            {
                stateList.Remove(state);
            }

            if (callback != null)
                callback();
        }

        private Vector3 GetGeometricAvg(List<ShakeState> states, bool position)
        {
            float x = 0, y = 0, z = 0, l = states.Count;
            foreach (ShakeState state in states)
            {
                if (position)
                {
                    x -= state.shakePosition.x;
                    y -= state.shakePosition.y;
                    z -= state.shakePosition.z;
                }
                else
                {
                    x += state.guiShakePosition.x;
                    y += state.guiShakePosition.y;
                }
            }

            return new Vector3(x / l, y / l, z / l);
        }

        private Quaternion GetAvgRotation(List<ShakeState> states)
        {
            Quaternion avg = new Quaternion(0, 0, 0, 0);
            foreach (ShakeState state in states)
            {
                if (Quaternion.Dot(state.shakeRotation, avg) > 0)
                {
                    avg.x += state.shakeRotation.x;
                    avg.y += state.shakeRotation.y;
                    avg.z += state.shakeRotation.z;
                    avg.w += state.shakeRotation.w;
                }
                else
                {
                    avg.x += -state.shakeRotation.x;
                    avg.y += -state.shakeRotation.y;
                    avg.z += -state.shakeRotation.z;
                    avg.w += -state.shakeRotation.w;
                }
            }

            var mag = Mathf.Sqrt(avg.x * avg.x + avg.y * avg.y + avg.z * avg.z + avg.w * avg.w);
            if (mag > 0.0001f)
            {
                avg.x /= mag;
                avg.y /= mag;
                avg.z /= mag;
                avg.w /= mag;
            }
            else
            {
                avg = states[0].shakeRotation;
            }

            return avg;
        }

        private void CheckShakeRect()
        {
            if (Screen.width != shakeRect.width || Screen.height != shakeRect.height)
            {
                shakeRect.width = Screen.width;
                shakeRect.height = Screen.height;
            }
        }

        private float GetPixelWidth(Transform cachedTransform, Camera cachedCamera)
        {
            var position = cachedTransform.position;
            var screenPos = cachedCamera.WorldToScreenPoint(position - cachedTransform.forward * .01f);
            var offset = Vector3.zero;
            if (screenPos.x > 0)
                offset = screenPos - Vector3.right;
            else
                offset = screenPos + Vector3.right;
            if (screenPos.y > 0)
                offset = screenPos - Vector3.up;
            else
                offset = screenPos + Vector3.up;
            offset = cachedCamera.ScreenToWorldPoint(offset);
            return 1f / (cachedTransform.InverseTransformPoint(position) - cachedTransform.InverseTransformPoint(offset)).magnitude;
        }

        private void ResetState(Transform cachedTransform, Camera cam)
        {
            cam.ResetWorldToCameraMatrix();
            shakeRect.x = 0;
            shakeRect.y = 0;
            states[cam].Clear();
        }

        private List<Vector3> offsetCache = new List<Vector3>(10);
        private List<Quaternion> rotationCache = new List<Quaternion>(10);
        private IEnumerator DoResetState(List<Camera> cameras, Dictionary<Camera, int> shakeCount, float time)
        {
            offsetCache.Clear();
            rotationCache.Clear();
            foreach (Camera cam in cameras)
            {
                offsetCache.Add((Vector3)((cam.worldToCameraMatrix * cam.transform.worldToLocalMatrix.inverse).GetColumn(3)));
                rotationCache.Add(QuaternionFromMatrix((cam.worldToCameraMatrix * cam.transform.worldToLocalMatrix.inverse).inverse * Matrix4x4.TRS(Vector3.zero, Quaternion.identity, new Vector3(1, 1, -1))));
                if (shakeCount.ContainsKey(cam))
                {
                    shakeCount[cam] = 0;
                }

                states[cam].Clear();
            }

			var camera = GetComponent<Camera>();
            float t = 0;
            float x = shakeRect.x, y = shakeRect.y;
            cancelling = true;
            while (t < time)
            {
                int i = 0;
                foreach (Camera cam in cameras)
                {
                    Transform cachedTransform = cam.transform;
                    shakeRect.x = Mathf.Lerp(x, 0, t / time);
                    shakeRect.y = Mathf.Lerp(y, 0, t / time);
                    Vector3 pos = Vector3.Lerp(offsetCache[i], Vector3.zero, t / time);
                    Quaternion rot = Quaternion.Slerp(rotationCache[i], cachedTransform.rotation, t / time);
                    Matrix4x4 m = Matrix4x4.TRS(pos, rot, new Vector3(1, 1, -1));
                    cam.worldToCameraMatrix = m * cachedTransform.worldToLocalMatrix;
                    i++;
                    if (cameraShake != null)
                        cameraShake(camera, pos, rot);
                }

                t += Time.deltaTime;
                yield return null;
            }

            foreach (Camera cam in cameras)
            {
                cam.ResetWorldToCameraMatrix();
                shakeRect.x = 0;
                shakeRect.y = 0;
            }

            this.shaking = false;
            this.cancelling = false;
        }

#endregion
#region Quaternion helpers
        private static Quaternion QuaternionFromMatrix(Matrix4x4 m)
        {
            return Quaternion.LookRotation(m.GetColumn(2), m.GetColumn(1));
        }

        private static void NormalizeQuaternion(ref Quaternion q)
        {
            float sum = 0;
            for (int i = 0; i < 4; ++i)
                sum += q[i] * q[i];
            float magnitudeInverse = 1 / Mathf.Sqrt(sum);
            for (int i = 0; i < 4; ++i)
                q[i] *= magnitudeInverse;
        }
#endregion
    }
