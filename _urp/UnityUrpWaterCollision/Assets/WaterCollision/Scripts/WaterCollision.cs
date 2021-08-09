using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class WaterCollision : MonoBehaviour
{
    Vector3 lastPos = new Vector3(999, 999, 999);
    static Vector3 startPos = new Vector3(999, 999, 999);
    WaterManager waterManager;
    // Start is called before the first frame update
    void Start()
    {
        waterManager = GameObject.Find("Main Camera").GetComponent<WaterManager>();
    }

    // Update is called once per frame
    void Update()
    {

    }

    void OnTriggerEnter(Collider collider)
    {

        //Debug.Log("aaa");
        if (isCollision())
        {
            waterManager.ColliderWater(transform.position);

        }
        lastPos = transform.position;
    }

    void OnTriggerStay(Collider collider)
    {
        //Debug.Log("aaa2");
        if (isCollision())
        {
            waterManager.ColliderWater(transform.position);
        }
        lastPos = transform.position;
    }

    bool isCollision() {
        if (lastPos.Equals(startPos)) {
            return false;
        }
        else if (lastPos == transform.position)
        {
            return false;
        }
        return true;
    }
    
}
