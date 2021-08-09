using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class DestoryByTime : MonoBehaviour
{
    public bool startActive = true;
    public float time = 5f;
    // Use this for initialization
    void Start()
    {
        if(startActive) Destroy(gameObject, time);
        //Destroy(gameObject);//删除挂载着脚本的游戏物体
        //Destroy(this);//移除脚本自身
        //Destroy(GetComponent<BoxCollider>());//移除游戏物体BoxCollider组件
        //Destroy(GetComponent<脚本类名>());//移除游戏物体上的脚本
    }
    public void ChangeDestroyTime(float time)
    {
        this.time = time;
    }

    public void StartActive()
    {
        startActive = true;
    }



    private void Update()
    {
        if (startActive) Destroy(gameObject, time);

        //减去时间增量
        //time -= Time.deltaTime;

        ////5秒结束
        //if (time <= 0f)
        //{
        //    Destroy(this.gameObject);
        //}
    }

    ////对象不可见时销毁对象
    //void OnBecameInvisible()
    //{
    //    Destroy(this.gameObject);
    //}
    ////对象发生碰撞
    //void OnCollisionStay( Collision collisionInfo)
    //{
    //    Destroy(this.gameObject);
    //}
}
