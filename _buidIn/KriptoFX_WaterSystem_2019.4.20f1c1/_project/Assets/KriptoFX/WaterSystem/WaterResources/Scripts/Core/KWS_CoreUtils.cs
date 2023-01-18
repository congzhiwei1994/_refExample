﻿using UnityEngine;
using UnityEngine.Experimental.Rendering;
#if UNITY_EDITOR
using UnityEditor.Experimental.SceneManagement;
#endif
using UnityEngine.Rendering;

namespace KWS
{
    public static partial class KWS_CoreUtils
    {

        private static int _sourceRT_id = Shader.PropertyToID("_SourceRT"); //by some reason _MainTex don't work
        private static int _sourceRTHandleScale_id = Shader.PropertyToID("_SourceRTHandleScale");
        const int MaxHeight = 1080;

        public static GraphicsFormat GetGraphicsFormatHDR()
        {
            if (SystemInfo.IsFormatSupported(GraphicsFormat.B10G11R11_UFloatPack32, FormatUsage.Render)) return GraphicsFormat.B10G11R11_UFloatPack32;
            else return GraphicsFormat.R16G16B16A16_SFloat;
        }

        public static bool CanRenderWaterForCurrentCamera(Camera cam)
        {
#if UNITY_EDITOR
            if (PrefabStageUtility.GetCurrentPrefabStage() != null) return false;
#endif
            if (cam.cameraType != CameraType.Game && cam.cameraType != CameraType.SceneView) return false;
            if (!cam.IsLayerRendered(KWS_Settings.Water.WaterLayer)) return false;
            if (!CanRenderWaterForCurrentCamera_PlatformSpecific(cam)) return false;
            //if (cam.name == "TopViewDepthCamera" || cam.name.Contains("eflect")) return false;
            return true;
        }

        public static void ConcatAndSetKeywords(string key1, bool value1, string key2, bool value2, string key3, bool value3, string key1_key2_key3)
        {
            if (!value1)
            {
                SetKeyword(key1, false);
                SetKeyword(key2, false);
                SetKeyword(key3, false);
                SetKeyword(key1_key2_key3, false);
            }
            else
            {
                if (!value2 && !value3)
                {
                    SetKeyword(key1, true);
                    SetKeyword(key2, false);
                    SetKeyword(key3, false);
                    SetKeyword(key1_key2_key3, false);
                }
                else if (value2 && !value3)
                {
                    SetKeyword(key1, false);
                    SetKeyword(key2, true);
                    SetKeyword(key3, false);
                    SetKeyword(key1_key2_key3, false);
                }
                else if (!value2 && value3)
                {
                    SetKeyword(key1, false);
                    SetKeyword(key2, false);
                    SetKeyword(key3, true);
                    SetKeyword(key1_key2_key3, false);
                }
                else
                {
                    SetKeyword(key1, false);
                    SetKeyword(key2, false);
                    SetKeyword(key3, false);
                    SetKeyword(key1_key2_key3, true);
                }
            }


        }

        public static void SetKeyword(string keyword, bool state)
        {
            if (state)
                Shader.EnableKeyword(keyword);
            else
                Shader.DisableKeyword(keyword);
        }

        public static void SetKeyword(this Material mat, string keyword, bool state)
        {
            if (state)
                mat.EnableKeyword(keyword);
            else
                mat.DisableKeyword(keyword);
        }

        public static void SetKeyword(this CommandBuffer buffer, string keyword, bool state)
        {
            if (state)
                buffer.EnableShaderKeyword(keyword);
            else
                buffer.DisableShaderKeyword(keyword);
        }

        public static void SetFloats(this WaterSystem waterInstance, params (int key, float value)[] waterParams)
        {
            SetFloats(waterInstance, null, waterParams);
        }

        public static void SetFloats(this WaterSystem waterInstance, CommandBuffer cmd, params (int key, float value)[] waterParams)
        {
            if (WaterSystem.ActiveWaterInstances.Count > 1)
            {
                var waterMaterials = waterInstance.GetWaterRenderingMaterials();
                for (int i = 0; i < waterMaterials.Count; i++)
                {
                    if (waterMaterials[i] == null) continue;
                    for (int j = 0; j < waterParams.Length; j++)
                    {
                        var param = waterParams[j];
                        waterMaterials[i].SetFloat(param.key, param.value);
                    }
                }
            }
            else
            {
                if (cmd != null)
                {
                    for (int j = 0; j < waterParams.Length; j++)
                    {
                        var param = waterParams[j];
                        cmd.SetGlobalFloat(param.key, param.value);
                    }
                }
                else
                {
                    for (int j = 0; j < waterParams.Length; j++)
                    {
                        var param = waterParams[j];
                        Shader.SetGlobalFloat(param.key, param.value);
                    }
                }
            }
        }

        public static void SetVectors(this WaterSystem waterInstance, params (int key, Vector4 value)[] waterParams)
        {
            SetVectors(waterInstance, null, waterParams);
        }

        public static void SetVectors(this WaterSystem waterInstance, CommandBuffer cmd, params (int key, Vector4 value)[] waterParams)
        {
            if (WaterSystem.ActiveWaterInstances.Count > 1)
            {
                var waterMaterials = waterInstance.GetWaterRenderingMaterials();
                for (int i = 0; i < waterMaterials.Count; i++)
                {
                    if (waterMaterials[i] == null) continue;
                    for (int j = 0; j < waterParams.Length; j++)
                    {
                        var param = waterParams[j];
                        waterMaterials[i].SetVector(param.key, param.value);
                    }
                }
            }
            else
            {
                if (cmd != null)
                {
                    for (int j = 0; j < waterParams.Length; j++)
                    {
                        var param = waterParams[j];
                        cmd.SetGlobalVector(param.key, param.value);
                    }
                }
                else
                {
                    for (int j = 0; j < waterParams.Length; j++)
                    {
                        var param = waterParams[j];
                        Shader.SetGlobalVector(param.key, param.value);
                    }
                }
            }
        }

        public static void SetTextures(this WaterSystem waterInstance, params (int key, Texture value)[] waterParams)
        {
            SetTextures(waterInstance, null, waterParams);
        }

        public static void SetTextures(this WaterSystem waterInstance, CommandBuffer cmd, params (int key, Texture value)[] waterParams)
        {
            if (WaterSystem.ActiveWaterInstances.Count > 1)
            {
                var waterMaterials = waterInstance.GetWaterRenderingMaterials();
                for (int i = 0; i < waterMaterials.Count; i++)
                {
                    if (waterMaterials[i] == null) continue;
                    for (int j = 0; j < waterParams.Length; j++)
                    {
                        var param = waterParams[j];
                        waterMaterials[i].SetTexture(param.key, param.value);
                    }
                }
            }
            else
            {
                if (cmd != null)
                {
                    for (int j = 0; j < waterParams.Length; j++)
                    {
                        var param = waterParams[j];
                        cmd.SetGlobalTexture(param.key, param.value);
                    }
                }
                else
                {
                    for (int j = 0; j < waterParams.Length; j++)
                    {
                        var param = waterParams[j];
                        Shader.SetGlobalTexture(param.key, param.value);
                    }
                }
            }
        }

        public static void SetKeywords(this WaterSystem waterInstance, params (string key, bool value)[] waterParams)
        {
            SetKeywords(waterInstance, null, waterParams);
        }

        public static void SetKeywords(this WaterSystem waterInstance, CommandBuffer cmd, params (string key, bool value)[] waterParams)
        {
            if (WaterSystem.ActiveWaterInstances.Count > 1)
            {
                var waterMaterials = waterInstance.GetWaterRenderingMaterials();
                for (int i = 0; i < waterMaterials.Count; i++)
                {
                    if (waterMaterials[i] == null) continue;
                    for (int j = 0; j < waterParams.Length; j++)
                    {
                        var param = waterParams[j];
                        waterMaterials[i].SetKeyword(param.key, param.value);
                    }
                }
            }
            else
            {
                if (cmd != null)
                {
                    for (int j = 0; j < waterParams.Length; j++)
                    {
                        var param = waterParams[j];
                        cmd.SetKeyword(param.key, param.value);
                    }
                }
                else
                {
                    for (int j = 0; j < waterParams.Length; j++)
                    {
                        var param = waterParams[j];
                        SetKeyword(param.key, param.value);
                    }
                }
            }
        }

        public class TemporaryRenderTexture
        {
            public RenderTextureDescriptor descriptor;
            public RenderTexture rt;
            string _name;
            public bool isInitialized;

            public TemporaryRenderTexture()
            {

            }

            public TemporaryRenderTexture(string name, TemporaryRenderTexture source)
            {
                descriptor = source.descriptor;
                rt = RenderTexture.GetTemporary(descriptor);
                rt.name = name;
                _name = name;
                if (!rt.IsCreated()) rt.Create();
                isInitialized = true;
            }

            public void Alloc(string name, int width, int height, int depth, GraphicsFormat format)
            {
                if (rt == null)
                {
#if UNITY_2019_2_OR_NEWER
                    descriptor = new RenderTextureDescriptor(width, height, format, depth);
#else
                    descriptor = new RenderTextureDescriptor(width, height, GraphicsFormatUtility.GetRenderTextureFormat(format), depth);
#endif

                    descriptor.sRGB = false;
                    descriptor.useMipMap = false;
                    descriptor.autoGenerateMips = false;

                    rt = RenderTexture.GetTemporary(descriptor);
                    rt.name = name;
                    _name = name;
                    if (!rt.IsCreated()) rt.Create();
                    isInitialized = true;

                }
                else if (rt.width != width || rt.height != height || !isInitialized || _name != name)
                {
                    if (isInitialized) Release();

                    descriptor.width = width;
                    descriptor.height = height;

                    rt = RenderTexture.GetTemporary(descriptor);
                    rt.name = name;
                    _name = name;
                    if (!rt.IsCreated()) rt.Create();
                    isInitialized = true;

                }
            }

            public void Alloc(string name, int width, int height, int depth, GraphicsFormat format, bool useMipMap,
            bool useRandomWrite = false, TextureDimension dimension = TextureDimension.Tex2D,
            bool autoGenerateMips = false, int mipMapCount = 0, int msaaSamples = 1, VRTextureUsage vrUsage = VRTextureUsage.None,
            FilterMode filterMode = FilterMode.Bilinear, ShadowSamplingMode shadowSamplingMode = ShadowSamplingMode.None)
            {
                if (rt == null)
                {
#if UNITY_2019_2_OR_NEWER
                    descriptor = new RenderTextureDescriptor(width, height, format, depth);
#else
                    descriptor = new RenderTextureDescriptor(width, height, GraphicsFormatUtility.GetRenderTextureFormat(format), depth);
#endif

                    descriptor.sRGB = false;
                    descriptor.enableRandomWrite = useRandomWrite;
                    descriptor.dimension = dimension;
                    descriptor.useMipMap = useMipMap;
                    descriptor.autoGenerateMips = autoGenerateMips;
                    descriptor.shadowSamplingMode = shadowSamplingMode;
#if UNITY_2019_2_OR_NEWER
                    descriptor.mipCount = mipMapCount;
#endif
                    descriptor.msaaSamples = msaaSamples;
                    descriptor.vrUsage = vrUsage;

                    rt = RenderTexture.GetTemporary(descriptor);
                    rt.name = name;
                    _name = name;
                    if (!rt.IsCreated()) rt.Create();
                    isInitialized = true;

                }
                else if (rt.width != width || rt.height != height || rt.dimension != dimension || rt.useMipMap != useMipMap || !isInitialized || _name != name)
                {
                    if (isInitialized) Release();

                    descriptor.width = width;
                    descriptor.height = height;
                    descriptor.dimension = dimension;
                    descriptor.useMipMap = useMipMap;

                    rt = RenderTexture.GetTemporary(descriptor);
                    rt.name = name;
                    _name = name;
                    if (!rt.IsCreated()) rt.Create();
                    isInitialized = true;

                }
            }

            public void Alloc(string name, int width, int height, int depth, GraphicsFormat format, ClearFlag clearFlag, Color clearColor,
bool useRandomWrite = false, TextureDimension dimension = TextureDimension.Tex2D, bool useMipMap = false,
bool autoGenerateMips = false, int mipMapCount = 0, int msaaSamples = 1, VRTextureUsage vrUsage = VRTextureUsage.None,
FilterMode filterMode = FilterMode.Bilinear, ShadowSamplingMode shadowSamplingMode = ShadowSamplingMode.None)
            {
                if (rt == null)
                {
#if UNITY_2019_2_OR_NEWER
                    descriptor = new RenderTextureDescriptor(width, height, format, depth);
#else
                    descriptor = new RenderTextureDescriptor(width, height, GraphicsFormatUtility.GetRenderTextureFormat(format), depth);
#endif

                    descriptor.sRGB = false;
                    descriptor.enableRandomWrite = useRandomWrite;
                    descriptor.dimension = dimension;
                    descriptor.useMipMap = useMipMap;
                    descriptor.autoGenerateMips = autoGenerateMips;
                    descriptor.shadowSamplingMode = shadowSamplingMode;
#if UNITY_2019_2_OR_NEWER
                    descriptor.mipCount = mipMapCount;
#endif
                    descriptor.msaaSamples = msaaSamples;
                    descriptor.vrUsage = vrUsage;

                    rt = RenderTexture.GetTemporary(descriptor);
                    rt.name = name;
                    _name = name;
                    if (!rt.IsCreated()) rt.Create();
                    ClearRenderTexture(rt, clearFlag, clearColor);
                    isInitialized = true;

                }
                else if (rt.width != width || rt.height != height || rt.dimension != dimension || rt.useMipMap != useMipMap || !isInitialized || _name != name)
                {
                    if (isInitialized) Release();

                    descriptor.width = width;
                    descriptor.height = height;
                    descriptor.dimension = dimension;
                    descriptor.useMipMap = useMipMap;

                    rt = RenderTexture.GetTemporary(descriptor);
                    rt.name = name;
                    _name = name;
                    if (!rt.IsCreated()) rt.Create();
                    ClearRenderTexture(rt, clearFlag, clearColor);
                    isInitialized = true;

                }
            }

            public void AllocDepth(string name, int width, int height, TextureDimension dimension = TextureDimension.Tex2D, ShadowSamplingMode shadowSamplingMode = ShadowSamplingMode.None)
            {
                if (rt == null)
                {
#if UNITY_2021_2_OR_NEWER
                   // descriptor = new RenderTextureDescriptor(width, height, SystemInfo.GetGraphicsFormat(DefaultFormat.LDR), SystemInfo.GetGraphicsFormat(DefaultFormat.DepthStencil));
                     descriptor = new RenderTextureDescriptor(width, height, RenderTextureFormat.Depth, 32);
#else
                    descriptor = new RenderTextureDescriptor(width, height, RenderTextureFormat.Depth, 32);
#endif
                    descriptor.dimension = dimension;
                    descriptor.shadowSamplingMode = shadowSamplingMode;

                    rt = RenderTexture.GetTemporary(descriptor);
                    rt.name = name;
                    _name = name;
                    if (!rt.IsCreated()) rt.Create();
                    isInitialized = true;
                }
                else if (rt.width != width || rt.height != height || rt.dimension != dimension || !isInitialized || _name != name)
                {
                    if (isInitialized) Release();

                    descriptor.width = width;
                    descriptor.height = height;
                    descriptor.dimension = dimension;

                    rt = RenderTexture.GetTemporary(descriptor);
                    rt.name = name;
                    _name = name;
                    isInitialized = true;
                    if (!rt.IsCreated()) rt.Create();
                }
            }

            public static implicit operator RenderTexture(TemporaryRenderTexture temporaryRT)
            {
                return temporaryRT?.rt;
            }

            public static implicit operator RenderTargetIdentifier(TemporaryRenderTexture temporaryRT)
            {
                return temporaryRT?.rt;
            }

            public void Release(bool unlink = false)
            {
                if (rt != null)
                {
                    RenderTexture.ReleaseTemporary(rt);
                    isInitialized = false;
                    if (unlink) rt = null;
                }
            }
        }


        public static Mesh CreateQuad()
        {
            var mesh = new Mesh();
            mesh.hideFlags = HideFlags.DontSave;

            Vector3[] vertices = new Vector3[4]
            {
                new Vector3(-0.5f, -0.5f, 0),
                new Vector3(0.5f, -0.5f, 0),
                new Vector3(-0.5f, 0.5f, 0),
                new Vector3(0.5f, 0.5f, 0)
            };
            mesh.vertices = vertices;

            int[] tris = new int[6]
            {
                0, 2, 1,
                2, 3, 1
            };
            mesh.triangles = tris;

            Vector3[] normals = new Vector3[4]
            {
                -Vector3.forward,
                -Vector3.forward,
                -Vector3.forward,
                -Vector3.forward
            };
            mesh.normals = normals;

            Vector2[] uv = new Vector2[4]
            {
                new Vector2(0, 0),
                new Vector2(1, 0),
                new Vector2(0, 1),
                new Vector2(1, 1)
            };
            mesh.uv = uv;

            return mesh;
        }

        public static Material CreateMaterial(string shaderName, string prefix)
        {
            return CreateMaterial(string.Format("{0}_{1}", shaderName, prefix));
        }

        public static Material CreateMaterial(string shaderName)
        {
            var waterShader = Shader.Find(shaderName);
            if (waterShader == null)
                Debug.LogError("Can't find the shader '" + shaderName + "' in the resources folder. Try to reimport the package.");

            var waterMaterial = new Material(waterShader);
            waterMaterial.hideFlags = HideFlags.HideAndDontSave;
            return waterMaterial;
        }

        public static ComputeBuffer GetOrUpdateBuffer<T>(ref ComputeBuffer buffer, int size) where T : struct
        {
            if (buffer == null)
            {
                buffer = new ComputeBuffer(size, System.Runtime.InteropServices.Marshal.SizeOf<T>());
            }
            else if (size > buffer.count)
            {
                buffer.Dispose();
                buffer = new ComputeBuffer(size, System.Runtime.InteropServices.Marshal.SizeOf<T>());
                // Debug.Log("ReInitializeHashBuffer");
            }

            return buffer;
        }

        public static void BlitTriangle(this CommandBuffer cmd, RenderTargetIdentifier dest, Material mat, int pass = 0)
        {
            KWS_SPR_CoreUtils.SetRenderTarget(cmd, dest);
            cmd.DrawProcedural(Matrix4x4.identity, mat, pass, MeshTopology.Triangles, 3);
        }

        public static void BlitTriangle(this CommandBuffer cmd, RenderTargetIdentifier source, RenderTargetIdentifier dest, Material mat, int pass = 0)
        {
            cmd.SetGlobalTexture(_sourceRT_id, source);
            cmd.BlitTriangle(dest, mat, pass);
        }

        public static void BlitTriangle(this CommandBuffer cmd, RenderTargetIdentifier source, Vector4 sourceRTHandleScale, RenderTargetIdentifier dest, Material mat, int pass = 0)
        {
            cmd.SetGlobalVector(_sourceRTHandleScale_id, sourceRTHandleScale);
            cmd.SetGlobalTexture(_sourceRT_id, source);
            cmd.BlitTriangle(dest, mat, pass);
        }

        public static void BlitTriangle(this CommandBuffer cmd, RenderTargetIdentifier target, Vector2 viewPortSize, Material mat, ClearFlag clearFlag, Color clearColor, int pass = 0)
        {
            cmd.SetRenderTarget(target);
            SetViewportAndClear(cmd, viewPortSize, clearFlag, clearColor);
            cmd.DrawProcedural(Matrix4x4.identity, mat, pass, MeshTopology.Triangles, 3);
        }

        public static void BlitTriangle(this CommandBuffer cmd, RenderTargetIdentifier source, Vector4 sourceRTHandleScale, RenderTargetIdentifier dest, Vector2 viewPortSize, Material mat, int pass = 0)
        {
            cmd.SetGlobalVector(_sourceRTHandleScale_id, sourceRTHandleScale);
            cmd.SetGlobalTexture(_sourceRT_id, source);
            cmd.BlitTriangle(dest, viewPortSize, mat, ClearFlag.None, Color.clear, pass);
        }

        public static void SetViewport(this CommandBuffer cmd, KWS_RTHandle target)
        {
            if (target.useScaling)
            {
                var scaledViewportSize = target.GetScaledSize(target.rtHandleProperties.currentViewportSize);
                cmd.SetViewport(new Rect(0.0f, 0.0f, scaledViewportSize.x, scaledViewportSize.y));
            }
        }

        public static void SetViewport(this CommandBuffer cmd, Vector2 viewPortSize)
        {
            cmd.SetViewport(new Rect(0.0f, 0.0f, viewPortSize.x, viewPortSize.y));
        }

        public static void SetViewportAndClear(this CommandBuffer cmd, KWS_RTHandle target, ClearFlag clearFlag, Color clearColor)
        {
#if !UNITY_EDITOR
            SetViewport(cmd, target);
#endif
            KWS_SPR_CoreUtils.ClearRenderTarget(cmd, clearFlag, clearColor);
#if UNITY_EDITOR
            SetViewport(cmd, target);
#endif
        }

        public static void SetViewportAndClear(this CommandBuffer cmd, Vector2 viewPortSize, ClearFlag clearFlag, Color clearColor)
        {
#if !UNITY_EDITOR
            SetViewport(cmd, viewPortSize);
#endif
            KWS_SPR_CoreUtils.ClearRenderTarget(cmd, clearFlag, clearColor);
#if UNITY_EDITOR
            SetViewport(cmd, viewPortSize);
#endif
        }

        public static void BlitTriangleRTHandle(this CommandBuffer cmd, KWS_RTHandle target, Material mat, ClearFlag clearFlag, Color clearColor, int pass = 0)
        {
            cmd.SetRenderTarget(target);
            SetViewportAndClear(cmd, target, clearFlag, clearColor);
            cmd.DrawProcedural(Matrix4x4.identity, mat, pass, MeshTopology.Triangles, 3);
        }

        public static void BlitTriangleRTHandle(this CommandBuffer cmd, RenderTargetIdentifier source, Vector4 sourceRTHandleScale, KWS_RTHandle target, Material mat, ClearFlag clearFlag, Color clearColor, int pass = 0)
        {
            cmd.SetGlobalVector(_sourceRTHandleScale_id, sourceRTHandleScale);
            cmd.SetGlobalTexture(_sourceRT_id, source);
            cmd.SetRenderTarget(target);
            SetViewportAndClear(cmd, target, clearFlag, clearColor);
            cmd.DrawProcedural(Matrix4x4.identity, mat, pass, MeshTopology.Triangles, 3);
        }

        public static Vector2Int GetScreenSizeLimited()
        {
            var width = Screen.width;
            var height = Screen.height;

            if (height > MaxHeight)
            {
                width = (int)(MaxHeight * width / (float)height);
                height = MaxHeight;
            }
            return new Vector2Int(width, height);
        }

        public static Vector2Int GetCameraScreenSizeLimited(Camera cam)
        {
            var width = cam.scaledPixelWidth;
            var height = cam.scaledPixelHeight;

            if (height > MaxHeight)
            {
                width = (int)(MaxHeight * width / (float)height);
                height = MaxHeight;
            }
            return new Vector2Int(width, height);
        }


        public static void ReleaseTemporaryRenderTextures(bool unlink = false, params TemporaryRenderTexture[] tempTenderTextures)
        {
            for (var i = 0; i < tempTenderTextures.Length; i++)
            {
                if (tempTenderTextures[i] == null) continue;
                tempTenderTextures[i].Release(unlink);
            }
        }

        public static void ReleaseComputeBuffers(params ComputeBuffer[] computeBuffers)
        {
            for (var i = 0; i < computeBuffers.Length; i++)
            {
                if (computeBuffers[i] == null) continue;
                computeBuffers[i].Release();
            }
        }

        public static void ReleaseRenderTextures(params RenderTexture[] renderTextures)
        {
            for (var i = 0; i < renderTextures.Length; i++)
            {
                if (renderTextures[i] == null) continue;
                renderTextures[i].Release();
            }
        }

        public static void ClearRenderTexture(RenderTexture rt, ClearFlag clearFlag, Color clearColor)
        {
            var activeRT = RenderTexture.active;
            RenderTexture.active = rt;
            GL.Clear((clearFlag & ClearFlag.Depth) != 0, (clearFlag & ClearFlag.Color) != 0, clearColor);
            RenderTexture.active = activeRT;
        }
    }
}