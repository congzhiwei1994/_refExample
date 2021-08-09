using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;

namespace ShaderLib
{
    static class LightProbePickerMenuItems
    {
        const string kRootMenu = "GameObject/LightProbe/";

        [MenuItem(kRootMenu + "LightProbe数据吸取", priority = 20)]
        static void CreateLightProbePicker(MenuCommand menuCommand)
        {
            var go = CreateGameObject("LightProbe数据吸取", menuCommand.context);
            var picker = go.AddComponent<LightProbePicker>();
        }

        public static GameObject CreateGameObject(string name, UnityEngine.Object context)
        {
            var parent = context as GameObject;
            var go = CreateGameObject(parent, name);
            GameObjectUtility.SetParentAndAlign(go, context as GameObject);
            Undo.RegisterCreatedObjectUndo(go, "Create " + go.name);
            Selection.activeObject = go;
            EditorApplication.ExecuteMenuItem("GameObject/Move To View");
            return go;
        }

        static public GameObject CreateGameObject(GameObject parent, string name, params System.Type[] types)
            => ObjectFactory.CreateGameObject(GameObjectUtility.GetUniqueNameForSibling(parent != null ? parent.transform : null, name), types);
    }
}