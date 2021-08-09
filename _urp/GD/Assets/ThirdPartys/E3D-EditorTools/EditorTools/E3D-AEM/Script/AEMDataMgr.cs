using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class FileDataParser
{
    private AEMDataParser _parser;
    private List<string> _keyCache = new List<string>();

    public bool Parse(string strFile, string key)
    {
        _parser = new AEMDataParser(strFile);
        if (!_parser.Parse())
        {
            return false;
        }
        for (int row = 0; row < _parser.Row; ++row)
        {
            _keyCache.Add(_parser.GetData(row, key));
        }
        return true;
    }

    public List<string> GetListValue(string strKey)
    {
        List<string> tempList = new List<string>();
        if (strKey != "")
        {
            for (int i = 0; i < _keyCache.Count; i++)
            {
                tempList.Add(_parser.GetData(i, strKey));
            }
            return tempList;
        }
        else
        {
            for (int i = 0; i < _keyCache.Count; i++)
            {
                tempList.Add(_keyCache[i]);
            }
            return tempList;
        }
    }
}

public class AEMDataMgr : AEMSingleton<AEMDataMgr>
{
    private FileDataParser _DataParser = new FileDataParser();

    public bool finish = false;


    public AEMDataMgr()
    {

    }

    public void Initialize(string path, string key)
    {
        FileDataParser ps = new FileDataParser();
        if (ps.Parse(path, key))
        {
            _DataParser = ps;
            finish = true;
        }
        else
        {
            finish = false;
        }
    }
    public List<string> GetExcelListData(string strFileName, string strColKey)
    {
        return _DataParser.GetListValue(strColKey);
    }
    //=========================================================//
}
