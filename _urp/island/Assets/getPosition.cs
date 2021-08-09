using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class getPosition : MonoBehaviour
{
    Transform _myTransform;
    // Start is called before the first frame update
    void Start()
    {
        _myTransform = this.transform;
    }

    // Update is called once per frame
    void Update()
    {
        Shader.SetGlobalVector("_PlayPosition",_myTransform.position);



    }
}
