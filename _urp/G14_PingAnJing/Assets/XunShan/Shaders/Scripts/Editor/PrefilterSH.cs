using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEditor;

namespace ShaderLib
{
    public static class PrefilterSH
    {
        public static void PrefilterToSH(Cubemap env, out SphericalHarmonicsL2 shData)
        {
            shData = new SphericalHarmonicsL2();

            EditorUtility.DisplayProgressBar("转换中", "正在处理，请稍候...", 0.1f);
            try
            {
                if (env == null)
                {
                    return;
                }
                TextureImporter importer = null;
                bool isGamma = true;
                if (!env.isReadable)
                {
                    var path = AssetDatabase.GetAssetPath(env);
                    if (string.IsNullOrEmpty(path))
                    {
                        UnityEngine.Debug.LogError("Cubemap not readable!");
                        return;
                    }
                    importer = TextureImporter.GetAtPath(path) as TextureImporter;
                    if (importer == null)
                    {
                        return;
                    }
                    importer.isReadable = true;
                    importer.SaveAndReimport();

                    isGamma = importer.sRGBTexture;
                }

                var usage = TextureUtil.GetUsageMode(env);
                bool isDoubleLDREncode = (usage == TextureUsageMode.DoubleLDR);
                bool isRGBMEncoded = (usage == TextureUsageMode.RGBMEncoded);
                try
                {
                    EditorUtility.DisplayProgressBar("转换中", "正在处理，请稍候...", 0.2f);
                    List<Color[]> envMapData = new List<Color[]>();
                    for (int faceIndex = 0; faceIndex < 6; faceIndex++)
                    {
                        CubemapFace face = (CubemapFace)faceIndex;
                        //var tempTexture = TextureUtil.GetSourceTexture(env, face);
                        //if (tempTexture == null)
                        //{
                        //    continue;
                        //}
                        //Debug.LogError("w:" + tempTexture.width + " w:" + env.width);
                        var pixels = env.GetPixels(face);
                        //var pixels = tempTexture.GetPixels();
                        // 处理GammarToLinear
                        // 处理HDR编码
                        if (isDoubleLDREncode || isRGBMEncoded || isGamma)
                        {
                            for (int _i = 0; _i < pixels.Length; ++_i)
                            {
                                var color = pixels[_i];
                                if (isDoubleLDREncode)
                                {
                                    // [0-1] to [0-2]
                                    color = color * 2.0f;
                                }
                                if (isGamma)
                                {
                                    color = color.linear;
                                }
                                pixels[_i] = color;
                            }
                        }
                        envMapData.Add(pixels);

                        //ReleaseTempTexture(tempTexture);
                    }
                   


                    EditorUtility.DisplayProgressBar("转换中", "正在处理，请稍候...", 0.3f);

                    //List<Color> coefficient = PrefilterUtil.PrefilterSH(envMapData, env.width);
                    //for (int _RGBIndex = 0; _RGBIndex < 3; ++_RGBIndex)
                    //{
                    //    for (int _coeffIndex = 0; _coeffIndex < 9; ++_coeffIndex)
                    //    {
                    //        shData[_RGBIndex, _coeffIndex] = coefficient[_coeffIndex][_RGBIndex];
                    //    }
                    //}

                    PrefilterUtil.PrefilterSH(envMapData, env.width, out shData);
                }
                catch (System.Exception e)
                {
                    UnityEngine.Debug.LogError(e);
                }
                EditorUtility.DisplayProgressBar("转换中", "正在处理，请稍候...", 0.8f);
                if (importer != null)
                {
                    importer.isReadable = false;
                    importer.SaveAndReimport();
                }
                EditorUtility.DisplayProgressBar("转换中", "正在处理，请稍候...", 0.9f);

            }
            catch (System.Exception e)
            {
                UnityEngine.Debug.LogError(e);
            }
            finally
            {
                EditorUtility.ClearProgressBar();
            }
        }

        private static void ReleaseTempTexture(Texture tex)
        {
            if (tex != null)
            {
                if (!EditorUtility.IsPersistent(tex))
                {
                    UnityEngine.Object.DestroyImmediate(tex);
                }
            }
        }
    }
}