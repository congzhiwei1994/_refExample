using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class AnimatorToggle : MonoBehaviour
{
    // Update is called once per frame
    void Update()
    {
        if (Input.GetKeyDown(KeyCode.Space)) ToggleAnimation();
    }

    public void ToggleAnimation()
    {
        Camera cam = Camera.main;
        Animator anim = cam.GetComponent<Animator>();
        SSS.ExplorationCamera explorationCamera = cam.GetComponent<SSS.ExplorationCamera>();
        
        if (explorationCamera != null)
            explorationCamera.enabled = !explorationCamera.enabled;
        else
            Debug.Log("Exploration camera component not found");

        anim.enabled = !anim.enabled;
    }
}
