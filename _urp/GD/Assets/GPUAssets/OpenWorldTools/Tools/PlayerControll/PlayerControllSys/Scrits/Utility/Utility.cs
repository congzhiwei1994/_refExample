using System.Collections.Generic;
using UnityEngine;
using UnityEngine.EventSystems;

/// <summary>
/// 常用辅助类
/// </summary>
public class Utility : MonoBehaviour
{ 
    /// <summary>
   /// 是否点击在UI上_
   /// </summary>
   /// <returns></returns>
    public static bool IsPointerOverUIObject()
    {
        if (EventSystem.current == null)
            return false;

        // Referencing this code for GraphicRaycaster https://gist.github.com/stramit/ead7ca1f432f3c0f181f
        // the ray cast appears to require only eventData.position.
        PointerEventData eventDataCurrentPosition = new PointerEventData(EventSystem.current);
        eventDataCurrentPosition.position = new Vector2(Input.mousePosition.x, Input.mousePosition.y);

        List<RaycastResult> results = new List<RaycastResult>();
        EventSystem.current.RaycastAll(eventDataCurrentPosition, results);

        return results.Count > 0;
    }


    public static float ClampAngle(float angle, float min, float max)
    {
        if (angle < -360)

            angle += 360;

        if (angle > 360)

            angle -= 360;

        return Mathf.Clamp(angle, min, max);
    }
}
