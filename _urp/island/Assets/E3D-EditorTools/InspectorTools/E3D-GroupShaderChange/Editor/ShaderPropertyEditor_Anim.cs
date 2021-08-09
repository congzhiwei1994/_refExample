//******************************************************
//
//	File Name 	: 		ShaderPropertyEditor_Anim.cs
//	
//	Author  	:		dust Taoist

//	CreatTime   :		8/16/2019 18:30
//******************************************************
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;

[CustomEditor(typeof(GroupMatsControll_Anim))]
public class ShaderPropertyEditor_Anim : Editor
{

    private GroupMatsControll_Anim _self;
    private float tempParamValue;

    private void OnEnable()
    {
        Debug.Log("Focus");
        _self = (GroupMatsControll_Anim)target;
        _self.OnInit();
        tempParamValue = _self.parame_1;
    }
    private void OnDisable()
    {
        if (_self)
            _self.ClearData();

        Debug.Log("invisible");
    }

    public override void OnInspectorGUI()
    {
        base.OnInspectorGUI();

        if (_self && _self.parame_1 != tempParamValue)
        {
            _self.SetShaderPropertyValue();
        }
        EditorUtility.SetDirty(_self);
    }
}
