using System.Collections;
using System.Collections.Generic;
using UnityEngine;

namespace LuxLWRPEssentials.Demo {
    public class ToggleOutlineSelection : MonoBehaviour
    {
        public Material SelectionMaterial;
        public Material OutlineMaterial;

    	Renderer rend;
        Material[] BaseMatArray = new Material[1];
        Material[] SelectedMatArray = new Material[2];
        bool Selected = false;
    	
        void OnEnable()
        {
        	rend = GetComponent<Renderer>();
            BaseMatArray[0] = rend.sharedMaterials[0];
            SelectedMatArray[0] = SelectionMaterial;
            SelectedMatArray[1] = OutlineMaterial;
        }

        public void Select()
        {
        	if (!Selected) {
        		rend.sharedMaterials = SelectedMatArray;
                Selected = true;
        	}
        	else {
        		rend.sharedMaterials = BaseMatArray;
                Selected = false;
        	}
        }
    }
}