using System.Collections;
using System.Collections.Generic;
using UnityEngine;


namespace ShaderLib
{
    public static class ShaderDefine
    {
        #region ObjectType

        /// <summary>
        /// 标识使用对象的Tag
        /// </summary>
        public const string TAG_OBJECT_TYPE = "ObjectType";
        public const string TAG_OBJECT_TYPE_PROP_ID = "ObjectType";

        /// <summary>
        /// 人物使用类型
        /// </summary>
        public const string OBJECT_TYPE_ACTOR = "Actor";
        public readonly static int OBJECT_TYPE_PROP_ID_ACTOR = Shader.PropertyToID("_ObjectType_Actor");

        /// <summary>
        /// 场景使用类型
        /// </summary>
        public const string OBJECT_TYPE_SCENEOBJ = "SceneObject";
        public readonly static int OBJECT_TYPE_PROP_ID_SCENEOBJ = Shader.PropertyToID("_ObjectType_SceneObject");

        #endregion
    }
}