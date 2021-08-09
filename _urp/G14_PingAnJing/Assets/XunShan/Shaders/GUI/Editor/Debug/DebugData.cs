using System.Collections;
using System.Collections.Generic;
using UnityEngine;


namespace ShaderEditor
{
    /// <summary>
    /// Debug数据基类
    /// </summary>
    /// <typeparam name="T"></typeparam>
    public abstract class DebugData<T> : ScriptableObject where T : ScriptableObject
    {
        protected static T get
        {
            get
            {
                if (!s_Get)
                {
                    s_Get = ScriptableObject.CreateInstance<T>();
                    s_Get.hideFlags = HideFlags.HideAndDontSave;
                }
                return s_Get;
            }
        }
        static T s_Get;

        protected virtual void OnEnable()
        {
            UnityEngine.Debug.Assert(this is T);
            s_Get = this as T;
        }
    }
   
}