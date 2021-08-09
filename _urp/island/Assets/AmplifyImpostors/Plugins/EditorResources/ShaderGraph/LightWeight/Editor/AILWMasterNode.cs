#if !UNITY_2019_1_OR_NEWER
using System;
using System.Linq;
using System.Collections.Generic;
using UnityEditor.Graphing;
using UnityEditor.ShaderGraph.Drawing;
using UnityEditor.ShaderGraph.Drawing.Controls;
using UnityEngine;
using UnityEngine.Experimental.UIElements;

namespace UnityEditor.ShaderGraph
{
    [Serializable]
    [Title("Master", "Amplify Impostor", "Bake LightWeight" )]
	public class AILWMasterNode : MasterNode<IAILWSubShader>, IMayRequirePosition, IMayRequireNormal
    {
        public const string AlphaClipThresholdSlotName = "Clip";
        public const string PositionName = "Position";
		public const string Buffer0SlotName = "Output0";
		public const string Buffer1SlotName = "Output1";
		public const string Buffer2SlotName = "Output2";
		public const string Buffer3SlotName = "Output3";
		public const string Buffer4SlotName = "Output4";
		public const string Buffer5SlotName = "Output5";
		public const string Buffer6SlotName = "Output6";
		public const string Buffer7SlotName = "Output7";

		public const int AlphaThresholdSlotId = 0;
        public const int PositionSlotId = 1;
		public const int Buffer0Id = 2;
		public const int Buffer1Id = 3;
		public const int Buffer2Id = 4;
		public const int Buffer3Id = 5;
		public const int Buffer4Id = 6;
		public const int Buffer5Id = 7;
		public const int Buffer6Id = 8;
		public const int Buffer7Id = 9;

		public enum Model
        {
            Specular,
            Metallic
        }

        [SerializeField]
        Model m_Model = Model.Metallic;

        public Model model
        {
            get { return m_Model; }
            set
            {
                if (m_Model == value)
                    return;

                m_Model = value;
                UpdateNodeAfterDeserialization();
                Dirty(ModificationScope.Topological);
            }
        }

        [SerializeField]
        SurfaceType m_SurfaceType;

        public SurfaceType surfaceType
        {
            get { return m_SurfaceType; }
            set
            {
                if (m_SurfaceType == value)
                    return;

                m_SurfaceType = value;
                Dirty(ModificationScope.Graph);
            }
        }

        [SerializeField]
        AlphaMode m_AlphaMode;

        public AlphaMode alphaMode
        {
            get { return m_AlphaMode; }
            set
            {
                if (m_AlphaMode == value)
                    return;

                m_AlphaMode = value;
                Dirty(ModificationScope.Graph);
            }
        }

        [SerializeField]
        bool m_TwoSided;

        public ToggleData twoSided
        {
            get { return new ToggleData(m_TwoSided); }
            set
            {
                if (m_TwoSided == value.isOn)
                    return;
                m_TwoSided = value.isOn;
                Dirty(ModificationScope.Graph);
            }
        }

        public AILWMasterNode()
        {
            UpdateNodeAfterDeserialization();
        }

        //public override string documentationURL
        //{
        //    get { return "https://github.com/Unity-Technologies/ShaderGraph/wiki/PBR-Master-Node"; }
        //}

        public sealed override void UpdateNodeAfterDeserialization()
        {
            base.UpdateNodeAfterDeserialization();
            name = "Amplify Impostor LW";
            AddSlot(new PositionMaterialSlot(PositionSlotId, PositionName, PositionName, CoordinateSpace.Object, ShaderStageCapability.Vertex));
			AddSlot(new Vector1MaterialSlot(AlphaThresholdSlotId, AlphaClipThresholdSlotName, AlphaClipThresholdSlotName, SlotType.Input, 1.0f, ShaderStageCapability.Fragment));
			AddSlot(new Vector4MaterialSlot(Buffer0Id, Buffer0SlotName, Buffer0SlotName, SlotType.Input, Vector4.zero, ShaderStageCapability.Fragment));
			AddSlot(new Vector4MaterialSlot(Buffer1Id, Buffer1SlotName, Buffer1SlotName, SlotType.Input, Vector4.zero, ShaderStageCapability.Fragment));
			AddSlot(new Vector4MaterialSlot(Buffer2Id, Buffer2SlotName, Buffer2SlotName, SlotType.Input, Vector4.zero, ShaderStageCapability.Fragment));
			AddSlot(new Vector4MaterialSlot(Buffer3Id, Buffer3SlotName, Buffer3SlotName, SlotType.Input, Vector4.zero, ShaderStageCapability.Fragment));
			AddSlot(new Vector4MaterialSlot(Buffer4Id, Buffer4SlotName, Buffer4SlotName, SlotType.Input, Vector4.zero, ShaderStageCapability.Fragment));
			AddSlot(new Vector4MaterialSlot(Buffer5Id, Buffer5SlotName, Buffer5SlotName, SlotType.Input, Vector4.zero, ShaderStageCapability.Fragment));
			AddSlot(new Vector4MaterialSlot(Buffer6Id, Buffer6SlotName, Buffer6SlotName, SlotType.Input, Vector4.zero, ShaderStageCapability.Fragment));
			AddSlot(new Vector4MaterialSlot(Buffer7Id, Buffer7SlotName, Buffer7SlotName, SlotType.Input, Vector4.zero, ShaderStageCapability.Fragment));

            // clear out slot names that do not match the slots
            // we support
            RemoveSlotsNameNotMatching(
                new[]
            {
                PositionSlotId,
				AlphaThresholdSlotId,
				Buffer0Id,
				Buffer1Id,
				Buffer2Id,
				Buffer3Id,
				Buffer4Id,
				Buffer5Id,
				Buffer6Id,
				Buffer7Id
			}, true);
        }

		protected override VisualElement CreateCommonSettingsElement()
		{
			return new AILWSettingsView( this );
		}

		public NeededCoordinateSpace RequiresNormal(ShaderStageCapability stageCapability)
        {
            List<MaterialSlot> slots = new List<MaterialSlot>();
            GetSlots(slots);

            List<MaterialSlot> validSlots = new List<MaterialSlot>();
            for (int i = 0; i < slots.Count; i++)
            {
                if (slots[i].stageCapability != ShaderStageCapability.All && slots[i].stageCapability != stageCapability)
                    continue;

                validSlots.Add(slots[i]);
            }
            return validSlots.OfType<IMayRequireNormal>().Aggregate(NeededCoordinateSpace.None, (mask, node) => mask | node.RequiresNormal(stageCapability));
        }

        public NeededCoordinateSpace RequiresPosition(ShaderStageCapability stageCapability)
        {
            List<MaterialSlot> slots = new List<MaterialSlot>();
            GetSlots(slots);

            List<MaterialSlot> validSlots = new List<MaterialSlot>();
            for (int i = 0; i < slots.Count; i++)
            {
                if (slots[i].stageCapability != ShaderStageCapability.All && slots[i].stageCapability != stageCapability)
                    continue;

                validSlots.Add(slots[i]);
            }
            return validSlots.OfType<IMayRequirePosition>().Aggregate(NeededCoordinateSpace.None, (mask, node) => mask | node.RequiresPosition(stageCapability));
        }
    }
}
#endif
