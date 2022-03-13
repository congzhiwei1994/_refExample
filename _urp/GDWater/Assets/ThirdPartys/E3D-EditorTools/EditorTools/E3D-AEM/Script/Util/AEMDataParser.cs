using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class AEMDataParser
{
    private string _DataPath = string.Empty;
    private List<string> _DataHeader = new List<string>();
    private List<List<string>> _Data = new List<List<string>>();

    public int Col = 0;
    public int Row = 0;
    public AEMDataParser(string datPath)
    {
        _DataPath = datPath;
    }

    public bool Parse()
    {
        Object obj = Resources.Load(_DataPath);
        TextAsset binAsset = obj as TextAsset;

        if (binAsset == null)
        {
            return false;
        }
        string strVal = binAsset.text.Replace("\r\n", "\r");

        string[] lines = strVal.Split('\r');
        if (lines.Length > 0)
        {
            //_DataHeader = new List<string>(lines[0].Split('\t'));
            _DataHeader = new List<string>();
            _DataHeader.Add("GameObject");
            _DataHeader.Add("Mesh");
            _DataHeader.Add("Position");
            _DataHeader.Add("Rotation");
        }
        for (int i = 1; i < lines.Length; ++i)
        {
            List<string> col = new List<string>(lines[i].Split('\t'));
            _Data.Add(col);
        }
        if (_Data.Count > 0)
            _Data.RemoveAt(_Data.Count - 1);
        Col = _DataHeader.Count;
        Row = _Data.Count;
        return true;
    }

    public string GetData(int row, int col)
    {
        if (row >= Row)
        {
            return "";
        }
        List<string> rowData = _Data[row];
        if (col >= rowData.Count)
        {
            return "";
        }
        return rowData[col];
    }

    public string GetData(int row, string name)
    {
        int col = _DataHeader.IndexOf(name);
        if (col < 0)
        {
            return "";
        }
        return GetData(row, col);
    }
}
