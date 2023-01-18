using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
using Unity.Collections;
using static KWS.KWS_WaterLights;
using static KWS.KWS_ShaderConstants_PlatformSpecific;

namespace KWS
{
    public class KWS_VolumetricLighting_Pass
    {
        public bool IsInitialized;

        KWS_VolumetricLighting_CommandPass pass = new KWS_VolumetricLighting_CommandPass();
        CommandBuffer                      cmd;
        CameraEvent                        camEvent = CameraEvent.BeforeForwardAlpha;

        NativeArray<LightData>       lightsData;
        NativeArray<ShadowLightData> shadowLightsData;
        ComputeBuffer                dirLightDataBuffer;
        ComputeBuffer                pointLightDataBuffer;
        ComputeBuffer                shadowPointLightDataBuffer;
        ComputeBuffer                spotLightDataBuffer;
        ComputeBuffer                shadowSpotLightDataBuffer;

        List<VolumeLight> activeDirLights          = new List<VolumeLight>(1);
        List<VolumeLight> activePointLights        = new List<VolumeLight>(10);
        List<VolumeLight> activePointLightsShadows = new List<VolumeLight>(10);
        List<VolumeLight> activeSpotLights         = new List<VolumeLight>(10);
        List<VolumeLight> activeSpotLightsShadows  = new List<VolumeLight>(10);

        private Transform  _shadowFixInfiniteOceanT;
        private GameObject _shadowFixInfiniteOceanGO;
        private Mesh _shadowFixInfiniteOceanMesh;
        private Material _shadowFixInfiniteOceanMaterial;

        private Transform _shadowFixFiniteT;
        private GameObject _shadowFixFiniteGO;
        private Mesh _shadowFixFiniteMesh;
        private Material _shadowFixFiniteMaterial;

        Camera             lastCamera;

        public void Execute(Camera cam, WaterSystem water)
        {
            if (cmd == null) cmd = new CommandBuffer() {name = "Water.VolumetricLightings_Pass"};
            cmd.Clear();

            lastCamera = cam;

            IsInitialized = true;

            if (WaterSystem.ActiveWaterInstances.Count > 0 &&  WaterSystem.ActiveWaterInstances[0] == water)
            {
                UnityEngine.Profiling.Profiler.BeginSample("Water.CollectAllLightsToOneBuffer");
                CollectAllLightsToOneBuffer(cam, water);
                UnityEngine.Profiling.Profiler.EndSample();
            }

            pass.Initialize(water);
            KWS_SPR_CoreUtils.SetRenderTarget(cmd, pass.GetTargetColorBuffer());
            pass.Execute(cam, cmd);

            cam.AddCommandBuffer(camEvent, cmd);
        }

        public void FrameCleanup(Camera cam)
        {
            RemoveCommandBuffer();

            var lights = KWS_WaterLights.Lights;

            foreach (var light in lights)
            {
                light.IsVisible = false;
                light.ReleaseLight();
            }
        }

        void FixStandardShadows(Vector3 camPos, Vector3 camForward, WaterSystem water)
        {
            if (water.WaterMeshType == WaterSystem.WaterMeshTypeEnum.InfiniteOcean)
            {
                var shadowCube = GetShadowInfiniteCube(water);
                shadowCube.position = new Vector3(camPos.x, water.WaterMeshWorldPosition.y - 200, camPos.z);
            } 
            else if(_shadowFixInfiniteOceanGO != null) KW_Extensions.SafeDestroy(_shadowFixInfiniteOceanGO);

            var shadowsAnchor   = GetShadowAnchor(water);
            shadowsAnchor.position = camPos + camForward * 10;
        }

        void CollectAllLightsToOneBuffer(Camera cam, WaterSystem water)
        {
            var currentFrustumCameraPlanes = GeometryUtility.CalculateFrustumPlanes(cam);
            var lights                     = KWS_WaterLights.Lights;
            activeDirLights.Clear();
            activePointLights.Clear();
            activePointLightsShadows.Clear();
            activeSpotLights.Clear();
            activeSpotLightsShadows.Clear();

            var camT   = cam.transform;
            var camPos = camT.position;

            FixStandardShadows(camPos, camT.forward, water);

            foreach (var volumeLight in lights)
            {
                volumeLight.IsVisible = IsLightVisible(currentFrustumCameraPlanes, volumeLight);
                if (volumeLight.IsVisible) volumeLight.SqrDistanceToCamera = Vector3.SqrMagnitude(camPos - volumeLight.LightTransform.position);
                else volumeLight.SqrDistanceToCamera = float.MaxValue;
                //volumeLight.ShadowIndex = -1;
            }

            lights.Sort((x, y) => x.SqrDistanceToCamera.CompareTo(y.SqrDistanceToCamera));

            int shadowPointLightFreeIndex = 0;
            int shadowSpotLightFreeIndex  = 0;
            foreach (var volumeLight in lights)
            {
                if (volumeLight.IsVisible)
                {
                    var light = volumeLight.Light;
                    AddShadowLightByDistance(ref shadowPointLightFreeIndex, ref shadowSpotLightFreeIndex, volumeLight, light);
                }
            }

            // Debug.Log("Point: " + activePointLights.Count + ",   Point Shadows: " + activePointLightsShadows.Count + ",  free indexes: " + KWS_WaterLights.FreeShadowIndexes[LightType.Point].Count);
            //foreach (var l in activePointLightsShadows)
            //{
            //    Debug.Log("shadow light: " + l.Light.name + "  shadow index " + l.ShadowIndex);
            //}

            if (activeDirLights.Count > 0)
            {
                ComputeShadowLightsBuffer(activeDirLights, ref dirLightDataBuffer, LightType.Directional);
                Shader.SetGlobalBuffer(LightsID.KWS_DirLightsBuffer, dirLightDataBuffer);
            }

            var isSplit  = activeDirLights.Count > 0 && QualitySettings.shadowProjection == ShadowProjection.StableFit;
            var isSingle = QualitySettings.shadowCascades == 1;
            KWS_CoreUtils.ConcatAndSetKeywords(LightKeywords.KWS_USE_DIR_LIGHT, activeDirLights.Count > 0,
                                               LightKeywords.KWS_DIR_SINGLE, isSingle,
                                               LightKeywords.KWS_DIR_SPLIT, isSplit, LightKeywords.KWS_DIR_SINGLE_SPLIT);


            Shader.SetGlobalFloat(LightsID.KWS_DirLightsCount, 1);

            if (activePointLights.Count > 0)
            {
                ComputeLightsBuffer(activePointLights, ref pointLightDataBuffer, LightType.Point);
                Shader.SetGlobalBuffer(LightsID.KWS_PointLightsBuffer, pointLightDataBuffer);
            }

            KWS_CoreUtils.SetKeyword(LightKeywords.KWS_USE_POINT_LIGHTS, activePointLights.Count > 0);
            Shader.SetGlobalFloat(LightsID.KWS_PointLightsCount, activePointLights.Count);

            if (activePointLightsShadows.Count > 0)
            {
                ComputeShadowLightsBuffer(activePointLightsShadows, ref shadowPointLightDataBuffer, LightType.Point);
                Shader.SetGlobalBuffer(LightsID.KWS_ShadowPointLightsBuffer, shadowPointLightDataBuffer);
            }

            KWS_CoreUtils.SetKeyword(LightKeywords.KWS_USE_SHADOW_POINT_LIGHTS, activePointLightsShadows.Count > 0);
            Shader.SetGlobalFloat(LightsID.KWS_ShadowPointLightsCount, activePointLightsShadows.Count);

            if (activeSpotLights.Count > 0)
            {
                ComputeLightsBuffer(activeSpotLights, ref spotLightDataBuffer, LightType.Spot);
                Shader.SetGlobalBuffer(LightsID.KWS_SpotLightsBuffer, spotLightDataBuffer);
            }

            KWS_CoreUtils.SetKeyword(LightKeywords.KWS_USE_SPOT_LIGHTS, activeSpotLights.Count > 0);
            Shader.SetGlobalFloat(LightsID.KWS_SpotLightsCount, activeSpotLights.Count);

            if (activeSpotLightsShadows.Count > 0)
            {
                ComputeShadowLightsBuffer(activeSpotLightsShadows, ref shadowSpotLightDataBuffer, LightType.Spot);
                Shader.SetGlobalBuffer(LightsID.KWS_ShadowSpotLightsBuffer, shadowSpotLightDataBuffer);
            }

            KWS_CoreUtils.SetKeyword(LightKeywords.KWS_USE_SHADOW_SPOT_LIGHTS, activeSpotLightsShadows.Count > 0);
            Shader.SetGlobalFloat(LightsID.KWS_ShadowSpotLightsCount, activeSpotLightsShadows.Count);

            foreach (var volumeLight in lights)
            {
                volumeLight.LightUpdate(camPos);
            }
        }

        private void AddShadowLightByDistance(ref int shadowPointLightFreeIndex, ref int shadowSpotLightFreeIndex, VolumeLight volumeLight, Light light)
        {
            switch (light.type)
            {
                case LightType.Directional:
                {
                    volumeLight.ShadowIndex = 0;
                    activeDirLights.Add(volumeLight);
                }
                    break;
                case LightType.Point:
                    if (light.shadows != LightShadows.None && volumeLight.UseVolumetricShadows && activePointLightsShadows.Count < MaxShadowPointLights)
                    {
                        volumeLight.ShadowIndex = shadowPointLightFreeIndex;
                        activePointLightsShadows.Add(volumeLight);
                        shadowPointLightFreeIndex++;
                    }
                    else
                    {
                        volumeLight.ShadowIndex = -1;
                        activePointLights.Add(volumeLight);
                    }

                    break;
                case LightType.Spot:
                    if (light.shadows != LightShadows.None && volumeLight.UseVolumetricShadows && activeSpotLightsShadows.Count < MaxShadowSpotLights)
                    {
                        volumeLight.ShadowIndex = shadowSpotLightFreeIndex;
                        activeSpotLightsShadows.Add(volumeLight);
                        shadowSpotLightFreeIndex++;
                    }
                    else
                    {
                        volumeLight.ShadowIndex = -1;
                        activeSpotLights.Add(volumeLight);
                    }

                    break;
            }
        }

        private void ComputeLightsBuffer(List<VolumeLight> lights, ref ComputeBuffer buffer, LightType type)
        {
            buffer = KWS_CoreUtils.GetOrUpdateBuffer<LightData>(ref buffer, lights.Count);
            lightsData = new NativeArray<LightData>(lights.Count, Allocator.Temp);
            int idx = 0;
            foreach (var light in lights)
            {
                var currentLight = light.Light;
                var data         = lightsData[idx];

                data.color = currentLight.color.linear * currentLight.intensity;

                if (type == LightType.Point || type == LightType.Spot)
                {
                    data.position = light.LightTransform.position;
                    data.range = currentLight.range;
                    GetPointLightAttenuation(ref data.attenuation, currentLight.range);
                }

                if (type == LightType.Spot)
                {
                    GetSpotLightAttenuation(ref data.attenuation, currentLight.spotAngle);
                }

                if (type == LightType.Directional || type == LightType.Spot) data.forward = -light.LightTransform.forward;

                lightsData[idx] = data;
                idx++;
            }

            buffer.SetData(lightsData);

        }

        private void ComputeShadowLightsBuffer(List<VolumeLight> lights, ref ComputeBuffer buffer, LightType type)
        {
            buffer = KWS_CoreUtils.GetOrUpdateBuffer<ShadowLightData>(ref buffer, lights.Count);
            shadowLightsData = new NativeArray<ShadowLightData>(lights.Count, Allocator.Temp);
            int idx = 0;
            foreach (var light in lights)
            {
                var currentLight = light.Light;
                var data         = shadowLightsData[idx];

                data.color = currentLight.color.linear * currentLight.intensity;
                data.shadowStrength = currentLight.shadowStrength;
                data.shadowIndex = light.ShadowIndex;

                if (type == LightType.Point || type == LightType.Spot)
                {
                    data.position = light.LightTransform.position;
                    data.range = currentLight.range;
                    GetPointLightAttenuation(ref data.attenuation, currentLight.range);
                }

                if (type == LightType.Point)
                {
                    data.projectionParams = ComputePointLightProjectionParams(currentLight);
                }

                if (type == LightType.Spot)
                {
                    GetSpotLightAttenuation(ref data.attenuation, currentLight.spotAngle);
                    data.worldToShadow = ComputeSpotLightShadowMatrix(currentLight);
                }

                if (type == LightType.Directional || type == LightType.Spot) data.forward = -light.LightTransform.forward;

                shadowLightsData[idx] = data;
                idx++;
            }

            buffer.SetData(shadowLightsData);
        }

        void GetPointLightAttenuation(ref Vector4 attenuation, float lightRange)
        {
            float lightRangeSqr                 = lightRange * lightRange;
            float fadeStartDistanceSqr          = 0.8f       * 0.8f * lightRangeSqr;
            float fadeRangeSqr                  = (fadeStartDistanceSqr - lightRangeSqr);
            float lightRangeSqrOverFadeRangeSqr = -lightRangeSqr / fadeRangeSqr;
            float oneOverLightRangeSqr          = 1.0f           / Mathf.Max(0.0001f, lightRange * lightRange);

            attenuation.x = oneOverLightRangeSqr;
            attenuation.y = lightRangeSqrOverFadeRangeSqr;
        }

        void GetSpotLightAttenuation(ref Vector4 attenuation, float spotAngle)
        {
            // Spot Attenuation with a linear falloff can be defined as
            // (SdotL - cosOuterAngle) / (cosInnerAngle - cosOuterAngle)
            // This can be rewritten as
            // invAngleRange = 1.0 / (cosInnerAngle - cosOuterAngle)
            // SdotL * invAngleRange + (-cosOuterAngle * invAngleRange)
            // If we precompute the terms in a MAD instruction
            spotAngle += 2;
            float cosOuterAngle    = Mathf.Cos(Mathf.Deg2Rad                                                                              * spotAngle * 0.5f);
            float cosInnerAngle    = Mathf.Cos((2.0f * Mathf.Atan(Mathf.Tan(spotAngle * 0.5f * Mathf.Deg2Rad) * (64.0f - 18.0f) / 64.0f)) * 0.5f);
            float smoothAngleRange = Mathf.Max(0.001f, cosInnerAngle - cosOuterAngle);
            float invAngleRange    = 1.0f           / smoothAngleRange;
            float add              = -cosOuterAngle * invAngleRange;

            attenuation.z = invAngleRange;
            attenuation.w = add;
        }

        Vector4 ComputePointLightProjectionParams(Light light)
        {
            // for point light projection: x = zfar / (znear - zfar), y = (znear * zfar) / (znear - zfar), z=shadow bias, w=shadow scale bias
            var far  = light.range;
            var near = light.shadowNearPlane;
            return new Vector4(far / (near - far), (near * far) / (near - far), light.shadowBias, 0.97f);
        }

        public static bool IsLightVisible(Plane[] frustum, KWS_WaterLights.VolumeLight volumeLight)
        {
            var light          = volumeLight.Light;
            var isLightVisible = true;
            if (light.type      == LightType.Point) isLightVisible = IsPointLightVisible(frustum, volumeLight.LightTransform.position, light.range);
            else if (light.type == LightType.Spot) isLightVisible = IsSpotLightVisible(frustum, volumeLight.LightTransform.position, volumeLight.LightTransform.forward, light.range, light.spotAngle);
            return isLightVisible;
        }

        static bool IsPointLightVisible(Plane[] planes, Vector3 center, float radius)
        {
            for (int i = 0; i < planes.Length; i++)
            {
                if (planes[i].normal.x * center.x + planes[i].normal.y * center.y + planes[i].normal.z * center.z + planes[i].distance < -radius) return false;
            }

            return true;
        }

        static bool IsSpotLightVisible(Plane[] planes, Vector3 center, Vector3 direction, float radius, float angle)
        {
            var coneEndPosition = center + direction * radius;
            var coneEndRadius   = radius * Mathf.Tan(angle * Mathf.Deg2Rad * 0.5f);
            for (int i = 0; i < planes.Length; i++)
            {
                if (planes[i].normal.x * center.x          + planes[i].normal.y * center.y          + planes[i].normal.z * center.z          + planes[i].distance < -0.1 &&
                    planes[i].normal.x * coneEndPosition.x + planes[i].normal.y * coneEndPosition.y + planes[i].normal.z * coneEndPosition.z + planes[i].distance < -coneEndRadius) return false;
            }

            return true;
        }

        Quaternion GetRotationByCubeFace(CubemapFace face)
        {
            switch (face)
            {
                case CubemapFace.NegativeX: return Quaternion.Euler(0,   -90,  0);
                case CubemapFace.PositiveX: return Quaternion.Euler(0,   90,   0);
                case CubemapFace.PositiveY: return Quaternion.Euler(90,  0,    0);
                case CubemapFace.NegativeY: return Quaternion.Euler(-90, 0,    0);
                case CubemapFace.PositiveZ: return Quaternion.Euler(0,   0,    0);
                case CubemapFace.NegativeZ: return Quaternion.Euler(0,   -180, 0);
            }

            return Quaternion.identity;
        }

        Transform GetShadowInfiniteCube(WaterSystem water) //unity disable shadows rendering if there is no opaque objects in a frustrum. So avoid it just by creating simple small object. 
        {
            if (_shadowFixInfiniteOceanGO == null)
            {
                _shadowFixInfiniteOceanGO = new GameObject("KWS.VolumetricLighting.UnityShadowRenderingDistanceFixForOcean");
                _shadowFixInfiniteOceanMaterial = KWS_CoreUtils.CreateMaterial("Particles/Standard Unlit");
                _shadowFixInfiniteOceanMesh = KWS_CoreUtils.CreateQuad();

                _shadowFixInfiniteOceanGO.AddComponent<MeshRenderer>().sharedMaterial = _shadowFixInfiniteOceanMaterial;
                _shadowFixInfiniteOceanGO.AddComponent<MeshFilter>().sharedMesh = _shadowFixInfiniteOceanMesh;

                _shadowFixInfiniteOceanGO.hideFlags = HideFlags.HideAndDontSave;
                _shadowFixInfiniteOceanGO.transform.localRotation = Quaternion.Euler(270, 0, 0);
                _shadowFixInfiniteOceanGO.transform.localScale = new Vector3(10000, 10000, 1);
                _shadowFixInfiniteOceanGO.transform.parent = water.WaterTemporaryObject.transform;
                _shadowFixInfiniteOceanT = _shadowFixInfiniteOceanGO.transform;
            }

            return _shadowFixInfiniteOceanT;
        }

        Transform GetShadowAnchor(WaterSystem water) //unity disable shadows rendering if there is no opaque objects in a frustrum. So avoid it just by creating simple small object. 
        {
            if (_shadowFixFiniteGO == null)
            {
                _shadowFixFiniteGO = new GameObject("KWS.VolumetricLighting.UnityShadowRenderingFix");
                _shadowFixFiniteMaterial = KWS_CoreUtils.CreateMaterial("Particles/Standard Unlit");
                _shadowFixFiniteMesh = KWS_CoreUtils.CreateQuad();

                _shadowFixFiniteGO.AddComponent<MeshRenderer>().sharedMaterial = _shadowFixFiniteMaterial;
                _shadowFixFiniteGO.AddComponent<MeshFilter>().sharedMesh = _shadowFixFiniteMesh;

                _shadowFixFiniteGO.hideFlags = HideFlags.HideAndDontSave;
                _shadowFixFiniteGO.transform.localScale = new Vector3(0, 0, 0);
                _shadowFixFiniteGO.transform.parent = water.WaterTemporaryObject.transform;
                _shadowFixFiniteT = _shadowFixFiniteGO.transform;
            }

            return _shadowFixFiniteT;
        }

        private Matrix4x4 ComputePointLightShadowMatrix(Light currentLight, CubemapFace face)
        {
            var       clip = Matrix4x4.TRS(new Vector3(0.5f, 0.5f, 0.5f), Quaternion.identity, new Vector3(0.5f, 0.5f, 0.5f));
            Matrix4x4 proj;
            if (SystemInfo.usesReversedZBuffer)
                proj = Matrix4x4.Perspective(90, 1, currentLight.range, currentLight.shadowNearPlane);
            else
                proj = Matrix4x4.Perspective(90, 1, currentLight.shadowNearPlane, currentLight.range);

            var m = clip * proj;
            m[0, 2] *= -1;
            m[1, 2] *= -1;
            m[2, 2] *= -1;
            m[3, 2] *= -1;

            var view = Matrix4x4.TRS(currentLight.transform.position, GetRotationByCubeFace(face), Vector3.one).inverse;
            return m * view;
        } //backup for atlas system instead of cubemaps

        private Matrix4x4 ComputeSpotLightShadowMatrix(Light currentLight)
        {
            var       clip = Matrix4x4.TRS(new Vector3(0.5f, 0.5f, 0.5f), Quaternion.identity, new Vector3(0.5f, 0.5f, 0.5f));
            Matrix4x4 proj;
            if (SystemInfo.usesReversedZBuffer)
                proj = Matrix4x4.Perspective(currentLight.spotAngle, 1, currentLight.range, currentLight.shadowNearPlane);
            else
                proj = Matrix4x4.Perspective(currentLight.spotAngle, 1, currentLight.shadowNearPlane, currentLight.range);

            var m = clip * proj;
            m[0, 2] *= -1;
            m[1, 2] *= -1;
            m[2, 2] *= -1;
            m[3, 2] *= -1;

            var view = Matrix4x4.TRS(currentLight.transform.position, currentLight.transform.rotation, Vector3.one).inverse;
            return m * view;
        }

        void RemoveCommandBuffer()
        {
            if (cmd != null && lastCamera != null)
            {
                lastCamera.RemoveCommandBuffer(camEvent, cmd);
            }
        }

        public void Release()
        {
            KWS_CoreUtils.ReleaseComputeBuffers(dirLightDataBuffer, pointLightDataBuffer, shadowPointLightDataBuffer, spotLightDataBuffer, shadowSpotLightDataBuffer);
            dirLightDataBuffer = pointLightDataBuffer = shadowPointLightDataBuffer = spotLightDataBuffer = shadowSpotLightDataBuffer;
            RemoveCommandBuffer();
            pass.Release();

            //unity crashed if I trying to remove _shadowFixInfiniteOceanGO and _shadowFixFiniteGO, but anyway it will be removed by water tempGameObject. 
            if (_shadowFixInfiniteOceanGO   != null) KW_Extensions.SafeDestroy(_shadowFixInfiniteOceanMaterial, _shadowFixInfiniteOceanMesh);
            if(_shadowFixFiniteGO != null) KW_Extensions.SafeDestroy(_shadowFixFiniteMaterial, _shadowFixFiniteMesh);

            Shader.DisableKeyword(LightKeywords.KWS_USE_DIR_LIGHT);
            Shader.DisableKeyword(LightKeywords.KWS_DIR_SINGLE);
            Shader.DisableKeyword(LightKeywords.KWS_DIR_SPLIT);
            Shader.DisableKeyword(LightKeywords.KWS_DIR_SINGLE_SPLIT);

            Shader.DisableKeyword(LightKeywords.KWS_USE_POINT_LIGHTS);
            Shader.DisableKeyword(LightKeywords.KWS_USE_SHADOW_POINT_LIGHTS);
            Shader.DisableKeyword(LightKeywords.KWS_USE_SPOT_LIGHTS);
            Shader.DisableKeyword(LightKeywords.KWS_USE_SHADOW_SPOT_LIGHTS);
            IsInitialized = false;
        }
    }
}