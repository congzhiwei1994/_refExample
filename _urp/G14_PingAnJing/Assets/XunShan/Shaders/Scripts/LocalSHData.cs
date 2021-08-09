using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;

namespace ShaderLib
{
    public class LocalSHData : ScriptableObject
    {
        [SerializeField]
        public SphericalHarmonicsL2 lightProbe;
        [SerializeField]
        public Vector4 occlusionProbe;
    }
}