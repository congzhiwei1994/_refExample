using UnityEngine;

namespace E3DChain {

	[System.Serializable]
	public class QualityBool {

		public int Mask = 0;

		public QualityBool() { }
		public QualityBool(int v) { Mask = v; }
		public QualityBool(bool v) { Mask = v ? int.MaxValue : 0; }

		public static implicit operator QualityBool(int v) {
			return new QualityBool(v);
		}

		public static implicit operator QualityBool(bool v) {
			return new QualityBool(v);
		}

		public static implicit operator bool(QualityBool qb) {
			return (QualitySettings.GetQualityLevel() & qb.Mask) != 0;
		}

	}

}