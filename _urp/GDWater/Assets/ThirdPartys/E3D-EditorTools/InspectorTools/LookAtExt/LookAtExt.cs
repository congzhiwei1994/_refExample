using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
public class LookAtExt : MonoBehaviour
{
	public Transform target;
	void Update () {
		//=======================================================//
		//  transform.LookAt (target);
		//=======================================================//
		 var dir = target.position - transform.position;
		transform.rotation = Quaternion.LookRotation(dir);
		//=======================================================//
	}
}
