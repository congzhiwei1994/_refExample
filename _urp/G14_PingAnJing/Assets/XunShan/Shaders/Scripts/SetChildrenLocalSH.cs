using System.Collections;
using System.Collections.Generic;
using UnityEngine;

namespace ShaderLib
{
    /// <summary>
    /// 设置子节点的Renderer SH数据
    /// </summary>
    public class SetChildrenLocalSH : MonoBehaviour
    {
        private readonly static List<Renderer> s_TempRenderer = new List<Renderer>();


        public enum ObjectType
        {
            None,
            Actor,
            SceneObject
        }
        private static int GetObjectTypeID(ObjectType type)
        {
            switch (type)
            {
                case ObjectType.Actor: return ShaderDefine.OBJECT_TYPE_PROP_ID_ACTOR;
                case ObjectType.SceneObject: return ShaderDefine.OBJECT_TYPE_PROP_ID_SCENEOBJ;
            }
            return 0;
        }


        public enum WhenSet
        {
            [InspectorName("手动")]
            Manual,

            [InspectorName("Start调用时")]
            Start,

            [InspectorName("每帧(性能消耗)")]
            EveryFrame,
        }

        /// <summary>
        /// 指定ObjectType
        /// </summary>
        [SerializeField]
        public ObjectType m_ObjectType;

        [SerializeField]
        public LocalSHData m_Data;

        [SerializeField]
        public WhenSet m_WhenSet;

        /// <summary>
        /// 是否自动设置LightProbe设置
        /// </summary>
        //[SerializeField]
        //public bool m_IsAutoSetLightProbeSetting;

        private Transform m_SelfTransform;
        private Transform SelfTransform
        {
            get
            {
                if(m_SelfTransform == null)
                {
                    m_SelfTransform = this.transform;
                }
                return m_SelfTransform;
            }
        }

        private void Start()
        {
            if(m_WhenSet == WhenSet.Start)
            {
                ApplyAll();
            }
        }

        private void Update()
        {
            if (m_WhenSet == WhenSet.EveryFrame)
            {
                ApplyAll();
            }
        }

        /// <summary>
        /// 遍历一次设置
        /// </summary>
        public void ApplyAll()
        {
            if(m_Data == null)
            {
                return;
            }
            s_TempRenderer.Clear();
            CollectAllRenderer(s_TempRenderer);
            if(s_TempRenderer.Count > 0)
            {
                for(int _i = 0; _i < s_TempRenderer.Count; ++_i)
                {
                    var renderer = s_TempRenderer[_i];
                    SetSingleLocalSH.ApplySHToRenderer(renderer, m_Data);
                }
                s_TempRenderer.Clear();
            }
        }

        public void ClearAll()
        {
            s_TempRenderer.Clear();
            CollectAllRenderer(s_TempRenderer);
            if (s_TempRenderer.Count > 0)
            {
                for (int _i = 0; _i < s_TempRenderer.Count; ++_i)
                {
                    var renderer = s_TempRenderer[_i];
                    SetSingleLocalSH.ClearSHToRenderer(renderer);
                }
                s_TempRenderer.Clear();
            }
        }

        /// <summary>
        /// 按类型过滤
        /// </summary>
        /// <param name="inoutList"></param>
        /// <param name="type"></param>
        private void FilterObjectType(List<Renderer> inoutList, ObjectType type)
        {
            int prop_id = GetObjectTypeID(type);
            for(int _i = inoutList.Count - 1; _i >= 0; --_i)
            {
                bool remove = true;
                var renderer = inoutList[_i];
                var _mat = renderer.sharedMaterial;
                if(_mat != null)
                {
                    if(_mat.HasProperty(prop_id))
                    {
                        remove = false;
                    }
                }

                if(remove)
                {
                    inoutList.RemoveAt(_i);
                }
            }
        }

        /// <summary>
        /// 收集所以设置的Renderer
        /// </summary>
        /// <param name="outList"></param>
        private void CollectAllRenderer(List<Renderer> outList)
        {
            if(SelfTransform == null)
            {
                return;
            }
            outList.Clear();
            SelfTransform.GetComponentsInChildren<Renderer>(true, outList);

            if(m_ObjectType != ObjectType.None)
            {
                FilterObjectType(outList, m_ObjectType);
            }
        }


       
    }
}