using UnityEngine;
using System.Collections.Generic;
using System.Runtime.CompilerServices;
using UnityEngine.Rendering;

namespace KWS
{
    public class KW_MeshGenerator : MonoBehaviour
    {
        static List<int> triangles = new List<int>();
        static List<Vector3> vertices = new List<Vector3>();
        static List<Color> colors = new List<Color>();
        static List<Vector3> normals = new List<Vector3>();

        private static bool IsOutFarDistance;
        private static bool IsOutBoxFarDistance;
        private static float FarDistance;
        private static float BottomDistance;
        private static Vector3 GlobalScale;

        public static Mesh GenerateOceanPlane(float startSizeMeters, int quadsPerStartSize, float maxSizeMeters)
        {
          
            IsOutFarDistance = false;
            IsOutBoxFarDistance = false;
            FarDistance = maxSizeMeters;
            BottomDistance = maxSizeMeters * 0.5f;
            GlobalScale = Vector3.one;

            vertices.Clear();
            triangles.Clear();
            colors.Clear();
            normals.Clear();

            var offset = CreateStartChunk(startSizeMeters, quadsPerStartSize);

            var newSize = quadsPerStartSize / 2 + 4;
            var count = (int)((quadsPerStartSize / 4f));
            var lastCount = newSize - 2;
            do
            {
                var currentScale = count;
                offset += CreateChunk(lastCount + 2, (startSizeMeters * 0.5f + offset), currentScale, out lastCount);

            } while (offset * 0.5f < maxSizeMeters);

            KW_Extensions.WeldVertices(ref vertices, ref colors, ref triangles, ref normals);

            AddBoxUnderwater(lastCount + 2, Mathf.Clamp(FarDistance, 1, 1500), Color.black);

            var mesh = new Mesh();
            mesh.indexFormat = IndexFormat.UInt32;
            mesh.vertices = vertices.ToArray();
            mesh.triangles = triangles.ToArray();
            mesh.colors = colors.ToArray();
            mesh.normals = normals.ToArray();
            mesh.Optimize();
            mesh.RecalculateBounds();

            KW_Extensions.WaterLog(null, $"Generated ocean plane with size: {maxSizeMeters}", KW_Extensions.WaterLogMessageType.Initialize);

            return mesh;
        }

        public static Mesh GenerateFinitePlane(int quadsPerStartSize, Vector3 scale)
        {
            IsOutFarDistance = false;
            IsOutBoxFarDistance = false;
            FarDistance = scale.y;
            BottomDistance = FarDistance;
            GlobalScale = scale;

            vertices.Clear();
            triangles.Clear();
            colors.Clear();
            normals.Clear();

            CreateSimpleChunk(2, quadsPerStartSize, true);
            // KW_Extensions.WeldVertices(ref vertices, ref colors, ref triangles, ref normals);
           
            AddBoxUnderwater(quadsPerStartSize, 1, Color.black);
            SetBlackBorder(scale);

            var mesh = new Mesh();
            mesh.indexFormat = IndexFormat.UInt32;
            mesh.vertices = vertices.ToArray();
            mesh.triangles = triangles.ToArray();
            mesh.colors = colors.ToArray();
            mesh.normals = normals.ToArray();
            mesh.Optimize();
            mesh.RecalculateBounds();
          
            return mesh;
        }

        //the first color channel is used as a reflection/refraction mask, where 0 -> no reflection/refraction (sides).
        //the second color channel is used as a distortion mask, where 0 -> no distortion (bottom side), 0.5 -> distortion by Y position (border), 1 -> distortion by XYZ
        private static void SetBlackBorder(Vector3 scale)
        {
            var maxCounts = vertices.Count;
            scale = scale * 0.5f - Vector3.one * 0.05f;
            for (int i = 0; i < maxCounts; i++)
            {
                if (Mathf.Abs(vertices[i].x) > scale.x) colors[i] = new Color(1, 0.5f, 0);
                if (Mathf.Abs(vertices[i].z) > scale.z) colors[i] = new Color(1, 0.5f, 0);
                if (vertices[i].y < -0.1) colors[i] = new Color(0, 0, 0);
            }
        }

        private static float CreateStartChunk(float startSizeMeters, int quadsPerStartSize, bool isFiniteMesh = false)
        {
            var halfSize = quadsPerStartSize / 2;
            float quadLength = startSizeMeters / quadsPerStartSize;
            for (int i = 0; i < halfSize; i++)
            {
                AddRing(quadsPerStartSize - i * 2, (startSizeMeters * 0.5f - quadLength * i), isTripple: false, isFiniteMesh);
            }
            var offset = quadLength * 2;
            AddRing(halfSize + 2, (startSizeMeters * 0.5f + offset), isTripple: true, isFiniteMesh);
            return offset;
        }

        private static void CreateSimpleChunk(float startSizeMeters, int quadsPerStartSize, bool isFiniteMesh = false)
        {
            var   halfSize   = quadsPerStartSize / 2;
            float quadLength = startSizeMeters   / quadsPerStartSize;
            for (int i = 0; i < halfSize; i++)
            {
                AddRing(quadsPerStartSize - i * 2, (startSizeMeters * 0.5f - quadLength * i), isTripple: false, isFiniteMesh);
            }
            
        }

        private static float CreateChunk(int size, float startScale, int count, out int lastCount)
        {
            float scaleOffset = 0;
            for (int i = 0; i < count; i++)
            {
                if (i < count - 1)
                {
                    var newSize = size + 2 * i;
                    scaleOffset += 1f / (size - 2) * startScale * 2;
                    AddRing(newSize, startScale + scaleOffset);
                }
                else
                {
                    int newSize = (size + 2 * i) / 2 + 1;
                    scaleOffset += 1f / (size - 2) * startScale * 4;
                    AddRing(newSize, (startScale + scaleOffset), isTripple: true);
                }
            }
            lastCount = (size + 2 * (count - 1)) / 2 + 1;
            return scaleOffset;
        }

        private static void AddRing(int size, float scale, bool isTripple = false, bool isFiniteMesh = false)
        {
            if (IsOutFarDistance) return;

            if (IsOutFarDistance == false && scale * 0.5f > FarDistance)
            {
                IsOutFarDistance = true;
            }

            if (IsOutBoxFarDistance == false && scale > (isFiniteMesh ? 1 : FarDistance))
            {
                IsOutBoxFarDistance = true;
                //AddBoxUnderwater(size, scale, Color.black);
            }

            int x, y = 0;
            for (x = 0; x < size; x++)
                CreateQuad(size, scale, x, y, Side.Down, isTripple, Color.white);

            x = size - 1;
            for (y = 1; y < size; y++)
                CreateQuad(size, scale, x, y, Side.Right, isTripple, Color.white);

            y = size - 1;
            for (x = size - 2; x >= 0; x--)
                CreateQuad(size, scale, x, y, Side.Up, isTripple, Color.white);

            x = 0;
            for (y = size - 2; y > 0; y--)
                CreateQuad(size, scale, x, y, Side.Left, isTripple, Color.white);
        }

        static void AddBoxUnderwater(int size, float scale, Color color)
        {
            int x, y = 0;
            for (x = 0; x < size; x++)
                CreateQuadVertical(size, scale, x, y, Side.Down, color);

            x = size - 1;
            for (y = 0; y < size; y++)
                CreateQuadVertical(size, scale, x, y, Side.Right, color);

            y = size - 1;
            for (x = size - 1; x >= 0; x--)
                CreateQuadVertical(size, scale, x, y, Side.Up, color);

            x = 0;
            for (y = size - 1; y >= 0; y--)
                CreateQuadVertical(size, scale, x, y, Side.Left, color);

            x = 0;
            y = 0;
            for (x = 0; x < size; x++)
                CreateQuadBootom(size, scale, x, y, Side.Down, color);

            x = size - 1;
            for (y = 0; y < size; y++)
                CreateQuadBootom(size, scale, x, y, Side.Right, color);

            y = size - 1;
            for (x = size - 1; x >= 0; x--)
                CreateQuadBootom(size, scale, x, y, Side.Up, color);

            x = 0;
            for (y = size - 1; y >= 0; y--)
                CreateQuadBootom(size, scale, x, y, Side.Left, color);
        }

        static void CreateQuad(int size, float scale, int x, int y, Side side, bool isTripple, Color color)
        {
            var offset = (1f / size) * GlobalScale * scale;
            var position = new Vector3((x / (float)size - 0.5f) * GlobalScale.x, 0, (y / (float)size - 0.5f) * GlobalScale.z) * scale;

            var leftBottomIndex = AddPoint(position, color);
            var rightBottomIndex = AddPoint(position + new Vector3(offset.x, 0, 0), color);
            var rightUpIndex = AddPoint(position + new Vector3(0, 0, offset.z), color);
            var leftUpIndex = AddPoint(position + new Vector3(offset.x, 0, offset.z), color);
            if (isTripple)
            {
                if (Mathf.Abs(x - y) == size - 1 || Mathf.Abs(x - y) == 0) side = Side.Fringe;
                AddTripplePoint(side, leftBottomIndex, rightBottomIndex, rightUpIndex,
                    leftUpIndex, position, offset, color);
            }
            else
            {
                AddQuadIndexes(leftBottomIndex, rightBottomIndex, rightUpIndex, leftUpIndex);
            }
        }

        static void CreateQuadVertical(int size, float scale, int x, int y, Side side, Color color)
        {
            var offset = (1f / size) * GlobalScale * scale;
            var position = new Vector3((x / (float)size - 0.5f) * GlobalScale.x, 0, (y / (float)size - 0.5f) * GlobalScale.z) * scale;

            var leftBottom_Height = Vector3.zero;
            var rightBottom_Height = new Vector3(offset.x, 0, 0);
            var rightUp_Height = new Vector3(0, 0, offset.z);
            var leftUp_Height = new Vector3(offset.x, 0, offset.z);

            switch (side)
            {
                case Side.Down:
                    rightUp_Height = new Vector3(0, -FarDistance, 0);
                    leftUp_Height = new Vector3(offset.x, -FarDistance, 0);
                    break;
                case Side.Right:
                    leftBottom_Height = new Vector3(offset.x, -FarDistance, 0);
                    rightUp_Height = new Vector3(offset.x, -FarDistance, offset.z);
                    break;
                case Side.Up:
                    leftBottom_Height = new Vector3(0, -FarDistance, offset.z);
                    rightBottom_Height = new Vector3(offset.x, -FarDistance, offset.z);
                    break;
                case Side.Left:
                    rightBottom_Height = new Vector3(0, -FarDistance, 0);
                    leftUp_Height = new Vector3(0, -FarDistance, offset.z);
                    break;
            }

            var vert1 = position + leftBottom_Height;
            var vert2 = position + rightBottom_Height;
            var vert3 = position + rightUp_Height;
            var vert4 = position + leftUp_Height;
            var normal = ComputeNormal(vert1, vert2, vert3);

            var leftBottomIndex = AddPoint(vert1, color, normal);
            var rightBottomIndex = AddPoint(vert2, color, normal);
            var rightUpIndex = AddPoint(vert3, color, normal);
            var leftUpIndex = AddPoint(vert4, color, normal);


            AddQuadIndexes(rightBottomIndex, leftBottomIndex, leftUpIndex, rightUpIndex);
        }

        static void CreateQuadBootom(int size, float scale, int x, int y, Side side, Color color)
        {
            var offset = (1f / size) * GlobalScale * scale;
            var position = new Vector3((x / (float)size - 0.5f) * GlobalScale.x, 0, (y / (float)size - 0.5f) * GlobalScale.z) * scale;

            var leftBottom_Height = position + new Vector3(0, -BottomDistance, 0);
            var rightBottom_Height = position + new Vector3(offset.x, -BottomDistance, 0);
            var rightUp_Height = position + new Vector3(0, -BottomDistance, offset.z);
            var leftUp_Height = position + new Vector3(offset.x, -BottomDistance, offset.z);
            if (side == Side.Down)
            {
                rightUp_Height = new Vector3(position.x, -BottomDistance, -position.z);
                leftUp_Height = new Vector3(position.x + offset.x, -BottomDistance, -position.z);
            }

            var normal = ComputeNormal(leftBottom_Height, rightBottom_Height, rightUp_Height);
            var leftBottomIndex = AddPoint(leftBottom_Height, color, normal);
            var rightBottomIndex = AddPoint(rightBottom_Height, color, normal);
            var rightUpIndex = AddPoint(rightUp_Height, color, normal);
            var leftUpIndex = AddPoint(leftUp_Height, color, normal);

            AddQuadIndexes(rightBottomIndex, leftBottomIndex, leftUpIndex, rightUpIndex);
        }

        static void AddTripplePoint(Side side, int leftBottomIndex, int rightBottomIndex, int rightUpIndex, int leftUpIndex, Vector3 position, Vector3 offset, Color color)
        {
            int middleIndex;
            if (side == Side.Fringe)
            {
                AddQuadIndexes(leftBottomIndex, rightBottomIndex, rightUpIndex, leftUpIndex);
                return;
            }

            if (side == Side.Down)
            {
                middleIndex = AddPoint(position + new Vector3(offset.x / 2f, 0, offset.z), color);
                AddTripleIndexesDown(leftBottomIndex, rightBottomIndex, rightUpIndex, leftUpIndex, middleIndex);
            }
            if (side == Side.Right)
            {
                middleIndex = AddPoint(position + new Vector3(0, 0, offset.z / 2), color);
                AddTripleIndexesRight(leftBottomIndex, rightBottomIndex, rightUpIndex, leftUpIndex, middleIndex);
            }
            if (side == Side.Up)
            {
                middleIndex = AddPoint(position + new Vector3(offset.x / 2, 0, 0), color);
                AddTripleIndexesUp(leftBottomIndex, rightBottomIndex, rightUpIndex, leftUpIndex, middleIndex);
            }
            if (side == Side.Left)
            {
                middleIndex = AddPoint(position + new Vector3(offset.x, 0, offset.z / 2), color);
                AddTripleIndexesLeft(leftBottomIndex, rightBottomIndex, rightUpIndex, leftUpIndex, middleIndex);
            }

        }

        static void AddQuadIndexes(int index1, int index2, int index3, int index4)
        {
            triangles.Add(index1); triangles.Add(index3); triangles.Add(index2);
            triangles.Add(index2); triangles.Add(index3); triangles.Add(index4);
        }


        #region TripleIndexes

        static void AddTripleIndexesDown(int index1, int index2, int index3, int index4, int index5)
        {
            triangles.Add(index3); triangles.Add(index5); triangles.Add(index1);
            triangles.Add(index1); triangles.Add(index5); triangles.Add(index2);
            triangles.Add(index5); triangles.Add(index4); triangles.Add(index2);
        }

        static void AddTripleIndexesRight(int index1, int index2, int index3, int index4, int index5)
        {
            triangles.Add(index3); triangles.Add(index4); triangles.Add(index5);
            triangles.Add(index1); triangles.Add(index5); triangles.Add(index2);
            triangles.Add(index5); triangles.Add(index4); triangles.Add(index2);
        }

        static void AddTripleIndexesUp(int index1, int index2, int index3, int index4, int index5)
        {
            triangles.Add(index3); triangles.Add(index4); triangles.Add(index5);
            triangles.Add(index3); triangles.Add(index5); triangles.Add(index1);
            triangles.Add(index5); triangles.Add(index4); triangles.Add(index2);
        }

        static void AddTripleIndexesLeft(int index1, int index2, int index3, int index4, int index5)
        {
            triangles.Add(index3); triangles.Add(index4); triangles.Add(index5);
            triangles.Add(index1); triangles.Add(index5); triangles.Add(index2);
            triangles.Add(index3); triangles.Add(index5); triangles.Add(index1);
        }
        #endregion

        enum Side
        {
            Down,
            Right,
            Up,
            Left,
            Fringe
        }

        static Vector3 ComputeNormal(Vector3 position1, Vector3 position2, Vector3 position3)
        {
            return Vector3.Cross(position1 - position2, position1 - position3).normalized;
        }

        static int AddPoint(Vector3 position, Color color)
        {
            vertices.Add(position);
            normals.Add(Vector3.up);
            colors.Add(color);
            return vertices.Count - 1;
        }

        static int AddPoint(Vector3 position, Color color, Vector3 normal)
        {
            vertices.Add(position);
            normals.Add(normal);
            colors.Add(color);
            return vertices.Count - 1;
        }
    }
}
