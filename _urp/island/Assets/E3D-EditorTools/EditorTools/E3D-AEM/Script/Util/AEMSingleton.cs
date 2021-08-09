using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class AEMSingleton<T>
{
    private static T _instance = default(T);
    public static T Instance
    {
        get
        {
            if (_instance == null)
            {
                _instance = (T)Activator.CreateInstance(typeof(T));
            }
            return _instance;
        }
    }

    public void DestroyInstance()
    {
        _instance = default(T);
    }
}
