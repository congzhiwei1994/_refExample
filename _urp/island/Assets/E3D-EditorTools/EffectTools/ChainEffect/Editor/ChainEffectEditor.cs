using UnityEditor;
using UnityEngine;

namespace E3DChain {

    [CustomEditor(typeof(ChainEffect))]
    public class ChainEffectEditor : TAEditor {

        void OnEnable() {
            layoutBegin();
            layoutProperty("pChainEffectRoot", "根节点");
            layoutEnd();
        }

        public override void OnInspectorGUI() {
            var ce = target as ChainEffect;
            layoutField();

            EditorGUI.BeginChangeCheck();
            var autoSegment = EditorGUILayout.Toggle("自动分段", ce.AutoSegment);
            if (EditorGUI.EndChangeCheck()) {
                ce.AutoSegment = autoSegment;
            }

            EditorGUI.indentLevel += 1;
            if (ce.AutoSegment) {
                EditorGUI.BeginChangeCheck();
                var autoSegmentLength = EditorGUILayout.FloatField("段长度", ce.AutoSegmentLength);
                if (EditorGUI.EndChangeCheck()) {
                    ce.AutoSegmentLength = autoSegmentLength;
                }
            } else {
                EditorGUI.BeginChangeCheck();
                var segment = EditorGUILayout.IntField("段数", ce.Segment);
                if (EditorGUI.EndChangeCheck()) {
                    ce.Segment = segment;
                }
            }
            EditorGUI.indentLevel -= 1;

            EditorGUI.BeginChangeCheck();
            /*var material = EditorGUILayout.ObjectField("材质", ce.ChainMaterial, typeof(Material), false) as Material;
            if (EditorGUI.EndChangeCheck()) {
                ce.ChainMaterial = material;
            }*/

            EditorGUI.BeginChangeCheck();
            var width = EditorGUILayout.FloatField("宽度", ce.ChainWidth);
            if (EditorGUI.EndChangeCheck()) {
                ce.ChainWidth = width;
            }

            EditorGUI.BeginChangeCheck();
            var randomShift = EditorGUILayout.Toggle("随机抖动", ce.RandomShift);
            if (EditorGUI.EndChangeCheck()) {
                ce.RandomShift = randomShift;
            }

            EditorGUI.indentLevel += 1;
            if (ce.RandomShift) {
                EditorGUI.BeginChangeCheck();
                var randomShiftLength = EditorGUILayout.FloatField("抖动偏移", ce.RandomShiftLength);
                if (EditorGUI.EndChangeCheck()) {
                    ce.RandomShiftLength = randomShiftLength;
                }

                EditorGUI.BeginChangeCheck();
                var randomShiftTime = EditorGUILayout.FloatField("抖动间隔", ce.RandomShiftTime);
                if (EditorGUI.EndChangeCheck()) {
                    ce.RandomShiftTime = randomShiftTime;
                }
            }
            EditorGUI.indentLevel -= 1;

            /*if (ce.transform.Find("MatProxy") == null) {
                if (GUILayout.Button("创建材质动画代理物体")) {
                    var proxy = GameObject.CreatePrimitive(PrimitiveType.Quad);
                    proxy.name = "MatProxy";
                    proxy.transform.SetParent(ce.transform);
                    var mc = proxy.GetComponent<MeshCollider>();
                    var mr = proxy.GetComponent<MeshRenderer>();
                    GameObject.DestroyImmediate(mc);
                    mr.sharedMaterial = ce.ChainMaterial;
                    mr.enabled = false;
                }
            }*/
        }

    }

}