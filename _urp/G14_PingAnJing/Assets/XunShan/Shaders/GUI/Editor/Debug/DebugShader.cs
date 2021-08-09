using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;

namespace ShaderEditor
{
    /// <summary>
    /// 通用Debug数据
    /// </summary>
    public class DebugShader : DebugData<DebugShader>
    {
        [SerializeField]
        private SavedFloat s_HeatMaxValue;
        public static float HeatMaxValue
        {
            get { return get.s_HeatMaxValue.value; }
            set
            {
                get.s_HeatMaxValue.value = Mathf.Max(0.0f, value);
            }
        }

        protected override void OnEnable()
        {
            base.OnEnable();

            string k_KeyPrefix = PlayerSettings.productName + "ShaderEditor:DebugShader:";

            s_HeatMaxValue = new SavedFloat($"{k_KeyPrefix}.HeatMaxValue", 2.0f);
        }
    }
}

