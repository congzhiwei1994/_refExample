using UnityEngine;namespace UnityEditor{

    internal class SSS_Water_MaterialEditor : ShaderGUI    {        Material material;

        #region Tabs
        private bool DiffuseTab        {            get { return EditorPrefs.GetBool("DiffuseTab" + material.name, false); }            set { EditorPrefs.SetBool("DiffuseTab" + material.name, value); }        }        private bool BumpTab        {            get { return EditorPrefs.GetBool("BumpTab" + material.name, false); }            set { EditorPrefs.SetBool("BumpTab" + material.name, value); }        }        private bool TransparencyTab        {            get { return EditorPrefs.GetBool("TransparencyTab" + material.name, false); }            set { EditorPrefs.SetBool("TransparencyTab" + material.name, value); }        }

        private bool SpecularTab
        {
            get { return EditorPrefs.GetBool("SpecularTab" + material.name, false); }
            set { EditorPrefs.SetBool("SpecularTab" + material.name, value); }
        }


        private bool FlowTab
        {
            get { return EditorPrefs.GetBool("FlowTab" + material.name, false); }
            set { EditorPrefs.SetBool("FlowTab" + material.name, value); }
        }


        private bool ProfileTab
        {
            get { return EditorPrefs.GetBool("ProfileTab" + material.name, false); }
            set { EditorPrefs.SetBool("ProfileTab" + material.name, value); }
        }


        private bool FogTab
        {
            get { return EditorPrefs.GetBool("FogTab" + material.name, false); }
            set { EditorPrefs.SetBool("FogTab" + material.name, value); }
        }










        #endregion
        #region ShaderProperties        MaterialProperty _Color = null;        MaterialProperty _BumpMap = null;        MaterialProperty _BumpScale = null;        MaterialProperty _BumpTile = null;        MaterialProperty _ChromaticAberration = null;        MaterialProperty TransparencyDistortion = null;        MaterialProperty _TintColor = null;        MaterialProperty SSS_TRANSPARENCY = null;        MaterialProperty _SpecColor = null;
        MaterialProperty _Gloss = null;
        MaterialProperty _ProfileColor = null;
        MaterialProperty _FlowMap = null;
        MaterialProperty _FlowSpeed = null;
        MaterialProperty _FlowIntensity = null;
        //MaterialProperty _Pan = null;
        MaterialProperty _PanU = null;
        MaterialProperty _PanV = null;
        MaterialProperty _FlowTile = null;
        MaterialProperty _FogColor = null;
        MaterialProperty _Density = null;
        MaterialProperty DEBUG_NORMALS = null;
        MaterialProperty _FadeDistance = null;
        MaterialProperty _FadeContrast = null;
        MaterialProperty _TintFade = null;

        #endregion
        MaterialEditor m_MaterialEditor;        bool m_FirstTimeApply = true;


        public void FindProperties(MaterialProperty[] properties)        {
            _Color = FindProperty("_Color", properties);            _BumpMap = FindProperty("_BumpMap", properties);            _BumpScale = FindProperty("_BumpScale", properties);            _ChromaticAberration = FindProperty("_ChromaticAberration", properties);            TransparencyDistortion = FindProperty("TransparencyDistortion", properties);            _TintColor = FindProperty("_TintColor", properties);            SSS_TRANSPARENCY = FindProperty("SSS_TRANSPARENCY", properties);
            _SpecColor = FindProperty("_SpecColor", properties);            _Gloss = FindProperty("_Glossiness", properties);
            _ProfileColor = FindProperty("_ProfileColor", properties);
            _FlowMap = FindProperty("_FlowMap", properties);
            _FlowSpeed = FindProperty("_FlowSpeed", properties);
            _FlowIntensity = FindProperty("_FlowIntensity", properties);
            _PanU = FindProperty("_PanU", properties);
            _PanV = FindProperty("_PanV", properties);
            _BumpTile = FindProperty("_BumpTile", properties);
            _FlowTile = FindProperty("_FlowTile", properties);
            _FogColor = FindProperty("_FogColor", properties);
            _Density = FindProperty("_Density", properties);
            DEBUG_NORMALS = FindProperty("DEBUG_NORMALS", properties);
            _FadeDistance = FindProperty("_FadeDistance", properties);
            _FadeContrast = FindProperty("_FadeContrast", properties);
            _TintFade = FindProperty("_TintFade", properties);
        }


        void CreateFogPlane()
        {
            /*
                        if (FogShader != null && fogMaterial == null)
                            fogMaterial = new Material(FogShader);
                        else
                            Debug.Log("Assign the fog shader");*/

        }        SSS.SSS sss;        public override void OnGUI(MaterialEditor materialEditor, MaterialProperty[] properties)        {

            FindProperties(properties); // MaterialProperties can be animated so we do not cache them but fetch them every event to ensure animated values are updated correctly

            m_MaterialEditor = materialEditor;            material = materialEditor.target as Material;            if (m_FirstTimeApply)            {                if (GameObject.FindObjectOfType<SSS.SSS>())                {                    sss = GameObject.FindObjectOfType<SSS.SSS>();                    if (GameObject.FindObjectOfType<SSS.SSS>().enabled == false)                        Shader.EnableKeyword("SCENE_VIEW");                }                m_FirstTimeApply = false;            }            EditorGUI.BeginChangeCheck();            GUILayout.Space(10);






            #region Albedo            if (GUILayout.Button("Albedo", EditorStyles.toolbarButton))                DiffuseTab = !DiffuseTab;            if (DiffuseTab)            {                GUILayout.BeginVertical("box");                m_MaterialEditor.ShaderProperty(_Color, _Color.displayName);                GUILayout.EndVertical();            }

            #endregion
            #region Profile
            if (Shader.IsKeywordEnabled("SSS_PROFILES") || material.IsKeywordEnabled("SSS_PROFILES"))
            {
                if (GUILayout.Button("Profile", EditorStyles.toolbarButton))
                    ProfileTab = !ProfileTab;

                if (ProfileTab)
                {

                    GUILayout.BeginVertical("box");
                    m_MaterialEditor.ShaderProperty(_ProfileColor, _ProfileColor.displayName);


                    GUILayout.EndVertical();
                }
            }
            #endregion

            #region Specular

            if (GUILayout.Button("Specular", EditorStyles.toolbarButton))
                SpecularTab = !SpecularTab;

            if (SpecularTab)
            {
                GUILayout.BeginVertical("box");
                GUILayout.BeginHorizontal();

                m_MaterialEditor.ShaderProperty(_SpecColor, _SpecColor.displayName);
                GUILayout.EndHorizontal();


                m_MaterialEditor.ShaderProperty(_Gloss, new GUIContent("Smoothness", ""));


                GUILayout.EndVertical();
            }

            #endregion

            #region Bump
            if (GUILayout.Button("Bump", EditorStyles.toolbarButton))                BumpTab = !BumpTab;            if (BumpTab)            {                GUILayout.BeginVertical("box");                m_MaterialEditor.TexturePropertySingleLine(new GUIContent(_BumpMap.displayName, ""), _BumpMap, _BumpScale);                m_MaterialEditor.ShaderProperty(_BumpTile, "Tiling");
                GUILayout.EndVertical();            }

            #endregion

            #region Flow
            if (GUILayout.Button("Flow", EditorStyles.toolbarButton))                FlowTab = !FlowTab;            if (FlowTab)            {                GUILayout.BeginVertical("box");                m_MaterialEditor.TexturePropertySingleLine(new GUIContent(_FlowMap.displayName, ""), _FlowMap, _FlowIntensity);
                m_MaterialEditor.ShaderProperty(_FlowTile, "Tiling");

                m_MaterialEditor.ShaderProperty(_FlowSpeed, _FlowSpeed.displayName);                m_MaterialEditor.ShaderProperty(_PanU, _PanU.displayName);                m_MaterialEditor.ShaderProperty(_PanV, _PanV.displayName);                m_MaterialEditor.ShaderProperty(DEBUG_NORMALS, DEBUG_NORMALS.displayName);
                GUILayout.EndVertical();            }

            #endregion
            #region Transparency            if (/*Shader.IsKeywordEnabled("SSS_TRANSPARENCY")*/ sss.bEnableTransparency)            {                if (GUILayout.Button("Transparency", EditorStyles.toolbarButton))                    TransparencyTab = !TransparencyTab;                if (TransparencyTab)                {                    GUILayout.BeginVertical("box");

                    //m_MaterialEditor.ShaderProperty(SSS_TRANSPARENCY, SSS_TRANSPARENCY.displayName);
                    //Debug.Log(material.IsKeywordEnabled("SSS_TRANSPARENCY"));
                    if (SSS_TRANSPARENCY.floatValue == 1)                    {
                        //material.EnableKeyword("SSS_TRANSPARENCY");
                        GUILayout.BeginVertical("box");                        if (_BumpMap.textureValue != null)                        {                            m_MaterialEditor.ShaderProperty(TransparencyDistortion, TransparencyDistortion.displayName);                            if (TransparencyDistortion.floatValue > 0)                                m_MaterialEditor.ShaderProperty(_ChromaticAberration, _ChromaticAberration.displayName);                        }
                        //m_MaterialEditor.ShaderProperty(TransparencyAlphaTweak, TransparencyAlphaTweak.displayName);
                        m_MaterialEditor.ShaderProperty(_TintColor, _TintColor.displayName);
                        m_MaterialEditor.ShaderProperty(_TintFade, _TintFade.displayName);
                        m_MaterialEditor.ShaderProperty(_FadeDistance, _FadeDistance.displayName);
                        m_MaterialEditor.ShaderProperty(_FadeContrast, _FadeContrast.displayName);
                        //m_MaterialEditor.ShaderProperty(_TintColor, TransparencyAlphaTweak.displayName);

                        GUILayout.EndVertical();                    }
                    //else
                    //material.DisableKeyword("SSS_TRANSPARENCY");


                    GUILayout.EndVertical();                }            }




            //else
            //material.DisableKeyword("SSS_TRANSPARENCY");
            #endregion
            #region Fog
            if (GUILayout.Button("Fog", EditorStyles.toolbarButton))                FogTab = !FogTab;            if (FogTab)            {                GUILayout.BeginVertical("box");
                {
                    // FogShader = (Shader)EditorGUILayout.ObjectField("Fog shader", FogShader, typeof(Shader), false);
                    //  FogMaterial = (Material)EditorGUILayout.ObjectField("Fog Material", FogMaterial, typeof(Material), false);

                    /* GUILayout.BeginHorizontal();
                     {
                       /*  if (GUILayout.Button("Create fog plane", EditorStyles.miniButton, GUILayout.MaxWidth(100))
                             && FogShader != null)
                             CreateFogPlane();

                         if (GUILayout.Button("Delete fog plane", EditorStyles.miniButton, GUILayout.MaxWidth(100)))
                             FogMaterial = null;


                     }
                     GUILayout.EndHorizontal();*/
                    m_MaterialEditor.ShaderProperty(_FogColor, _FogColor.displayName);
                    m_MaterialEditor.ShaderProperty(_Density, _Density.displayName);
                }
                GUILayout.EndVertical();            }

            #endregion




            m_MaterialEditor.EnableInstancingField();        }    }}