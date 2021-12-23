using System.Collections;
using System.Collections.Generic;
using UnityEngine;

namespace LuxLWRPEssentials.Demo {
	public class MouseSelect : MonoBehaviour {
		private Transform selectedTransform;
	    void Update() {
		    if (Input.GetMouseButtonDown(0)) {
		         
		        RaycastHit hitInfo = new RaycastHit();
		        bool hit = Physics.Raycast(Camera.main.ScreenPointToRay(Input.mousePosition), out hitInfo);
		        if (hit) {

		            if (selectedTransform != null) {
		             	var tg = selectedTransform.GetComponent<ToggleOutlineSelection>();
		             	if(tg != null) {
		             		tg.Select();
		             	}
		            }

		            if (selectedTransform != hitInfo.transform) {
		            	var tg = hitInfo.transform.GetComponent<ToggleOutlineSelection>();
		            	if(tg != null) {
		             		selectedTransform = hitInfo.transform;
		             		tg.Select();
		             	}
		             	else {
		             		selectedTransform = null;
		             	}
		            }

		            else {
		             	selectedTransform = null;
		            }
		        } 
		    } 
	  	}
	}
}