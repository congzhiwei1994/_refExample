using UnityEngine;
[CreateAssetMenu(menuName = "EjoyTA/PlayControll_RTS")]
public class RTSData : ScriptableObject
{
    public float moveSpeed = 10.0f;
    public float offSetAngle = 70.0f;
    public float rotateVminAngle = 0.0f;
    public float rotateVmaxAngle = 90.0f;
    /// <summary>
    /// 虚拟平面所在的高度--以世界坐标系为基准
    /// </summary>
    public float panelYValue = 0.0f;

    public float currentZoomDis = 10;
    public float zoomSpeed = 5.0f;
    /// <summary>
    /// 缩放每次增量值
    /// </summary>
    //public float zoomLerp = 1.0f;
    public float zoomMin = 5.0f;
    public float zoomMax = 30.0f;

    public float boundX = 20.0f;
    public float boundY = 40.0f;

    public void SetRTSData(float newMoveSpeed, float newOffSetAngle, float newRotateVminAngle, float newRotateVmaxAngle, float newPanelYValue,
                    float newCurrentZoomDis, float newZoomSpeed, float newZoomMin, float newZoomMax, float newBoundX, float newBoundY)
    {
        moveSpeed = newMoveSpeed;
        offSetAngle = newOffSetAngle;
        rotateVminAngle = newRotateVminAngle;
        rotateVmaxAngle = newRotateVmaxAngle;

        panelYValue = newPanelYValue;

        currentZoomDis = newCurrentZoomDis;
        zoomSpeed = newZoomSpeed;

        zoomMin = newZoomMin;
        zoomMax = newZoomMax;

        boundX = newBoundX;
        boundY = newBoundY;
    }
}
