using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.IO;
using System.Linq;
using System.Threading.Tasks;
using KWS;
using UnityEngine;
using UnityEngine.Rendering;
using Debug = UnityEngine.Debug;

namespace KWS
{
    [Serializable]
    public class KWS_SplineMesh : MonoBehaviour
    {

        [Serializable]
        public class SplineArray
        {
            [SerializeField] public List<Spline> Splines = new List<Spline>();
        }

        [Serializable]
        public class Spline
        {
            [SerializeField] public int               ID;
            [SerializeField] public List<SplinePoint> SplinePoints             = new List<SplinePoint>();
            [SerializeField] public int               VertexCountBetweenPoints = 20;
        }

        [Serializable]
        public class SplinePoint
        {
            [SerializeField] public int     ID;
            [SerializeField] public Vector3 WorldPosition;
            [SerializeField] public float   Width = 10;

            public SplinePoint(int id, Vector3 worldPos)
            {
                ID            = id;
                WorldPosition = worldPos;
            }
        }

        public SplineArray CurrentSplineArray;

        private KW_Extensions.AsyncInitializingStatusEnum _splineDataLoadStatus;
        public  Mesh                                      CurrentMesh { get; private set; }
        private List<Vector3>                             vertices  = new List<Vector3>();
        List<int>                                         triangles = new List<int>();
        List<Color>                                       colors    = new List<Color>();
        private List<Vector3>                             normals   = new List<Vector3>();
        private int                                       vertexIndex;
        private Color                                     _aboveSurfaceWater = Color.white;
        private Color                                     _underSurfaceWater = Color.black;

        public List<Vector3> EditorBadVertices = new List<Vector3>();

        class BezierPointCache
        {
            public Vector3 PointCurrent;
            public Vector3 DirectionCurrent;

            public Vector3 DirectionNext;
            public Vector3 PointNext;

            public float Scale;
            public int   RightDistance;
            public int   LeftDistance;

            public int Density;
        }

        void OnDisable()
        {
            KW_Extensions.SafeDestroy(CurrentMesh);
            vertices.Clear();
            triangles.Clear();
            colors.Clear();
            EditorBadVertices.Clear();
            _splineDataLoadStatus = KW_Extensions.AsyncInitializingStatusEnum.NonInitialized;
        }

        public async Task LoadOrCreateSpline(string GUID)
        {
            if (_splineDataLoadStatus == KW_Extensions.AsyncInitializingStatusEnum.NonInitialized)
            {
                _splineDataLoadStatus = KW_Extensions.AsyncInitializingStatusEnum.StartedInitialize;

                var pathToDataFolder = KW_Extensions.GetPathToStreamingAssetsFolder();
                var pathToDirectory  = Path.Combine(pathToDataFolder, KWS_Settings.DataPaths.SplineFolder, GUID);

                if (Directory.Exists(pathToDirectory))
                {
                    CurrentSplineArray = await KW_Extensions.DeserializeFromFile<SplineArray>(Path.Combine(pathToDirectory, KWS_Settings.DataPaths.SplineData));
                    if (CurrentSplineArray == null) _splineDataLoadStatus = KW_Extensions.AsyncInitializingStatusEnum.Failed;
                }
                else
                {
                    _splineDataLoadStatus = KW_Extensions.AsyncInitializingStatusEnum.Failed;
                }

                if (_splineDataLoadStatus == KW_Extensions.AsyncInitializingStatusEnum.Failed) CurrentSplineArray = new SplineArray();
                _splineDataLoadStatus = KW_Extensions.AsyncInitializingStatusEnum.Initialized;
            }
        }

        public Spline GetSplineByID(int id)
        {
            var splines = CurrentSplineArray.Splines;
            if (id < 0 && id > splines.Count - 1)
            {
                Debug.LogError("Incorrect spline ID");
                return null;
            }

            return CurrentSplineArray.Splines[id];
        }

        public void SaveSplineDataToFile(string GUID)
        {
            _splineDataLoadStatus = KW_Extensions.AsyncInitializingStatusEnum.StartedInitialize;

            var pathToDataFolder = KW_Extensions.GetPathToStreamingAssetsFolder();
            var pathToDirectory  = Path.Combine(pathToDataFolder, KWS_Settings.DataPaths.SplineFolder, GUID);
            var pathToFile       = Path.Combine(pathToDirectory,  KWS_Settings.DataPaths.SplineData);

            KW_Extensions.SerializeToFile(pathToFile, CurrentSplineArray);
        }


        public async Task<Mesh> CreateMeshFromSpline(string GUID)
        {
            if (CurrentSplineArray == null) await LoadOrCreateSpline(GUID);
            UpdateMesh(false);
            return CurrentMesh;
        }

        public void UpdateMesh(bool isEditorMode)
        {
            if (CurrentMesh == null)
            {
                CurrentMesh             = new Mesh() {hideFlags = HideFlags.HideAndDontSave};
                CurrentMesh.indexFormat = IndexFormat.UInt32;
                CurrentMesh.MarkDynamic();
            }

            if (CurrentSplineArray == null || CurrentSplineArray.Splines.Count == 0) return;
            var splines = CurrentSplineArray.Splines;

            vertices.Clear();
            triangles.Clear();
            colors.Clear();
            normals.Clear();
            EditorBadVertices.Clear();
            vertexIndex = 0;

            var splineCaches = new Dictionary<Spline, List<BezierPointCache>>();
            foreach (var spline in splines)
            {
                var bezierCache = PrecacheBezierPonts(spline.SplinePoints, spline.VertexCountBetweenPoints);
                splineCaches.Add(spline, bezierCache);
            }

            foreach (var splineCache in splineCaches)
            {
                var bezierCache = splineCache.Value;
                InitializeSurfaceMesh(bezierCache, isEditorMode);
            }

            KW_Extensions.WeldVertices(ref vertices, ref colors, ref triangles, ref normals);

            vertexIndex = vertices.Count;
            foreach (var splineCache in splineCaches)
            {
                var bezierCache = splineCache.Value;
                InitializeUnderwaterSurfaceMesh(bezierCache, new Vector3(0, 10, 0));
            }

            CurrentMesh.Clear();
            CurrentMesh.vertices  = vertices.ToArray();
            CurrentMesh.triangles = triangles.ToArray();
            CurrentMesh.colors    = colors.ToArray();
            CurrentMesh.normals   = normals.ToArray();
            CurrentMesh.RecalculateBounds();
            CurrentMesh.Optimize();
        }

        List<BezierPointCache> PrecacheBezierPonts(List<SplinePoint> points, int gridDensity)
        {
            var bezierCache    = new List<BezierPointCache>();
            var minDistance    = 1;
            var t              = transform;
            var lastPointIndex = points.Count - 3;

            var density = (int) Mathf.Lerp(10, 1, 1f * gridDensity / KWS_Settings.Water.SplineRiverMaxVertexCount);

            for (int pointIndex = 0; pointIndex <= lastPointIndex; pointIndex++)
            {
                InitializeBezierPoints(t, points, pointIndex, out var p0, out var p1, out var p2);
                InitializeBezierPointsWidth(points, pointIndex, out var s0, out var s1, out var s2);

                var pointStep                                 = 1.0f / gridDensity;
                if (pointIndex == points.Count - 3) pointStep = 1.0f / (gridDensity - 1.0f);

                for (int bezierPointIndex = 0; bezierPointIndex < gridDensity; bezierPointIndex++)
                {
                    var pointCache = new BezierPointCache();

                    var t1 = bezierPointIndex       * pointStep;
                    var t2 = (bezierPointIndex + 1) * pointStep;

                    pointCache.PointCurrent     = GetBezierPoint(p0, p1, p2, t1);
                    pointCache.PointNext        = GetBezierPoint(p0, p1, p2, t2);
                    pointCache.DirectionCurrent = GetOrientationHorizontal(p0, p1, p2, t1);
                    pointCache.DirectionNext    = GetOrientationHorizontal(p0, p1, p2, t2);
                    pointCache.Scale            = GetBezierScale(s0, s1, s2, t1);

                    pointCache.Density       = density;
                    pointCache.RightDistance = Mathf.Max(minDistance, Mathf.CeilToInt(RaycastFromVertex(t, pointCache.PointCurrent, pointCache.DirectionCurrent,  pointCache.Scale) / pointCache.Density) + 2);
                    pointCache.LeftDistance  = Mathf.Max(minDistance, Mathf.CeilToInt(RaycastFromVertex(t, pointCache.PointCurrent, -pointCache.DirectionCurrent, pointCache.Scale) / pointCache.Density) + 2);

                    bezierCache.Add(pointCache);
                }
            }

            return bezierCache;
        }

        void InitializeSurfaceMesh(List<BezierPointCache> bezierCache, bool isEditorMode)
        {
            var t          = transform;
            var cacheCount = bezierCache.Count;
            for (int bezierPointIndex = 0; bezierPointIndex < cacheCount; bezierPointIndex++)
            {
                var cache       = bezierCache[bezierPointIndex];
                var gridDensity = cache.Density;
                for (int offsetIdx = -cache.LeftDistance * gridDensity; offsetIdx < cache.RightDistance * gridDensity; offsetIdx += gridDensity)
                {
                    var vert1 = cache.PointCurrent + cache.DirectionCurrent * offsetIdx;
                    var vert2 = cache.PointNext    + cache.DirectionNext    * offsetIdx;
                    var vert3 = cache.PointCurrent + cache.DirectionCurrent * (offsetIdx + gridDensity);
                    var vert4 = cache.PointNext    + cache.DirectionNext    * (offsetIdx + gridDensity);

                    if (isEditorMode)
                    {
                        if ((vert1 - vert2).sqrMagnitude < 0.001)
                        {
                            EditorBadVertices.Add(t.TransformPoint(vert1));
                        }
                    }

                    AddQuad(vert1, vert2, vert3, vert4, _aboveSurfaceWater, _aboveSurfaceWater, _aboveSurfaceWater, _aboveSurfaceWater, false);
                }
            }
        }

        void InitializeUnderwaterSurfaceMesh(List<BezierPointCache> bezierCache, Vector3 heightOffset)
        {
            var cacheCount        = bezierCache.Count;
            int lastRightDistance = 0, lastLeftDistance = 0;
            for (int bezierPointIndex = 0; bezierPointIndex < cacheCount; bezierPointIndex++)
            {
                var cache = bezierCache[bezierPointIndex];

                var leftDistance  = cache.LeftDistance  * cache.Density;
                var rightDistance = cache.RightDistance * cache.Density;
                //start fringe
                if (bezierPointIndex == 0)
                {
                    for (int offsetIdx = -leftDistance; offsetIdx < rightDistance; offsetIdx += cache.Density)
                    {
                        var vert1 = cache.PointCurrent + cache.DirectionCurrent * offsetIdx;
                        var vert2 = vert1              - heightOffset;
                        var vert3 = cache.PointCurrent + cache.DirectionCurrent * (offsetIdx + cache.Density);
                        var vert4 = vert3              - heightOffset;
                        AddQuad(vert1, vert2, vert3, vert4, _aboveSurfaceWater, _underSurfaceWater, _aboveSurfaceWater, _underSurfaceWater, true);
                    }
                }

                //end fringe
                if (bezierPointIndex == cacheCount - 1)
                {
                    for (int offsetIdx = -leftDistance; offsetIdx < rightDistance; offsetIdx += cache.Density)
                    {
                        var vert1 = cache.PointNext + cache.DirectionNext * offsetIdx;
                        var vert2 = vert1           - heightOffset;
                        var vert3 = cache.PointNext + cache.DirectionNext * (offsetIdx + cache.Density);
                        var vert4 = vert3           - heightOffset;
                        AddQuad(vert1, vert2, vert3, vert4, _aboveSurfaceWater, _underSurfaceWater, _aboveSurfaceWater, _underSurfaceWater, false);
                    }
                }

                //right side
                {
                    var offset = rightDistance;
                    var vert1  = cache.PointCurrent + cache.DirectionCurrent * offset;
                    var vert2  = vert1              - heightOffset;
                    var vert3  = cache.PointNext    + cache.DirectionNext * offset;
                    var vert4  = vert3              - heightOffset;
                    AddQuad(vert1, vert2, vert3, vert4, _aboveSurfaceWater, _underSurfaceWater, _aboveSurfaceWater, _underSurfaceWater, true);

                    if (lastRightDistance < rightDistance)
                    {

                        var nextDistanceOffset = rightDistance - lastRightDistance;
                        for (int currentOffset = 0; currentOffset < nextDistanceOffset; currentOffset += cache.Density)
                        {
                            vert1 = cache.PointCurrent + cache.DirectionCurrent * (offset - currentOffset - cache.Density);
                            vert2 = cache.PointCurrent + cache.DirectionCurrent * (offset                 - currentOffset);
                            vert3 = vert1              - heightOffset;
                            vert4 = vert2              - heightOffset;

                            AddQuad(vert1, vert2, vert3, vert4, _aboveSurfaceWater, _aboveSurfaceWater, _underSurfaceWater, _underSurfaceWater, false);
                        }
                    }

                    if (lastRightDistance > rightDistance)
                    {
                        var nextDistanceOffset = lastRightDistance - rightDistance;
                        for (int currentOffset = cache.Density; currentOffset <= nextDistanceOffset; currentOffset += cache.Density)
                        {
                            vert1 = cache.PointCurrent + cache.DirectionCurrent * (offset + currentOffset - cache.Density);
                            vert2 = cache.PointCurrent + cache.DirectionCurrent * (offset                 + currentOffset);
                            vert3 = vert1              - heightOffset;
                            vert4 = vert2              - heightOffset;
                            AddQuad(vert1, vert2, vert3, vert4, _aboveSurfaceWater, _aboveSurfaceWater, _underSurfaceWater, _underSurfaceWater, true);
                        }

                    }
                }

                //left side
                {
                    var offset = -leftDistance;
                    var vert1  = cache.PointCurrent + cache.DirectionCurrent * (offset);
                    var vert2  = vert1              - heightOffset;
                    var vert3  = cache.PointNext    + cache.DirectionNext * (offset);
                    var vert4  = vert3              - heightOffset;
                    AddQuad(vert1, vert2, vert3, vert4, _aboveSurfaceWater, _underSurfaceWater, _aboveSurfaceWater, _underSurfaceWater, false);

                    if (lastLeftDistance < leftDistance)
                    {
                        var nextDistanceOffset = leftDistance - lastLeftDistance;
                        for (int currentOffset = 0; currentOffset < nextDistanceOffset; currentOffset += cache.Density)
                        {
                            vert1 = cache.PointCurrent + cache.DirectionCurrent * (offset                 + currentOffset);
                            vert2 = cache.PointCurrent + cache.DirectionCurrent * (offset + currentOffset + cache.Density);
                            vert3 = vert1              - heightOffset;
                            vert4 = vert2              - heightOffset;
                            AddQuad(vert1, vert2, vert3, vert4, _aboveSurfaceWater, _aboveSurfaceWater, _underSurfaceWater, _underSurfaceWater, false);
                        }
                    }

                    if (lastLeftDistance > leftDistance)
                    {
                        var nextDistanceOffset = lastLeftDistance - leftDistance;
                        for (int currentOffset = cache.Density; currentOffset <= nextDistanceOffset; currentOffset += cache.Density)
                        {
                            vert1 = cache.PointCurrent + cache.DirectionCurrent * (offset                 - currentOffset);
                            vert2 = cache.PointCurrent + cache.DirectionCurrent * (offset - currentOffset + cache.Density);
                            vert3 = vert1              - heightOffset;
                            vert4 = vert2              - heightOffset;
                            AddQuad(vert1, vert2, vert3, vert4, _aboveSurfaceWater, _aboveSurfaceWater, _underSurfaceWater, _underSurfaceWater, true);
                        }

                    }
                }

                //bottom side
                // for (int offsetIdx = -leftDistance; offsetIdx < rightDistance; offsetIdx++)
                {
                    var vert1 = cache.PointCurrent + cache.DirectionCurrent * -leftDistance - heightOffset;
                    var vert2 = cache.PointNext    + cache.DirectionNext    * -leftDistance - heightOffset;
                    var vert3 = cache.PointCurrent + cache.DirectionCurrent * rightDistance - heightOffset;
                    var vert4 = cache.PointNext    + cache.DirectionNext    * rightDistance - heightOffset;

                    AddQuad(vert1, vert2, vert3, vert4, _underSurfaceWater, _underSurfaceWater, _underSurfaceWater, _underSurfaceWater, true);
                }

                lastRightDistance = rightDistance;
                lastLeftDistance  = leftDistance;
            }
        }

        void AddQuad(Vector3 vert1, Vector3 vert2, Vector3 vert3, Vector3 vert4, Color color1, Color color2, Color color3, Color color4, bool isReversed)
        {
            vertices.Add(vert1);
            vertices.Add(vert2);
            vertices.Add(vert3);
            vertices.Add(vert4);

            if (isReversed)
            {
                triangles.Add(vertexIndex + 2);
                triangles.Add(vertexIndex + 1);
                triangles.Add(vertexIndex + 0);

                triangles.Add(vertexIndex + 3);
                triangles.Add(vertexIndex + 1);
                triangles.Add(vertexIndex + 2);

                Vector3 normal1 = Vector3.Cross(vert1 - vert3, vert1 - vert2).normalized;
                normals.Add(normal1);
                normals.Add(normal1);
                normals.Add(normal1);
                normals.Add(normal1);

            }
            else
            {
                triangles.Add(vertexIndex + 0);
                triangles.Add(vertexIndex + 1);
                triangles.Add(vertexIndex + 2);

                triangles.Add(vertexIndex + 2);
                triangles.Add(vertexIndex + 1);
                triangles.Add(vertexIndex + 3);

                Vector3 normal1 = Vector3.Cross(vert1 - vert2, vert1 - vert3).normalized;
                normals.Add(normal1);
                normals.Add(normal1);
                normals.Add(normal1);
                normals.Add(normal1);

            }

            colors.Add(color1);
            colors.Add(color2);
            colors.Add(color3);
            colors.Add(color4);

            vertexIndex += 4;
        }

        void InitializeBezierPoints(Transform t, List<SplinePoint> points, int index, out Vector3 p0, out Vector3 p1, out Vector3 p2)
        {
            var p0_local = t.InverseTransformPoint(points[index].WorldPosition);
            var p1_local = t.InverseTransformPoint(points[index + 1].WorldPosition);
            var p2_local = t.InverseTransformPoint(points[index + 2].WorldPosition);

            if (index == 0) p0 = t.InverseTransformPoint(points[0].WorldPosition);
            else p0            = 0.5f * (p0_local + p1_local);

            p1 = p1_local;

            if (index == points.Count - 3) p2 = t.InverseTransformPoint(points[points.Count - 1].WorldPosition);
            else p2                           = 0.5f * (p1_local + p2_local);
        }

        void InitializeBezierPointsWidth(List<SplinePoint> points, int index, out float s0, out float s1, out float s2)
        {
            var s0_local = points[index].Width;
            var s1_local = points[index + 1].Width;
            var s2_local = points[index + 2].Width;

            if (index == 0) s0 = points[0].Width;
            else s0            = 0.5f * (s0_local + s1_local);

            s1 = s1_local;

            if (index == points.Count - 3) s2 = points[points.Count - 1].Width;
            else s2                           = 0.5f * (s1_local + s2_local);
        }

        float RaycastFromVertex(Transform t, Vector3 vertexPosition, Vector3 direction, float maxDistance)
        {
            var worldVertexPos = t.TransformPoint(vertexPosition);

            var raycastHits = Physics.RaycastAll(worldVertexPos, direction, maxDistance);
            if (raycastHits.Length == 0) return maxDistance;
            float currentMaxDistance = raycastHits.Max(n => n.distance);
            return currentMaxDistance;

            //var reversedRaycastHits = Physics.RaycastAll(worldVertexPos + direction * maxDistance, -direction, maxDistance);
            //if (reversedRaycastHits.Length == 0) return maxDistance;
            //float currentReversedMaxDistance = reversedRaycastHits.Max(n => (n.point- worldVertexPos).magnitude);


            //return Mathf.Max(currentMaxDistance, currentReversedMaxDistance);
        }


        public static Vector3 GetBezierPoint(Vector3 p0, Vector3 p1, Vector3 p2, float t)
        {
            return (1 - t) * (1 - t) * p0 + 2 * t * (1 - t) * p1 + t * t * p2;
        }

        public static float GetBezierScale(float p0, float p1, float p2, float t)
        {
            return (1 - t) * (1 - t) * p0 + 2 * t * (1 - t) * p1 + t * t * p2;
        }

        public static Vector3 GetBezierTangent(Vector3 p0, Vector3 p1, Vector3 p2, float t)
        {
            float alpha   = 1f - t;
            float alpha_2 = alpha * alpha;
            float t_2     = t     * t;

            var tangent = p0 * (-alpha_2)                  +
                          p1 * (3f  * alpha_2 - 2 * alpha) +
                          p1 * (-3f * t_2     + 2 * t)     +
                          p2 * (t_2);

            return tangent.normalized;
        }

        public static Vector3 GetBezierNormal(Vector3 p0, Vector3 p1, Vector3 p2, float t)
        {
            Vector3 tangent  = GetBezierTangent(p0, p1, p2, t);
            Vector3 binormal = Vector3.Cross(Vector3.up, tangent).normalized;

            return Vector3.Cross(tangent, binormal);
        }

        public static Vector3 GetOrientationHorizontal(Vector3 p0, Vector3 p1, Vector3 p2, float t)
        {
            var tangent = GetBezierTangent(p0, p1, p2, t);
            var normal  = GetBezierNormal(p0, p1, p2, t);
            //return Quaternion.LookRotation(tangent, normal);
            var orientation = Vector3.Cross(-tangent, normal);
            orientation.y = 0;
            return orientation.normalized;
        }
    }
}