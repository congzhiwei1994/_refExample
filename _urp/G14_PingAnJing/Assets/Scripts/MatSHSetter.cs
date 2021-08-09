using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteAlways]
public class MatSHSetter : MonoBehaviour
{
    public TextAsset csvFile;
    public Matrix4x4 envSHR;
    public Matrix4x4 envSHG;
    public Matrix4x4 envSHB;

    static MaterialPropertyBlock s_MPB;

    private void OnEnable()
    {
        if(csvFile != null)
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
                    case "envSHB.row0": envSHB.SetRow(0, StringToVector4(_value));break;
                    case "envSHB.row1": envSHB.SetRow(1, StringToVector4(_value));break;
                    case "envSHB.row2": envSHB.SetRow(2, StringToVector4(_value));break;
                    case "envSHB.row3": envSHB.SetRow(3, StringToVector4(_value));break;


                    case "envSHG.row0": envSHG.SetRow(0, StringToVector4(_value)); break;
                    case "envSHG.row1": envSHG.SetRow(1, StringToVector4(_value)); break;
                    case "envSHG.row2": envSHG.SetRow(2, StringToVector4(_value)); break;
                    case "envSHG.row3": envSHG.SetRow(3, StringToVector4(_value)); break;

                    case "envSHR.row0": envSHR.SetRow(0, StringToVector4(_value)); break;
                    case "envSHR.row1": envSHR.SetRow(1, StringToVector4(_value)); break;
                    case "envSHR.row2": envSHR.SetRow(2, StringToVector4(_value)); break;
                    case "envSHR.row3": envSHR.SetRow(3, StringToVector4(_value)); break;
                }
                _line = _sr.ReadLine();
            }


            _sr.Close();
            _sr.Dispose();
        }
    }

    private void OnDisable()
    {
        var _renderers = this.GetComponentsInChildren<Renderer>();
        if (_renderers != null)
        {
            foreach(var _renderer in _renderers)
            {
                ClearRenderer(_renderer);
            }
        }
    }

    // Update is called once per frame
    void Update()
    {
        var _renderers = this.GetComponentsInChildren<Renderer>();
        if (_renderers != null)
        {
            foreach (var _renderer in _renderers)
            {
                SetRenderer(_renderer);
            }
        }
    }

    private void OnDrawGizmos()
    {
        //Gizmos.DrawRay(this.transform.position, (new Vector3(0.30802f, -0.44072f, -0.84314f).normalized));
        //var _light = Object.FindObjectOfType<Light>();
        //_light.transform.forward = new Vector3(0.30802f, -0.44072f, -0.84314f).normalized;

        //_light.transform.localToWorldMatrix.GetColumn(2);

        //Debug.Log(_light.transform.forward);
        //Debug.Log(_light.transform.localToWorldMatrix.GetColumn(2).normalized);
    }

    private void ClearRenderer(Renderer _renderer)
    {
        if (s_MPB == null)
        {
            s_MPB = new MaterialPropertyBlock();
        }
        s_MPB.Clear();
        _renderer.GetPropertyBlock(s_MPB);
        s_MPB.SetMatrix("_EnvSHR", Matrix4x4.identity);
        s_MPB.SetMatrix("_EnvSHG", Matrix4x4.identity);
        s_MPB.SetMatrix("_EnvSHB", Matrix4x4.identity);
        _renderer.SetPropertyBlock(s_MPB);
    }

    private void SetRenderer(Renderer _renderer)
    {
        if (s_MPB == null)
        {
            s_MPB = new MaterialPropertyBlock();
        }
        s_MPB.Clear();
        _renderer.GetPropertyBlock(s_MPB);
        s_MPB.SetMatrix("_EnvSHR", envSHR);
        s_MPB.SetMatrix("_EnvSHG", envSHG);
        s_MPB.SetMatrix("_EnvSHB", envSHB);
        _renderer.SetPropertyBlock(s_MPB);
    }

    private void GetKeyValue(string _line, out string _key, out string _value)
    {
        _key = string.Empty;
        _value = string.Empty;
        var _keyIndex = _line.IndexOf(',');
        if(_keyIndex != -1)
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
            if(_valueYinIndex < _valueDouIndex)
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
        if(_value.Length == 4)
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
