using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;

namespace ShaderEditor
{
    public interface IProperties
    {

    }

    public static class PropertyHelper
    {
        static Dictionary<System.Type, System.Reflection.FieldInfo[]> s_CachedIPropertiesFieldInfo = new Dictionary<System.Type, System.Reflection.FieldInfo[]>();
        static Dictionary<System.Type, System.Reflection.FieldInfo[]> s_CachedFieldInfo = new Dictionary<System.Type, System.Reflection.FieldInfo[]>();
        static HashSet<MaterialProperty> s_TempMaterialPropertyHash = new HashSet<MaterialProperty>();

        public static void DrawUncatchMaterialProperty(BaseShaderGUI _baseGUI, MaterialEditor materialEditor, MaterialProperty[] _allProperties)
        {
            s_TempMaterialPropertyHash.Clear();

            var _GUIType = _baseGUI.GetType();
            System.Reflection.FieldInfo[] _GUIFields;
            if (!s_CachedFieldInfo.TryGetValue(_GUIType, out _GUIFields))
            {
                List<System.Reflection.FieldInfo> _TempGUIFields = new List<System.Reflection.FieldInfo>();
                var _fields = _GUIType.GetFields(System.Reflection.BindingFlags.NonPublic | System.Reflection.BindingFlags.Instance);
                for (int _i = 0; _i < _fields.Length; ++_i)
                {
                    var _field = _fields[_i];
                    var _fieldType = _field.FieldType;
                    if (!typeof(IProperties).IsAssignableFrom(_fieldType))
                    {
                        continue;
                    }
                    _TempGUIFields.Add(_field);
                }
                _GUIFields = _TempGUIFields.ToArray();
                s_CachedFieldInfo.Add(_GUIType, _GUIFields);
            }
            for (int _i = 0; _i < _GUIFields.Length; ++_i)
            {
                var _field = _GUIFields[_i];
                var _fieldType = _field.FieldType;
                var _FieldObj = _field.GetValue(_baseGUI);
                if(_FieldObj == null)
                {
                    continue;
                }

                System.Reflection.FieldInfo[] _IPropertiesFields;
                if(!s_CachedIPropertiesFieldInfo.TryGetValue(_fieldType, out _IPropertiesFields))
                {
                    List<System.Reflection.FieldInfo> _TempIPropertiesFields = new List<System.Reflection.FieldInfo>();
                    var _materialPropertyFields = _fieldType.GetFields(System.Reflection.BindingFlags.Public | System.Reflection.BindingFlags.Instance);
                    for (int _j = 0; _j < _materialPropertyFields.Length; ++_j)
                    {
                        var _propertyField = _materialPropertyFields[_j];
                        var _propertyFieldType = _propertyField.FieldType;
                        if (_propertyFieldType != (typeof(MaterialProperty)))
                        {
                            continue;
                        }
                        _TempIPropertiesFields.Add(_propertyField);
                    }
                    _IPropertiesFields = _TempIPropertiesFields.ToArray();
                    s_CachedIPropertiesFieldInfo.Add(_fieldType, _IPropertiesFields);
                }

                for(int _j = 0; _j < _IPropertiesFields.Length; ++_j)
                {
                    var _propertyField = _IPropertiesFields[_j];
                    var _propertyFieldObj = _propertyField.GetValue(_FieldObj) as MaterialProperty;
                    if(_propertyFieldObj == null)
                    {
                        continue;
                    }
                    s_TempMaterialPropertyHash.Add(_propertyFieldObj);
                }
            }


            for(int _i = 0; _i < _allProperties.Length; ++_i)
            {
                var _property = _allProperties[_i];
                if((_property.flags & MaterialProperty.PropFlags.HideInInspector) != 0)
                {
                    continue;
                }
                if (s_TempMaterialPropertyHash.Contains(_property))
                {
                    continue;
                }

                materialEditor.ShaderProperty(_property, _property.displayName);
            }

            s_TempMaterialPropertyHash.Clear();
        }
    }
}