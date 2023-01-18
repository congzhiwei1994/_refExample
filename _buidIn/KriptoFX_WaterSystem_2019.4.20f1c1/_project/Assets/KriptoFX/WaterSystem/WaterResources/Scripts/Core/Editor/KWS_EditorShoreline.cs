#if UNITY_EDITOR
using KWS;
using System.Collections.Generic;
using System.Linq;
using UnityEditor;
using UnityEngine;
using Random = UnityEngine.Random;

namespace KWS
{
    public class KWS_EditorShoreline
    {
        const float updateShorelineParamsEverySeconds = 0.1f;

        bool  _isMousePressed            = false;
        int   _nearMouseSelectionWaveIdx = -1;
        bool  _isRequiredUpdateShorelineParams;
        float _currentTimeBeforeShorelineUpdate;

        public async void AddWave(WaterSystem waterSystem, Ray ray, bool interpolateNextPosition)
        {
            var wavesData = await waterSystem.GetShorelineWavesData();
            var waves     = wavesData.ShorelineWaves;
            var newWave = new KW_ShorelineWaves.ShorelineWaveInfo();
            ComputeShorelineNextTransform(newWave, waves, ray, waterSystem.WaterWorldPosition.y, interpolateNextPosition);

            newWave.ID = (waves.Count == 0) ? 0 : waves.Last().ID + 1;
            newWave.TimeOffset = GetShorelineTimeOffset(waves);
            //Debug.Log("ID " + newWave.ID + "   time offset " + newWave.TimeOffset);

            waves.Add(newWave);
            waterSystem.ClearShorelineFoam();
        }

        public void ComputeShorelineNextTransform(KW_ShorelineWaves.ShorelineWaveInfo newWave, List<KW_ShorelineWaves.ShorelineWaveInfo> wavesData, Ray ray, float waterHeight, bool interpolateNextPosition)
        {
            var intersectionPos = GetWaterRayIntersection(ray, waterHeight);
            newWave.PositionX = intersectionPos.x;
            newWave.PositionZ = intersectionPos.z;
            if (wavesData.Count > 0)
            {
                var lastIdx = wavesData.Count - 1;
                newWave.EulerRotation = wavesData[lastIdx].EulerRotation;
                newWave.ScaleX = wavesData[lastIdx].ScaleX;
                newWave.ScaleY = wavesData[lastIdx].ScaleY;
                newWave.ScaleZ = wavesData[lastIdx].ScaleZ;
            }

            if (interpolateNextPosition && wavesData.Count > 0)
            {
                if (wavesData.Count < 2) newWave.PositionZ += 10;
                else
                {
                    var currentIdx = wavesData.Count - 1;
                    var lastPos = new Vector2(wavesData[currentIdx].PositionX, wavesData[currentIdx].PositionZ);
                    var lastLastPos = new Vector2(wavesData[currentIdx - 1].PositionX, wavesData[currentIdx - 1].PositionZ);
                    var direction = (lastPos - lastLastPos).normalized;
                    var radius = new Vector2(wavesData[currentIdx].ScaleX, wavesData[currentIdx].ScaleZ).magnitude * 0.4f;
                    newWave.PositionX = lastPos.x + radius * direction.x;
                    newWave.PositionZ = lastPos.y + radius * direction.y;
                }
            }

            //var plane = new Plane(Vector3.down, waterSystem.transform.position.y);

            //var ray = useMousePositionAsStartPoint ? HandleUtility.GUIPointToWorldRay(Event.current.mousePosition) : new Ray(waterSystem.currentCamera.transform.position, waterSystem.currentCamera.transform.forward * 1000);

            //if (plane.Raycast(ray, out var distanceToPlane))
            //{
            //    var intersectionPos = ray.GetPoint(distanceToPlane);

            //    newWave.PositionX = intersectionPos.x;
            //    newWave.PositionZ = intersectionPos.z;
            //    if (wavesData.Count > 0)
            //    {
            //        var lastIdx = wavesData.Count - 1;
            //        newWave.EulerRotation = wavesData[lastIdx].EulerRotation;
            //        newWave.ScaleX = wavesData[lastIdx].ScaleX;
            //        newWave.ScaleY = wavesData[lastIdx].ScaleY;
            //        newWave.ScaleZ = wavesData[lastIdx].ScaleZ;
            //    }

            //    if (!useMousePositionAsStartPoint && wavesData.Count > 0)
            //    {
            //        if (wavesData.Count < 2) newWave.PositionZ += 10;
            //        else
            //        {
            //            var currentIdx = wavesData.Count - 1;
            //            var lastPos = new Vector2(wavesData[currentIdx].PositionX, wavesData[currentIdx].PositionZ);
            //            var lastLastPos = new Vector2(wavesData[currentIdx - 1].PositionX, wavesData[currentIdx - 1].PositionZ);
            //            var direction = (lastPos - lastLastPos).normalized;
            //            var radius = new Vector2(wavesData[currentIdx].ScaleX, wavesData[currentIdx].ScaleZ).magnitude * 0.4f;
            //            newWave.PositionX = lastPos.x + radius * direction.x;
            //            newWave.PositionZ = lastPos.y + radius * direction.y;
            //        }
            //    }
            //}
        }

        public Ray GetCurrentMouseToWorldRay()
        {
            return HandleUtility.GUIPointToWorldRay(Event.current.mousePosition);
        }


        public Vector3 GetSceneCameraPosition()
        {
            var sceneCamera = KWS_EditorUtils.GetSceneCamera();
             return sceneCamera.transform.position;
        }


        public Ray GetCameraToWorldRay()
        {
            var sceneCamT = KWS_EditorUtils.GetSceneCamera().transform;
            return new Ray(sceneCamT.position, sceneCamT.forward * 1000);
        }

        public Vector3 GetWaterRayIntersection(Ray ray, float waterHeight)
        {
            var plane = new Plane(Vector3.down, waterHeight);

            if (plane.Raycast(ray, out var distanceToPlane))
            {
                return ray.GetPoint(distanceToPlane);
            }
            return Vector3.zero;
        }


        public bool IsShorelineIntersectOther(int currentShorelineIdx, List<KW_ShorelineWaves.ShorelineWaveInfo> wavesData)
        {
            if (currentShorelineIdx < 0 || currentShorelineIdx >= wavesData.Count) return false;
            var currentWave = wavesData[currentShorelineIdx];
            var currentWavePos = new Vector3(currentWave.PositionX, 0, currentWave.PositionZ);
            var currentWaveMaxScale = Mathf.Max(currentWave.ScaleX, currentWave.ScaleZ);
            int startIdx = currentShorelineIdx % 2 == 0 ? 0 : 1;
            for (var i = startIdx; i < wavesData.Count; i += 2)
            {
                if (currentShorelineIdx == i) continue;

                var distance = (currentWavePos - new Vector3(wavesData[i].PositionX, 0, wavesData[i].PositionZ)).magnitude;
                var maxScale = Mathf.Max(wavesData[i].ScaleX, wavesData[i].ScaleZ);
                if (distance < (currentWaveMaxScale + maxScale) * 0.5f)
                {
                    return true;
                }
            }

            return false;
        }

        public float GetShorelineTimeOffset(List<KW_ShorelineWaves.ShorelineWaveInfo> wavesData)
        {
            if (wavesData.Count == 0) return 0;
            // if (shorelineWaves.Count == 1) return Random.Range(0.25f, 0.35f);

            // return shorelineWaves[shorelineWaves.Count - 2].TimeOffset + Random.Range(0.25f, 0.35f);
            var timeOffset = wavesData[wavesData.Count - 1].TimeOffset + Random.Range(0.13f, 0.22f);
            return timeOffset % 1;
        }

        public int GetWaveNearestToMouse(WaterSystem waterSystem, List<KW_ShorelineWaves.ShorelineWaveInfo> wavesData)
        {
            var   mouseWorldPos = KWS_EditorUtils.GetMouseWorldPosProjectedToWater(waterSystem.WaterWorldPosition.y, Event.current);
            float minDistance   = float.PositiveInfinity;
            int   minIdx        = 0;
            if (!float.IsInfinity(mouseWorldPos.x))
            {
                for (var i = 0; i < wavesData.Count; i++)
                {
                    var wave        = wavesData[i];
                    var distToMouse = new Vector2(wave.PositionX - mouseWorldPos.x, wave.PositionZ - mouseWorldPos.z).magnitude;
                    var waveRadius  = new Vector2(wave.ScaleX, wave.ScaleZ).magnitude * 2.0f;

                    if (distToMouse < waveRadius && distToMouse < minDistance)
                    {
                        minDistance = distToMouse;
                        minIdx      = i;
                    }
                }
            }

            return minIdx;
        }


        public async void DrawShorelineEditor(WaterSystem waterSystem)
        {
            if (Application.isPlaying) return;
            var wavesData = await waterSystem.GetShorelineWavesData();
            var waves = wavesData.ShorelineWaves;

            var defaultLighting = Handles.lighting;
            var defaultZTest = Handles.zTest;
            var defaultMatrix = Handles.matrix;

            Handles.lighting = false;
            Handles.zTest = UnityEngine.Rendering.CompareFunction.Always;

            var e = Event.current;

            if (e.type == EventType.MouseDown) _isMousePressed = true;
            else if (e.type == EventType.MouseUp) _isMousePressed = false;
            
            if (!_isMousePressed) _nearMouseSelectionWaveIdx = GetWaveNearestToMouse(waterSystem, waves);
           
            int controlID = GUIUtility.GetControlID(FocusType.Passive);
            if (Event.current.GetTypeForControl(controlID) == EventType.KeyDown)
            {
                if (Event.current.keyCode == KeyCode.Insert)
                {
                    AddWave(waterSystem, GetCurrentMouseToWorldRay(), false);
                    _isRequiredUpdateShorelineParams = true;
                    //waterSystem.SaveShorelineWavesParamsToDataFolder();
                }

                if (Event.current.keyCode == KeyCode.Delete)
                {
                    waves.RemoveAt(_nearMouseSelectionWaveIdx);
                    waterSystem.SaveShorelineToDataFolder();
                    waterSystem.Editor_RenderShorelineWavesWithFoam();
                    _isRequiredUpdateShorelineParams = true;
                    Event.current.Use();
                }
            }
          
            var waterYPos = waterSystem.WaterWorldPosition.y;
            for (var i = 0; i < waves.Count; i++)
            {
                var wave = waves[i];
                var wavePos = new Vector3(wave.PositionX, waterYPos, wave.PositionZ);

                Handles.matrix = defaultMatrix;


                if (_nearMouseSelectionWaveIdx == i)
                {
                    switch (Tools.current)
                    {
                        case Tool.Move:
                            var newWavePos = Handles.DoPositionHandle(wavePos, Quaternion.identity);
                           
                            if (wavePos != newWavePos) _isRequiredUpdateShorelineParams = true;

                            wave.PositionX = newWavePos.x;
                            wave.PositionZ = newWavePos.z;

                            break;
                        case Tool.Rotate:
                            {
                                var currentRotation = Quaternion.Euler(0, wave.EulerRotation, 0);
                                var newRotation = Handles.DoRotationHandle(currentRotation, wavePos);
                                if (currentRotation != newRotation) _isRequiredUpdateShorelineParams = true;
                                wave.EulerRotation = newRotation.eulerAngles.y;
                                break;
                            }
                        case Tool.Scale:
                            {
                                var distToCamera = Vector3.Distance(GetSceneCameraPosition(), wavePos);
                                var handleScaleToCamera = Mathf.Lerp(1, 50, Mathf.Clamp01(distToCamera / 500));

                                var currentScale = new Vector3(wave.ScaleX, wave.ScaleY, wave.ScaleZ);
                                var newScale = Handles.DoScaleHandle(new Vector3(wave.ScaleX, wave.ScaleY, wave.ScaleZ), wavePos, Quaternion.Euler(0, wave.EulerRotation, 0), handleScaleToCamera);
                                if (currentScale != newScale)
                                {
                                    _isRequiredUpdateShorelineParams = true;
                                    var maxNewScale = Mathf.Min(wave.ScaleX, wave.ScaleZ);
                                    var maxDefaultScale = Mathf.Min(wave.DefaultScaleX, wave.DefaultScaleZ);

                                    wave.ScaleX = newScale.x;
                                    wave.ScaleZ = newScale.z;
                                    wave.ScaleY = wave.DefaultScaleY * (maxNewScale / maxDefaultScale);

                                }



                                break;
                            }
                    }
                }

                var waveColor = i % 2 == 0 ? new Color(0, 0.75f, 1, 0.4f) : new Color(0.75f, 1, 0, 0.4f);
                var selectionColor = new Color(Mathf.Clamp01(waveColor.r * 1.5f), Mathf.Clamp01(waveColor.g * 1.5f), Mathf.Clamp01(waveColor.b * 1.5f), 0.95f);
                if (IsShorelineIntersectOther(_nearMouseSelectionWaveIdx, waves)) selectionColor = new Color(1, 0, 0, 0.9f);


                Handles.color = _nearMouseSelectionWaveIdx == i ? selectionColor : waveColor;
                Handles.matrix = Matrix4x4.TRS(wavePos, Quaternion.Euler(0, wave.EulerRotation, 0), new Vector3(wave.ScaleX, wave.ScaleY, wave.ScaleZ));
                Handles.DrawWireCube(Vector3.zero, Vector3.one);

                Handles.color = _nearMouseSelectionWaveIdx == i ? selectionColor * 0.3f : waveColor * 0.2f;
                Handles.CubeHandleCap(0, Vector3.zero, Quaternion.identity, 1, EventType.Repaint);


                //Handles.matrix = defaultMatrix;
                //if (i % 2 == 1 && i >= 3)
                //{
                //    Handles.color = new Color(1f, 1f, 0f, 0.99f);
                //    Handles.DrawLine(new Vector3(wavesData[i - 2].PositionX, waterYPos, wavesData[i - 2].PositionZ), wavePos);
                //}
                //if (i % 2 == 0 && i >= 2)
                //{
                //    Handles.color = new Color(0f, 1f, 1f, 0.99f);
                //    Handles.DrawLine(new Vector3(wavesData[i - 2].PositionX, waterYPos, wavesData[i - 2].PositionZ), wavePos);
                //}

                //Handles.matrix = Matrix4x4.TRS(wavePos, Quaternion.Euler(0, wave.EulerRotation, 0), new Vector3(0.5f, 0.5f, wave.ScaleZ));
                //Handles.CubeHandleCap(0, Vector3.zero, Quaternion.identity, 1, EventType.Repaint);


            }

            if (IsCanUpdateShoreline())
            {
                //waterSystem.RenderOrthoDepth();
                waterSystem.BakeWavesToTexture();

                waterSystem.Editor_RenderShorelineWavesWithFoam();
            }

            Handles.matrix = Matrix4x4.TRS(waterSystem.ShorelineAreaPosition - Vector3.up, Quaternion.identity, new Vector3(waterSystem.ShorelineAreaSize, 3.0f, waterSystem.ShorelineAreaSize));


            //Handles.color = new Color(0, 0.75f, 1, 0.05f);
            //Handles.CubeHandleCap(0, Vector3.zero, Quaternion.identity, 1, EventType.Repaint);
            Handles.color = new Color(0, 0.75f, 1, 0.075f);
            Handles.CubeHandleCap(0, Vector3.zero, Quaternion.identity, 1, EventType.Repaint);

            Handles.matrix = defaultMatrix;
            Handles.lighting = defaultLighting;
            Handles.zTest = defaultZTest;

            KWS_EditorUtils.LockLeftClickSelection(controlID);

        }

        public void UpdateShorelineTime()
        {
            _currentTimeBeforeShorelineUpdate += KW_Extensions.DeltaTime();
        }

        public void ForceUpdateShoreline()
        {
            _isRequiredUpdateShorelineParams = true;
        }

        bool IsCanUpdateShoreline()
        {
            if (_isRequiredUpdateShorelineParams)
            {

                if (_currentTimeBeforeShorelineUpdate > updateShorelineParamsEverySeconds)
                {
                    _isRequiredUpdateShorelineParams  = false;
                    _currentTimeBeforeShorelineUpdate = 0;
                    return true;
                }
            }
            return false;
        }

    }
}

#endif