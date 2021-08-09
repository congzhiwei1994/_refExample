using System.Collections;
using System.Collections.Generic;
using UnityEngine;


[ExecuteAlways]
public class LightSetter : MonoBehaviour
{
    public TextAsset csvFile;

    public Color color = Color.white;
    public Vector3 dir;

    private void OnEnable()
    {
        if (csvFile != null)
        {
            var allText = csvFile.text;
            System.IO.StringReader _sr = new System.IO.StringReader(allText);
            var _line = _sr.ReadLine();
            while (_line != null && !string.IsNullOrEmpty(_line))
            {
                //var _line_value = _line.Split(',');
                //var _key = _line_value[0];
                //var _value = _line_value[1];
                string _key;
                string _value;
                GetKeyValue(_line, out _key, out _value);
                switch (_key)
                {
                    case "ShadowLightAttr[3]": dir = StringToVector4(_value); break;
                    case "ShadowLightAttr[1]": color = StringToVector4(_value); break;
                }
                _line = _sr.ReadLine();
            }


            _sr.Close();
            _sr.Dispose();


        }

        SetLight(color, dir);
    }

    private void Update()
    {

        SetLight(color, dir);

    }

    private void SetLight(Color _color, Vector3 _dir)
    {
        var _light = GetComponent<Light>();
        if(_light != null)
        {
            _light.color = _color;
            _light.intensity = 1.0f;

            this.transform.forward = _dir;
        }
    }


    private void GetKeyValue(string _line, out string _key, out string _value)
    {
        _key = string.Empty;
        _value = string.Empty;
        var _keyIndex = _line.IndexOf(',');
        if (_keyIndex != -1)
        {
            _key = _line.Substring(0, _keyIndex);
        }
        else
        {
            return;
        }

        var _beginIndex = _keyIndex + 1;
        var _valueYinIndex = _line.IndexOf('"', _beginIndex);
        var _valueDouIndex = _line.IndexOf(',', _beginIndex);
        if (_valueYinIndex != -1)
        {
            if (_valueYinIndex < _valueDouIndex)
            {
                // 有双引
                var _valueLastYinIndex = _line.IndexOf('"', _valueYinIndex + 1);
                if (_valueLastYinIndex != -1)
                {
                    _value = _line.Substring(_valueYinIndex + 1, _valueLastYinIndex - _valueYinIndex);
                }
            }
            else
            {
                // 没有引号
                _value = _line.Substring(_beginIndex, _valueDouIndex - _beginIndex);
            }
        }
        else
        {
            // 没有引号
            _value = _line.Substring(_beginIndex, _valueDouIndex - _beginIndex);
        }
    }

    private Vector4 StringToVector4(string _str)
    {
        _str = _str.Trim('"');
        var _value = _str.Split(',');
        if (_value.Length == 4)
        {
            return new Vector4(
                System.Convert.ToSingle(_value[0]),
                System.Convert.ToSingle(_value[1]),
                System.Convert.ToSingle(_value[2]),
                System.Convert.ToSingle(_value[3])
                );
        }

        return Vector4.zero;
    }
}
