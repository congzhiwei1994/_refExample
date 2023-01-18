#if UNITY_EDITOR
using KWS;
using System;
using System.Collections.Generic;
using UnityEditor;
using UnityEngine;
using Random = UnityEngine.Random;

namespace KWS
{
    public class KWS_EditorFlowmap
    {
        private float floatMapCircleRadiusDefault = 2f;
        private bool leftKeyPressed;
        private bool isFlowMapChanged;
        private Vector3 flowMapLastPos = Vector3.positiveInfinity;

        public void DrawFlowMapEditor(WaterSystem waterSystem, Editor editor)
        {
            if (Application.isPlaying) return;

            var e = Event.current;
            if (e.type == EventType.ScrollWheel)
            {
                floatMapCircleRadiusDefault -= (e.delta.y * floatMapCircleRadiusDefault) / 40f;
                floatMapCircleRadiusDefault = Mathf.Clamp(floatMapCircleRadiusDefault, 0.1f, waterSystem.FlowMapAreaSize);
            }

            var controlId = GUIUtility.GetControlID(FocusType.Passive);
            HandleUtility.AddDefaultControl(controlId);
            if (e.type == EventType.ScrollWheel) e.Use();

            var waterPos = waterSystem.transform.position;
            var waterHeight = waterSystem.transform.position.y;
            var flowmapWorldPos = KWS.KWS_EditorUtils.GetMouseWorldPosProjectedToWater(waterHeight, e);
            if (float.IsInfinity(flowmapWorldPos.x)) return;
            var flowPosWithOffset = new Vector3(-waterSystem.FlowMapAreaPosition.x, 0, -waterSystem.FlowMapAreaPosition.z) + (Vector3)flowmapWorldPos;

            Handles.color = e.control ? new Color(1, 0, 0) : new Color(0, 0.8f, 1);
            Handles.CircleHandleCap(controlId, (Vector3)flowmapWorldPos, Quaternion.LookRotation(Vector3.up), floatMapCircleRadiusDefault, EventType.Repaint);

            Handles.color = e.control ? new Color(1, 0, 0, 0.2f) : new Color(0, 0.8f, 1, 0.25f);
            Handles.DrawSolidDisc((Vector3)flowmapWorldPos, Vector3.up, floatMapCircleRadiusDefault);



            // var flowMapAreaPos = new Vector3(waterPos.x + waterSystem.FlowMapOffset.x, waterPos.y, waterPos.z + waterSystem.FlowMapOffset.y);
            var flowMapAreaScale = new Vector3(waterSystem.FlowMapAreaSize, 0.5f, waterSystem.FlowMapAreaSize);
            Handles.matrix = Matrix4x4.TRS(waterSystem.FlowMapAreaPosition, Quaternion.identity, flowMapAreaScale);


            Handles.color = new Color(0, 0.75f, 1, 0.2f);
            Handles.CubeHandleCap(0, Vector3.zero, Quaternion.identity, 1, EventType.Repaint);
            Handles.color = new Color(0, 0.75f, 1, 0.9f);
            Handles.DrawWireCube(Vector3.zero, Vector3.one);

            if (Event.current.button == 0)
            {
                if (e.type == EventType.MouseDown)
                {
                    leftKeyPressed = true;
                    //waterSystem.flowMap.LastDrawFlowMapPosition = flowPosWithOffset;
                }
                if (e.type == EventType.MouseUp)
                {
                    leftKeyPressed = false;
                    isFlowMapChanged = true;
                    flowMapLastPos = Vector3.positiveInfinity;

                    editor.Repaint();
                }
            }

            if (leftKeyPressed)
            {
                if (float.IsPositiveInfinity(flowMapLastPos.x))
                {
                    flowMapLastPos = flowPosWithOffset;
                }
                else
                {
                    var brushDir = (flowPosWithOffset - flowMapLastPos);
                    flowMapLastPos = flowPosWithOffset;
                    waterSystem.DrawOnFlowMap(flowPosWithOffset, brushDir, floatMapCircleRadiusDefault, waterSystem.FlowMapBrushStrength, e.control);
                }
            }

        }
    }
}

#endif