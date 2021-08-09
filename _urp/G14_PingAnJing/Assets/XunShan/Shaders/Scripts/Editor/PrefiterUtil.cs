using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;

namespace ShaderLib
{
    public class PrefilterUtil
    {
        /*
         * The data is internally ordered like this:
                                    [L00:  DC]

                        [L1-1:  y] [L10:   z] [L11:   x]

            [L2-2: xy] [L2-1: yz] [L20:  zz] [L21:  xz]  [L22:  xx - yy]

            The 9 coefficients for R, G and B are ordered like this:

            SphericalHarmonicsL2数据的排列：SphericalHarmonicsL2[RGB, Coefficient]
            L00, L1-1,  L10,  L11, L2-2, L2-1,  L20,  L21,  L22, // red channel

            L00, L1-1,  L10,  L11, L2-2, L2-1,  L20,  L21,  L22, // blue channel

            L00, L1-1,  L10,  L11, L2-2, L2-1,  L20,  L21,  L22  // green channel
        */

        /// <summary>
        /// 参考方法：XNA-Final-Engine的SphericalHarmonicsL2.cs
        /// 一定要转为线性空间
        /// </summary>
        /// <param name="envColorArray"></param>
        /// <param name="size"></param>
        /// <param name="outSHData"></param>
        public static void PrefilterSH(List<Color[]> envColorArray, int size, out SphericalHarmonicsL2 outSHData)
        {
            outSHData = new SphericalHarmonicsL2();

            float total_weight = 0.0f;
            for (int face = 0; face < 6; face++)
            {
                CubemapFace faceId = (CubemapFace)face;
                // Get the transformation for this face.
                Matrix4x4 cubeFaceMatrix;
                switch (faceId)
                {
                    case CubemapFace.PositiveX:
                        cubeFaceMatrix = Matrix4x4.LookAt(Vector3.zero, new Vector3(1, 0, 0), new Vector3(0, 1, 0));
                        break;
                    case CubemapFace.NegativeX:
                        cubeFaceMatrix = Matrix4x4.LookAt(Vector3.zero, new Vector3(-1, 0, 0), new Vector3(0, 1, 0));
                        break;
                    case CubemapFace.PositiveY:
                        cubeFaceMatrix = Matrix4x4.LookAt(Vector3.zero, new Vector3(0, 1, 0), new Vector3(0, 0, 1));
                        break;
                    case CubemapFace.NegativeY:
                        cubeFaceMatrix = Matrix4x4.LookAt(Vector3.zero, new Vector3(0, -1, 0), new Vector3(0, 0, -1));
                        break;
                    case CubemapFace.PositiveZ:
                        cubeFaceMatrix = Matrix4x4.LookAt(Vector3.zero, new Vector3(0, 0, -1), new Vector3(0, 1, 0));
                        break;
                    case CubemapFace.NegativeZ:
                        cubeFaceMatrix = Matrix4x4.LookAt(Vector3.zero, new Vector3(0, 0, 1), new Vector3(0, 1, 0));
                        break;
                    default:
                        throw new System.ArgumentOutOfRangeException();
                }
                // Extract the spherical harmonic for this face and accumulate it.
                outSHData += ExtractSphericalHarmonicForCubeFace(cubeFaceMatrix, envColorArray[face], size);
                total_weight += 1.0f;
            }
            // Average out the entire spherical harmonic.
            // The 4 is because the SH lighting input is being sampled over a cosine weighted hemisphere.
            // The hemisphere halves the divider, the cosine weighting halves it again.
            if(total_weight > 0)
            {
                outSHData *= 1.0f / total_weight;
            }
            outSHData = outSHData * 4;
        }

        private static SphericalHarmonicsL2 ExtractSphericalHarmonicForCubeFace(Matrix4x4 faceTransform, Color[] colorDataRGB, int faceSize)
        {
            SphericalHarmonicsL2 sh = new SphericalHarmonicsL2();

            // For each pixel in the face, generate it's SH contribution.
            // Treat each pixel in the cube as a light source, which gets added to the SH.
            // This is used to generate an indirect lighting SH for the scene.

            float directionStep = 2.0f / (faceSize - 1.0f);
            int pixelIndex = 0;

            float dirY = 1.0f;
            float y_total_weight = 0.0f;
            for (int y = 0; y < faceSize; y++)
            {
                SphericalHarmonicsL2 lineSh = new SphericalHarmonicsL2();
                float dirX = -1.0f;
                float x_total_weight = 0.0f;
                for (int x = 0; x < faceSize; x++)
                {
                    //the direction to the pixel in the cube
                    Vector3 direction = new Vector3(dirX, dirY, 1);
                    direction = faceTransform.MultiplyVector(direction);

                    //length of the direction vector
                    float length = direction.magnitude;
                    //approximate area of the pixel (pixels close to the cube edges appear smaller when projected)
                    float weight = 1.0f / length;

                    //normalise:
                    direction.x *= weight;
                    direction.y *= weight;
                    direction.z *= weight;

                    // 这个颜色必需是线性空间
                    Color rgb = colorDataRGB[pixelIndex++];
                    //Add it to the SH
                    lineSh.AddDirectionalLight(direction, rgb, weight);
                    x_total_weight += weight;

                    dirX += directionStep;
                }

                //average the SH
                if (x_total_weight > 0)
                {
                    lineSh *= 1 / x_total_weight;

                    y_total_weight += 1.0f;
                }

                // Add the line to the full SH
                // (SH is generated line by line to ease problems with floating point accuracy loss)
                sh += lineSh;

                dirY -= directionStep;
            }

            // Average the SH.
            if (y_total_weight > 0)
            {
                sh *= 1 / y_total_weight;
            }

            return sh;
        } // ExtractSphericalHarmonicForCubeFace

        #region SH
        // Prefilter environment map to compute 9 SH coeffcient
        //
        // env: 
        // Environment map data, must stored by +x,-x,+y,-y,+z,-z order.
        // And +x is right +y is up +z is forward vector.
        //
        // size: Environment map size in pixels
        //
        // return: Result stored in Y00, Y1-1, Y10, Y11, Y2-2, Y2-1, Y20, Y21, Y22 order
        //
        public static List<Color> PrefilterSH(List<Color[]> env, int size)
        {
            List<Color> result = new List<Color>();

            int[] ls = { 0, 1, 1, 1, 2, 2, 2, 2, 2 };
            int[] ms = { 0, 1, 0, -1, 2, 1, 0, -1, -2 };

            float halfSize = size / 2.0f;
            for (int i = 0; i < 9; i++)
            {
                Color coeffcient = new Color(0.0f, 0.0f, 0.0f);
                float totalTexelSolidAngle = 0.0f;

                // +x
                for (int y = 0; y < size; y++)
                {
                    for (int x = 0; x < size; x++)
                    {
                        Vector3 pos = new Vector3(halfSize - 0.5f, halfSize - x - 0.5f, halfSize - y - 0.5f);
                        pos.Normalize();

                        Color radiance = env[0][y * size + x];
                        float sh = SHFunction(pos, ls[i], ms[i]);
                        float texelSolidAngle = TexelCoordSolidAngle(x, y, size);
                        coeffcient = coeffcient + radiance * sh * texelSolidAngle;

                        totalTexelSolidAngle = totalTexelSolidAngle + texelSolidAngle;
                    }
                }

                // -x
                for (int y = 0; y < size; y++)
                {
                    for (int x = 0; x < size; x++)
                    {
                        Vector3 pos = new Vector3(-halfSize + 0.5f, x - halfSize + 0.5f, halfSize - y - 0.5f);
                        pos.Normalize();

                        Color radiance = env[1][y * size + x];
                        float sh = SHFunction(pos, ls[i], ms[i]);
                        float texelSolidAngle = TexelCoordSolidAngle(x, y, size);
                        coeffcient = coeffcient + radiance * sh * texelSolidAngle;

                        totalTexelSolidAngle = totalTexelSolidAngle + texelSolidAngle;
                    }
                }

                // +y
                for (int y = 0; y < size; y++)
                {
                    for (int x = 0; x < size; x++)
                    {
                        Vector3 pos = new Vector3(-halfSize + 0.5f + x, halfSize - 0.5f, halfSize - y - 0.5f);
                        pos.Normalize();

                        Color radiance = env[2][y * size + x];
                        float sh = SHFunction(pos, ls[i], ms[i]);
                        float texelSolidAngle = TexelCoordSolidAngle(x, y, size);
                        coeffcient = coeffcient + radiance * sh * texelSolidAngle;

                        totalTexelSolidAngle = totalTexelSolidAngle + texelSolidAngle;
                    }
                }

                // -y
                for (int y = 0; y < size; y++)
                {
                    for (int x = 0; x < size; x++)
                    {
                        Vector3 pos = new Vector3(halfSize - 0.5f - x, -halfSize + 0.5f, halfSize - y - 0.5f);
                        pos.Normalize();

                        Color radiance = env[3][y * size + x];
                        float sh = SHFunction(pos, ls[i], ms[i]);
                        float texelSolidAngle = TexelCoordSolidAngle(x, y, size);
                        coeffcient = coeffcient + radiance * sh * texelSolidAngle;

                        totalTexelSolidAngle = totalTexelSolidAngle + texelSolidAngle;
                    }
                }

                // +z
                for (int y = 0; y < size; y++)
                {
                    for (int x = 0; x < size; x++)
                    {
                        Vector3 pos = new Vector3(-halfSize + 0.5f + x, -halfSize + 0.5f + y, halfSize - 0.5f);
                        pos.Normalize();

                        Color radiance = env[4][y * size + x];
                        float sh = SHFunction(pos, ls[i], ms[i]);
                        float texelSolidAngle = TexelCoordSolidAngle(x, y, size);
                        coeffcient = coeffcient + radiance * sh * texelSolidAngle;

                        totalTexelSolidAngle = totalTexelSolidAngle + texelSolidAngle;
                    }
                }

                // -z
                for (int y = 0; y < size; y++)
                {
                    for (int x = 0; x < size; x++)
                    {
                        Vector3 pos = new Vector3(-halfSize + 0.5f + x, halfSize - 0.5f - y, -halfSize + 0.5f);
                        pos.Normalize();

                        Color radiance = env[5][y * size + x];
                        float sh = SHFunction(pos, ls[i], ms[i]);
                        float texelSolidAngle = TexelCoordSolidAngle(x, y, size);
                        coeffcient = coeffcient + radiance * sh * texelSolidAngle;

                        totalTexelSolidAngle = totalTexelSolidAngle + texelSolidAngle;
                    }
                }

                // Error correction
                coeffcient = coeffcient * 4.0f / totalTexelSolidAngle;

                result.Add(coeffcient);
            }

            return result;
        }

        private static float SHFunction(Vector3 v, int l, int m)
        {
            if (!(0 <= l && l <= 2 && -2 <= m && m <= 2)) return 0.0f;

            if (l == 0 && m == 0)
            {
                // Y00
                return 0.282095f;
            }
            else if (l == 1)
            {
                if (m == 0)
                {
                    // Y10
                    return 0.488603f * v.z;
                }
                else if (m == -1)
                {
                    // Y1-1
                    return 0.488603f * v.y;
                }
                else if (m == 1)
                {
                    // Y11
                    return 0.488603f * v.x;
                }
            }
            else if (l == 2)
            {
                if (m == 0)
                {
                    // Y20
                    return 0.315392f * (3.0f * v.z * v.z - 1.0f);
                }
                else if (m == -1)
                {
                    // Y2-1
                    return 1.092548f * v.y * v.z;
                }
                else if (m == 1)
                {
                    // Y21
                    return 1.092548f * v.x * v.z;
                }
                else if (m == -2)
                {
                    // Y2-2
                    return 1.092548f * v.x * v.y;
                }
                else if (m == 2)
                {
                    // Y22
                    return 0.546274f * (v.x * v.x - v.y * v.y);
                }
            }

            return 0.0f;
        }
        #endregion

        #region BruteForce
        // Prefilter environment map to compute irradiance map with brute force way
        //
        // env: 
        // Environment map data, must stored by +x,-x,+y,-y,+z,-z order.
        // And +z is up vector.
        //
        // srcSize: Environment map size in pixels
        //
        // dstSize: Irradiance map size in pixels
        //
        // return: Result environment map stored by +x,-x,+y,-y,+z,-z order
        //
        public static List<Color[]> PrefilterBruteForce(List<Color[]> env, int srcSize, int dstSize)
        {
            List<Color[]> result = new List<Color[]>();
            for (int i = 0; i < 6; i++)
            {
                result.Add(new Color[dstSize * dstSize]);
            }

            float srcHalfSize = srcSize / 2.0f;
            float dstHalfSize = dstSize / 2.0f;

            for (int faceIndex = 0; faceIndex < 6; faceIndex++)
            {
                for (int j = 0; j < dstSize; j++)
                {
                    for (int i = 0; i < dstSize; i++)
                    {
                        // Calculate target irradiance map direction
                        Vector3 dir = new Vector3(0.0f, 0.0f, 0.0f);
                        if (faceIndex == 0)  // +x
                        {
                            dir = new Vector3(dstHalfSize - 0.5f, dstHalfSize - i - 0.5f, dstHalfSize - j - 0.5f);
                        }
                        else if (faceIndex == 1)  // -x
                        {
                            dir = new Vector3(-dstHalfSize + 0.5f, i - dstHalfSize + 0.5f, dstHalfSize - j - 0.5f);
                        }
                        else if (faceIndex == 2)  // +y
                        {
                            dir = new Vector3(-dstHalfSize + 0.5f + i, dstHalfSize - 0.5f, dstHalfSize - j - 0.5f);
                        }
                        else if (faceIndex == 3)  // -y
                        {
                            dir = new Vector3(dstHalfSize - 0.5f - i, -dstHalfSize + 0.5f, dstHalfSize - j - 0.5f);
                        }
                        else if (faceIndex == 4)  // +z
                        {
                            dir = new Vector3(-dstHalfSize + 0.5f + i, -dstHalfSize + 0.5f + j, dstHalfSize - 0.5f);
                        }
                        else if (faceIndex == 5)  // -z
                        {
                            dir = new Vector3(-dstHalfSize + 0.5f + i, dstHalfSize - 0.5f - j, -dstHalfSize + 0.5f);
                        }
                        dir.Normalize();

                        float totalTexelSolidAngle = 0.0f;
                        Color irradiance = new Color(0.0f, 0.0f, 0.0f);

                        // +x
                        for (int y = 0; y < srcSize; y++)
                        {
                            for (int x = 0; x < srcSize; x++)
                            {
                                Vector3 pos = new Vector3(srcHalfSize - 0.5f, srcHalfSize - x - 0.5f, srcHalfSize - y - 0.5f);
                                pos.Normalize();

                                Color radiance = env[0][y * srcSize + x];
                                float ndotl = Mathf.Max(0.0f, Vector3.Dot(pos, dir));
                                float texelSolidAngle = TexelCoordSolidAngle(x, y, srcSize);
                                irradiance = irradiance + radiance * ndotl * texelSolidAngle;
                                totalTexelSolidAngle = totalTexelSolidAngle + texelSolidAngle;
                            }
                        }

                        // -x
                        for (int y = 0; y < srcSize; y++)
                        {
                            for (int x = 0; x < srcSize; x++)
                            {
                                Vector3 pos = new Vector3(-srcHalfSize + 0.5f, x - srcHalfSize + 0.5f, srcHalfSize - y - 0.5f);
                                pos.Normalize();

                                Color radiance = env[1][y * srcSize + x];
                                float ndotl = Mathf.Max(0.0f, Vector3.Dot(pos, dir));
                                float texelSolidAngle = TexelCoordSolidAngle(x, y, srcSize);
                                irradiance = irradiance + radiance * ndotl * texelSolidAngle;
                                totalTexelSolidAngle = totalTexelSolidAngle + texelSolidAngle;
                            }
                        }

                        // +y
                        for (int y = 0; y < srcSize; y++)
                        {
                            for (int x = 0; x < srcSize; x++)
                            {
                                Vector3 pos = new Vector3(-srcHalfSize + 0.5f + x, srcHalfSize - 0.5f, srcHalfSize - y - 0.5f);
                                pos.Normalize();

                                Color radiance = env[2][y * srcSize + x];
                                float ndotl = Mathf.Max(0.0f, Vector3.Dot(pos, dir));
                                float texelSolidAngle = TexelCoordSolidAngle(x, y, srcSize);
                                irradiance = irradiance + radiance * ndotl * texelSolidAngle;
                                totalTexelSolidAngle = totalTexelSolidAngle + texelSolidAngle;
                            }
                        }

                        // -y
                        for (int y = 0; y < srcSize; y++)
                        {
                            for (int x = 0; x < srcSize; x++)
                            {
                                Vector3 pos = new Vector3(srcHalfSize - 0.5f - x, -srcHalfSize + 0.5f, srcHalfSize - y - 0.5f);
                                pos.Normalize();

                                Color radiance = env[3][y * srcSize + x];
                                float ndotl = Mathf.Max(0.0f, Vector3.Dot(pos, dir));
                                float texelSolidAngle = TexelCoordSolidAngle(x, y, srcSize);
                                irradiance = irradiance + radiance * ndotl * texelSolidAngle;
                                totalTexelSolidAngle = totalTexelSolidAngle + texelSolidAngle;
                            }
                        }

                        // +z
                        for (int y = 0; y < srcSize; y++)
                        {
                            for (int x = 0; x < srcSize; x++)
                            {
                                Vector3 pos = new Vector3(-srcHalfSize + 0.5f + x, -srcHalfSize + 0.5f + y, srcHalfSize - 0.5f);
                                pos.Normalize();

                                Color radiance = env[4][y * srcSize + x];
                                float ndotl = Mathf.Max(0.0f, Vector3.Dot(pos, dir));
                                float texelSolidAngle = TexelCoordSolidAngle(x, y, srcSize);
                                irradiance = irradiance + radiance * ndotl * texelSolidAngle;
                                totalTexelSolidAngle = totalTexelSolidAngle + texelSolidAngle;
                            }
                        }

                        // -z
                        for (int y = 0; y < srcSize; y++)
                        {
                            for (int x = 0; x < srcSize; x++)
                            {
                                Vector3 pos = new Vector3(-srcHalfSize + 0.5f + x, srcHalfSize - 0.5f - y, -srcHalfSize + 0.5f);
                                pos.Normalize();

                                Color radiance = env[5][y * srcSize + x];
                                float ndotl = Mathf.Max(0.0f, Vector3.Dot(pos, dir));
                                float texelSolidAngle = TexelCoordSolidAngle(x, y, srcSize);
                                irradiance = irradiance + radiance * ndotl * texelSolidAngle;
                                totalTexelSolidAngle = totalTexelSolidAngle + texelSolidAngle;
                            }
                        }

                        // Error correction
                        irradiance = irradiance * 4 * Mathf.PI / totalTexelSolidAngle;

                        // Transform into radiance
                        irradiance = irradiance / Mathf.PI;

                        result[faceIndex][j * dstSize + i] = irradiance;
                    }
                }
            }

            return result;
        }
        #endregion

        private static float AreaElement(float x, float y)
        {
            return Mathf.Atan2(x * y, Mathf.Sqrt(x * x + y * y + 1.0f));
        }

        private static float TexelCoordSolidAngle(float x, float y, int size)
        {
            // Scale up to [-1,1] range (inclusive), offset by 0.5 to point to texel center
            float u = 2.0f * (x + 0.5f) / size - 1.0f;
            float v = 2.0f * (y + 0.5f) / size - 1.0f;

            float invRes = 1.0f / size;

            // Project area for this texel
            float x0 = u - invRes;
            float y0 = v - invRes;
            float x1 = u + invRes;
            float y1 = v + invRes;
            return AreaElement(x0, y0) - AreaElement(x0, y1) - AreaElement(x1, y0) + AreaElement(x1, y1);
        }
    }
}