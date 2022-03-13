using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class AutoPlayerPos : MonoBehaviour {

    public Transform player;

	// Use this for initialization
	void Start () {
		
	}
	
	// Update is called once per frame
	void Update () {
		
	}

    private void LateUpdate()
    {
        if (player == null) return;
        this.transform.position = player.position;
    }
}
