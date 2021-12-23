using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class RotateSeeker : MonoBehaviour
{

	public float Speed = 20.0f;
	Transform trans;

    // Start is called before the first frame update
    void Start()
    {
        trans = GetComponent<Transform>();
    }

    // Update is called once per frame
    void Update()
    {
        trans.Rotate(0, Time.deltaTime * Speed, 0, Space.World);
    }
}
