#if UNITY_EDITOR
using System;
using System.Collections.Generic;
using System.Linq;
using UnityEditor;
using UnityEngine;
using static KWS.KWS_SplineMesh;
using Object = UnityEngine.Object;

namespace KWS
{
    public class KWS_EditorSplineMesh
    {
        public WaterSystem WaterInstance;

        public KWS_EditorSplineMesh(WaterSystem waterSystem)
        {
            WaterInstance = waterSystem;
        }

        enum MousePressedEnum
        {
            None,
            _Down,
            Up
        }

        enum SplineEditorMode
        {
            Default,
            AddSline,
            AddPoint,
            DeleteMode
        }
        readonly Color _handleGhostSphere = new Color(0.75f, 0.85f, 0.95f, 0.5f);
        readonly Color _handleGhostSphereNotAllowed = new Color(0.95f, 0.2f, 0.2f, 0.7f);

        readonly Color _handleMoveColor = new Color(0.3f, 0.55f, 0.9f, 0.8f);
        readonly Color _handleMoveColorAddMode = new Color(0.25f, 0.95f, 0.25f, 0.99f);
        readonly Color _handleMoveColorDeleteMode = new Color(0.95f, 0.25f, 0.25f, 0.99f);
        readonly Color _handleMoveUnselectedColor = new Color(0.5f, 0.5f, 0.5f, 0.6f);

        readonly Color _bezierSelectedColor = new Color(0.65f, 0.85f, 0.99f, 0.65f);
        readonly Color _bezierSelectedColorAddMode = new Color(0.65f, 0.95f, 0.69f, 0.99f);
        readonly Color _bezierSelectedColorDeleteMode = new Color(0.95f, 0.65f, 0.69f, 0.99f);
        readonly Color _bezierUnselectedColor = new Color(0.95f, 0.95f, 0.95f, 0.3f);

        private MousePressedEnum _mousePressedState;
        private SplinePoint _nearPoint;
        private Spline _nearSpline;
        private Spline _selectedSpline;

        private SplineEditorMode _splineEditorMode;

        private bool _isRequiredUpdateMesh;
        private bool _isSplineChanged;

        private const float MinDistanceBeetweenPoints = 2;

        //public void RecalculatePointsFlowHeight(List<SplinePoint> points)
        //{
        //    if (points.Count < 2) return;

        //    var startPos = points[0].WorldPosition;
        //    var endPos = points.Last().WorldPosition;
        //    var maxDistance = (startPos - endPos).sqrMagnitude;

        //    foreach (var point in points)
        //    {
        //        var distance = (point.WorldPosition - startPos).sqrMagnitude;
        //        var lerpedHeight = Mathf.Lerp(startPos.y, endPos.y, distance / maxDistance);
        //        if (Physics.Raycast(point.WorldPosition + Vector3.up * 5, Vector3.down, out var hit))
        //        {
        //            point.WorldPosition.y = Mathf.Max(hit.point.y, lerpedHeight);
        //        }
        //        else point.WorldPosition.y = lerpedHeight;
        //    }
        //}

        public void AddSpline()
        {
            _splineEditorMode = SplineEditorMode.AddSline;
        }

        public void DeleteSpline()
        {
            if (_selectedSpline == null) return;

            var splineArray = WaterInstance.splineMesh.CurrentSplineArray;
            if (splineArray == null || splineArray.Splines.Count == 0) return;

            var splines = splineArray.Splines;
            if (splines.Contains(_selectedSpline)) splines.Remove(_selectedSpline);

            WaterInstance.splineMesh?.UpdateMesh(isEditorMode: true);
        }

        public void UpdateVertexCountBetweenPoints()
        {
            if (_selectedSpline == null) return;

            _selectedSpline.VertexCountBetweenPoints = WaterInstance.RiverSplineVertexCountBetweenPoints;
            WaterInstance.splineMesh?.UpdateMesh(isEditorMode: true);
        }

        public int GetVertexCountBetweenPoints()
        {
            if (_selectedSpline == null) return -1;

            return _selectedSpline.VertexCountBetweenPoints;
        }

        public bool IsSplineChanged()
        {
            return _isSplineChanged;
        }

        public void ResetSplineChangeStatus()
        {
            _isSplineChanged = false;
        }

        void AddSplineByClick()
        {
            var splineArray = WaterInstance.splineMesh.CurrentSplineArray;
            if (splineArray == null) return;

            var splines = splineArray.Splines;
            if (KWS_EditorUtils.MouseRaycast(out var hit))
            {
                var spline = new Spline();
                var splinePoint = new SplinePoint(0, hit.point + Vector3.up * WaterInstance.RiverSplineNormalOffset);
                spline.SplinePoints.Add(splinePoint);
                splines.Add(spline);
                _selectedSpline = spline;
                _nearSpline = spline;
            }
            _isRequiredUpdateMesh = true;
            _isSplineChanged = true;
            _splineEditorMode = SplineEditorMode.Default;
            Debug.Log("River added");
        }

        SplinePoint GetNearSplinePoint(List<Spline> splines, out Spline nearSpline)
        {
            var mouseToCameraRay = HandleUtility.GUIPointToWorldRay(Event.current.mousePosition);

            SplinePoint nearSplinePoint = null;
            nearSpline = null;
            var lastDistance = float.MaxValue;
            foreach (var spline in splines)
            {
                foreach (var point in spline.SplinePoints)
                {
                    var currentDistance = HandleUtility.DistancePointLine(point.WorldPosition, mouseToCameraRay.origin, mouseToCameraRay.origin + mouseToCameraRay.direction * 100000);
                    var radius = HandleUtility.GetHandleSize(point.WorldPosition);
                    if (currentDistance < lastDistance && currentDistance < radius)
                    {
                        lastDistance = currentDistance;
                        nearSplinePoint = point;
                        nearSpline = spline;
                    }
                }
            }

            return nearSplinePoint;
        }

        void DrawSphereGhostUsingRaycast()
        {
            if (KWS_EditorUtils.MouseRaycast(out var hit))
            {
                var position = hit.point + Vector3.up * WaterInstance.RiverSplineNormalOffset;
                if (_selectedSpline != null && _selectedSpline.SplinePoints.Count > 0)
                {
                    var lastPoint = _selectedSpline.SplinePoints.Last();
                    Handles.color = IsAllowedPositionBeetweenPoints(lastPoint.WorldPosition, position) ? _handleGhostSphere : _handleGhostSphereNotAllowed;
                }
                else Handles.color = _handleGhostSphere;

                Handles.SphereHandleCap(0, position, Quaternion.identity, GetHandleSphereSize(position), EventType.Repaint);
            }
        }


        //Stopwatch sw = new Stopwatch();
        Vector3 DrawMoveHandle(Vector3 position, Color color)
        {
            var newPos = position;
            Handles.color = color;
            newPos = Handles.FreeMoveHandle(newPos, Quaternion.identity, GetHandleSphereSize(position), Vector3.one, Handles.CylinderHandleCap);
            return newPos;
        }

        Vector3 DrawMoveArrows(Vector3 position, Vector3 forward)
        {
            var newPos = position;

            Handles.color = Handles.xAxisColor;
            var right = Vector3.Cross(-forward, Vector3.up);
            newPos = Handles.Slider(position, right);

            Handles.color = Handles.yAxisColor;
            newPos = Handles.Slider(newPos, Vector3.up);

            Handles.color = Handles.zAxisColor;
            newPos = Handles.Slider(newPos + Vector3.up * 0.15f, forward) - Vector3.up * 0.15f;

            return newPos;
        }

        float DrawScaleArrows(Vector3 position, Vector3 forward, float scale)
        {
            Handles.color = Color.white;
            var right = Vector3.Cross(forward, Vector3.up);
            var handleScale = GetHandleScaleSize(position);
            var handleRotation = Quaternion.LookRotation(right);

            var newScale = Handles.ScaleSlider(scale, position, right, handleRotation, handleScale, handleScale);
            newScale = Handles.ScaleSlider(newScale, position, -right, handleRotation, handleScale, handleScale);
            newScale = Math.Max(0.25f, newScale);

            Handles.color = Color.green;
            Handles.DrawLine(position - right * scale, position + right * scale);

            if (Mathf.Abs(scale - newScale) > 0.01f)
            {
                _isRequiredUpdateMesh = true;
            }

            return newScale;
        }

        float GetHandleSphereSize(Vector3 position)
        {
            return HandleUtility.GetHandleSize(position) * 0.25f;
        }

        float GetHandleScaleSize(Vector3 position)
        {
            return HandleUtility.GetHandleSize(position) * 1.0f;
        }

        void AddNewPoint()
        {
            if (_selectedSpline == null) return;
            var splinePoints = _selectedSpline.SplinePoints;

            if (KWS_EditorUtils.MouseRaycast(out var hit))
            {
                var position = hit.point + Vector3.up * WaterInstance.RiverSplineNormalOffset;

                if (splinePoints.Count > 0)
                {
                    var lastPoint = _selectedSpline.SplinePoints.Last();
                    var isAllowed = IsAllowedPositionBeetweenPoints(lastPoint.WorldPosition, position);
                    if (!isAllowed)
                    {
                        KWS_EditorUtils.DisplayMessageNotification($"The minimum distance between the points should be greater than {MinDistanceBeetweenPoints} meters", false, 3);
                        return;
                    }
                }

                var splineID = (splinePoints.Count == 0) ? 0 : splinePoints.Last().ID + 1;
                var newPoint = new SplinePoint(splineID, position);
                if (splinePoints.Count > 0) newPoint.Width = splinePoints.Last().Width;

                splinePoints.Add(newPoint);
                _isSplineChanged = true;
            }
        }

        bool IsAllowedPositionBeetweenPoints(Vector3 lastPosition, Vector3 newPosition)
        {
            var distance = (lastPosition - newPosition).magnitude;
            if (distance < MinDistanceBeetweenPoints) return false;
            else return true;
        }

        void DeleteSelectedPoint()
        {
            if (_nearPoint == null || _selectedSpline == null) return;

            _selectedSpline.SplinePoints.Remove(_nearPoint);
            _isSplineChanged = true;
        }


        private void DrawHandles(List<SplinePoint> points, bool isSplineSelected)
        {
            var handleColor = _handleMoveUnselectedColor;
            if (isSplineSelected)
            {
                handleColor = _handleMoveColor;
                if (Event.current.shift) handleColor = _handleMoveColorAddMode;
                if (Event.current.control) handleColor = _handleMoveColorDeleteMode;
            }

            var selectedTool = Tools.current;
            for (var i = 0; i < points.Count; i++)
            {
                var isNearPoint = _nearPoint != null && _nearPoint == points[i];
                Vector3 newPos = points[i].WorldPosition;

                if (isNearPoint)
                {
                    Vector3 forward;
                    if (points.Count == 1) forward = Vector3.forward;
                    else
                    {
                        forward = i == points.Count - 1
                            ? (points[i].WorldPosition - points[i - 1].WorldPosition).normalized
                            : (points[i + 1].WorldPosition - points[i].WorldPosition).normalized;
                    }


                    if (selectedTool == Tool.Scale) points[i].Width = DrawScaleArrows(newPos, forward, points[i].Width);
                    else newPos = DrawMoveArrows(newPos, forward);

                }

                var freeMoveHandleNewPos = DrawMoveHandle(newPos, handleColor);
                newPos.x = freeMoveHandleNewPos.x;
                newPos.z = freeMoveHandleNewPos.z;

                
                if (!((newPos - points[i].WorldPosition).sqrMagnitude > 0.00001f)) continue;
                {
                    UpdatePointPositionIfAllowed(points, newPos, i);
                  
                }

                _isRequiredUpdateMesh = true;
            }
        }

        private void UpdatePointPositionIfAllowed(List<SplinePoint> points, Vector3 newPos, int i)
        {
            var isAllowedPrev = _nearPoint.ID - 1 >= 0 ? IsAllowedPositionBeetweenPoints(points[_nearPoint.ID - 1].WorldPosition, newPos) : true;
            var isAllowedNext = _nearPoint.ID + 1 < points.Count ? IsAllowedPositionBeetweenPoints(points[_nearPoint.ID + 1].WorldPosition, newPos) : true;

            if (isAllowedPrev && isAllowedNext)
            {
                points[i].WorldPosition = newPos;
                _isSplineChanged = true;
            }
        }

        private void DrawBezier(List<SplinePoint> points, bool isSplineSelected)
        {
            var bezierColor = _bezierUnselectedColor;

            if (isSplineSelected)
            {
                bezierColor = _bezierSelectedColor;
                if (Event.current.shift) bezierColor = _bezierSelectedColorAddMode;
                if (Event.current.control) bezierColor = _bezierSelectedColorDeleteMode;
            }

            Vector3 p0, p1, p2;
            for (int index = 0; index < points.Count - 2; index++)
            {
                if (index == 0) p0 = points[0].WorldPosition;
                else p0 = 0.5f * (points[index].WorldPosition + points[index + 1].WorldPosition);

                p1 = points[index + 1].WorldPosition;

                if (index == points.Count - 3) p2 = points[points.Count - 1].WorldPosition;
                else p2 = 0.5f * (points[index + 1].WorldPosition + points[index + 2].WorldPosition);

                Handles.DrawBezier(p0, p2, p1, p1, bezierColor, Texture2D.whiteTexture, 4);
            }
        }

        bool IsCanUpdateMesh()
        {
            if (_isRequiredUpdateMesh && _mousePressedState == MousePressedEnum.Up)
            {
                _isRequiredUpdateMesh = false;
                return true;
            }
            return false;
        }

        public void DrawSplineMeshEditor(Object target)
        {
            if (Application.isPlaying) return;

            var splineMesh = WaterInstance.splineMesh;
            if (splineMesh == null) return;

            var splineArray = splineMesh.CurrentSplineArray;
            if (splineArray == null) return;
            var splines = splineArray.Splines;

            var e = Event.current;
            UpdateMouseState(e);

            if (_mousePressedState == MousePressedEnum.None) _nearPoint = GetNearSplinePoint(splines, out _nearSpline);
            if (_mousePressedState == MousePressedEnum.Up && e.button == 0 && _nearSpline != null) _selectedSpline = _nearSpline;

            var isControlMode = e.control;
            var isShiftMode = e.shift;

            if (isControlMode && e.type == EventType.KeyDown && (e.keyCode != KeyCode.Z && e.keyCode != KeyCode.Y)) Event.current.Use();

            if (_splineEditorMode == SplineEditorMode.AddSline || (isShiftMode && _selectedSpline != null))
            {
                DrawSphereGhostUsingRaycast();
            }

            if (e.type == EventType.MouseDown && e.button == 0)
            {
                if (_splineEditorMode == SplineEditorMode.AddSline)
                {
                    AddSplineByClick();
                }
                if (isShiftMode)
                {
                    AddNewPoint();
                    splineMesh.UpdateMesh(isEditorMode: true);
                }
                if (isControlMode)
                {
                    DeleteSelectedPoint();
                    splineMesh.UpdateMesh(isEditorMode: true);
                }
            }

            foreach (var spline in splines)
            {
                var isCurrentSplineSelected = (_selectedSpline != null && spline == _selectedSpline);
                DrawBezier(spline.SplinePoints, isCurrentSplineSelected);
                DrawHandles(spline.SplinePoints, isCurrentSplineSelected);
            }

            if (IsCanUpdateMesh())
            {
                splineMesh.UpdateMesh(isEditorMode: true);
                //Debug.Log("Mesh Updated");
            }

            var badVertices = splineMesh.EditorBadVertices;
           
            Handles.color = Color.red;
            foreach (var badVert in badVertices)
            {
                Handles.DrawWireCube(badVert, Vector3.one * 0.35f);
            }

            int controlID = GUIUtility.GetControlID(FocusType.Passive);
            KWS_EditorUtils.LockLeftClickSelection(controlID);

            Undo.RecordObject(WaterInstance.splineMesh, "Changed spline point");
          
        }

        private void UpdateMouseState(Event e)
        {
            if (e.type == EventType.MouseDown) _mousePressedState = MousePressedEnum._Down;
            else if (_mousePressedState == MousePressedEnum._Down && e.type == EventType.MouseUp) _mousePressedState = MousePressedEnum.Up;
            else if (_mousePressedState == MousePressedEnum.Up) _mousePressedState = MousePressedEnum.None;
        }
    }
}
#endif
