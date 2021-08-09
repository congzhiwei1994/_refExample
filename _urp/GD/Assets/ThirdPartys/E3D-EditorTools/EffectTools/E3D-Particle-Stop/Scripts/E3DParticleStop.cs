//******************************************************
//
//	File Name 	: 		E3DParticleStop.cs
//	
//	Author  	:		dust Taoist

//	CreatTime   :		12/27/2019 20:53
//******************************************************
using System.Collections;
using System.Collections.Generic;
using System.Reflection;
using UnityEngine;

public class E3DParticleStop : MonoBehaviour
{
    public bool destroy;
    [HideInInspector]
    public bool recover;
    [HideInInspector]
    public List<EffectParticles> resetQueue = new List<EffectParticles>();
    EffectParticles rt;
    int index = 0;
    public class EffectParticles
    {
        public ParticleSystem p;
        public float count;
    }

    void Start()
    {
        var array = GetComponentsInChildren<ParticleSystem>();
        for (int i = 0; i < array.Length; i++)
        {
            EffectParticles p = new EffectParticles();
            p.p = array[i];
            p.count = array[i].emission.rateOverTimeMultiplier;
            resetQueue.Add(p);
        }
    }

    void FixedUpdate()
    {
        if (destroy)
        {
            if (index < resetQueue.Count)
            {
                rt = resetQueue[index];
                System.Type type = rt.p.emission.GetType();
                PropertyInfo property = type.GetProperty("rateOverTimeMultiplier");
                property.SetValue(rt.p.emission, 0, null);
                index++;
            }
            else
            {
                destroy = false;
                index = 0;
            }
        }
        //=================================================//
        if (recover)
        {
            if (index < resetQueue.Count)
            {
                rt = resetQueue[index];
                System.Type type = rt.p.emission.GetType();
                PropertyInfo property = type.GetProperty("rateOverTimeMultiplier");
                property.SetValue(rt.p.emission, rt.count, null);
                index++;
            }
            else
            {
                recover = false;
                index = 0;
            }
        }
        //=================================================//
    }

    public void DestoryAfter()
    {
        destroy = true;
    }

    public void RecoverBefore()
    {
        recover = true;
    }
}
