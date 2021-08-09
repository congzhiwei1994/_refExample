using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[CreateAssetMenu(menuName ="EjoyTA/PlayControllData")]
public class PlayControllsData : ScriptableObject
{
    public GameObject target;
    public GameObject camera;
    public PlayControllType playCtoType;
    public bool isPlaymaker;
}
