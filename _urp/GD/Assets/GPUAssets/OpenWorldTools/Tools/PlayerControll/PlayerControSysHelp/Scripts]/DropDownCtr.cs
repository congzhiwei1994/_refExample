using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;

public class DropDownCtr : MonoBehaviour
{
    public Dropdown _dropDown;
    public PlayControll_V1 _playControll;

	// Use this for initialization
	void Start ()
    {
        _dropDown.value = (int)_playControll.playControllType;

        _dropDown.onValueChanged.AddListener(delegate
            {
                 DropCallBack(_dropDown.value);
            }
        );
    }
    private void Update()
    {
        if (_playControll&&_playControll.playControllType != _playControll.LastPType)
        {
            _dropDown.value = (int)_playControll.playControllType;
        }
    }
    void DropCallBack(int index)
    {
        if (index == 0)
        {
            if (_playControll)
            {
                if (_playControll.playControllType != PlayControllType.TPS)
                {
                    _playControll.playControllType = PlayControllType.TPS;
                }
            }
        }
        else if (index == 1)
        {
            if (_playControll)
            {
                if (_playControll.playControllType != PlayControllType.FPS)
                {
                    _playControll.playControllType = PlayControllType.FPS;
                }
            }
        }
        else if (index == 2)
        {
            if (_playControll)
            {
                if (_playControll.playControllType != PlayControllType.LockCamera)
                {
                    _playControll.playControllType = PlayControllType.LockCamera;
                }
            }
        }
        else if (index == 3)
        {
            if (_playControll)
            {
                if (_playControll.playControllType != PlayControllType.RTS)
                {
                    _playControll.playControllType = PlayControllType.RTS;
                }
            }
        }         
    }
}
