using System.Collections;
using System.Collections.Generic;
using UnityEngine;

namespace LuxLWRPEssentials.Demo {
    public class AnimateSphere : MonoBehaviour
    {
        
    	Transform trans;
    	float yPos;

        // Start is called before the first frame update
        void Start()
        {
            trans = GetComponent<Transform>();
            yPos = trans.position.y;
        }

        // Update is called once per frame
        void Update()
        {
            var position = trans.position;
            position.y = yPos + Mathf.Sin(Time.time) * 2.0f;
            trans.position = position;
        }
    }
}