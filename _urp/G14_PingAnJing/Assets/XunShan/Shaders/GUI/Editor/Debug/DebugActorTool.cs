using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;
using UnityEditor.EditorTools;
using System;

namespace ShaderEditor
{
    [EditorTool("角色渲染调试工具")]
    public class DebugActorTool : DebugShaderTool
    {
        protected override float GetToolWindowWidth()
        {
            return 300f;
        }

        protected override Texture GetToolIcon()
        {
            return EditorGUIUtility.IconContent("Avatar Icon")?.image;
        }

        protected override string GetToolText()
        {
            return "角色渲染调试工具";
        }

        protected override string GetToolTip()
        {
            return "用于调试角色渲染是否正确";
        }

        protected override Type GetModeEnumType()
        {
            return typeof(DebugActor.Mode);
        }

        protected override int GetCurrentMode()
        {
            return (int)DebugActor.CurrentMode;
        }

        protected override void OnToolSelectMode(int _mode)
        {
            DebugActor.CurrentMode = (DebugActor.Mode)_mode;
        }

        protected override void OnToolExit()
        {
            Shader.DisableKeyword(ActorGUI.Keywords._G_DEBUG_ACTOR_ON);
        }

       
        protected override void OnToolUpdate(float _deltaTime)
        {
            if(DebugActor.CurrentMode != DebugActor.Mode.None)
            {
                Shader.SetGlobalInt(ActorGUI.PropName._G_DebugActorMode, (int)DebugActor.CurrentMode);
                Shader.EnableKeyword(ActorGUI.Keywords._G_DEBUG_ACTOR_ON);
            }
            else
            {
                Shader.DisableKeyword(ActorGUI.Keywords._G_DEBUG_ACTOR_ON);
            }
            
        }

        protected override void OnToolDrawBottom()
        {
            DrawHDRHeatmapGUI();
        }
    }
}