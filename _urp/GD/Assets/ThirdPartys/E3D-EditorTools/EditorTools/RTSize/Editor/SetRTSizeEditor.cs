using System.Collections;
using System.Collections.Generic;
using UnityEditor;
using UnityEngine;

[CustomEditor(typeof(SetRTSize), true)]
public class SetRTSizeEditor : Editor
{
    private SetRTSize _self;

    public void OnEnable()
    {
        _self = (SetRTSize)target;
    }

    public override void OnInspectorGUI()
    {
        base.OnInspectorGUI();
        if (GUILayout.Button("Set Size"))
        {
           if(_self.execute == false)
            {
                _self.execute = true;
            }
        }
    }
}
