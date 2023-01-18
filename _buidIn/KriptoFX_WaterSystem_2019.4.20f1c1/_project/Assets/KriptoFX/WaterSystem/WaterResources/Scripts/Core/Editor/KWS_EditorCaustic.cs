#if UNITY_EDITOR
using KWS;
using System;
using System.Collections.Generic;
using UnityEditor;
using UnityEngine;
using Random = UnityEngine.Random;

namespace KWS
{
    public class KWS_EditorCaustic
    {
        public void DrawCausticEditor(WaterSystem waterSystem)
        {
            Handles.lighting = false;
            var causticAreaScale = new Vector3(waterSystem.CausticOrthoDepthAreaSize, waterSystem.Transparent, waterSystem.CausticOrthoDepthAreaSize);
            var causticAreaPos   = waterSystem.CausticOrthoDepthPosition - Vector3.up * waterSystem.Transparent * 0.5f;
            Handles.matrix = Matrix4x4.TRS(causticAreaPos, Quaternion.identity, causticAreaScale);

            Handles.color = new Color(0, 0.75f, 1, 0.15f);
            Handles.CubeHandleCap(0, Vector3.zero, Quaternion.identity, 1, EventType.Repaint);
            Handles.color = new Color(0, 0.75f, 1, 0.9f);
            Handles.DrawWireCube(Vector3.zero, Vector3.one);
        }
    }
}

#endif