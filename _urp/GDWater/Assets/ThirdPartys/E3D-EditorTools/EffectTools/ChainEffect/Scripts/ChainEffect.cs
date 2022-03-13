using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;

namespace E3DChain {
    [AddComponentMenu("Effect/ChainEffect")]
    [ExecuteInEditMode]
    [RequireComponent(typeof(MeshRenderer))]
    public class ChainEffect : MonoBehaviour {
        public ChainEffectRoot pChainEffectRoot;
        private MaterialPropertyBlock _mpb;

        [SerializeField]
        private bool _autoSegment = false;
        public bool AutoSegment {
            get { return _autoSegment;  }
            set {
                _autoSegment = value;
                UpdateLineRenderers();
            }
        }

        [SerializeField]
        private int _segment = 1;
        public int Segment {
            get { return _segment;  }
            set {
                _segment = Mathf.Clamp(value, 1, 100);
                UpdateLineRenderers();
            }
        }

        [SerializeField]
        private float _autoSegmentLength = 2f;
        public float AutoSegmentLength {
            get { return _autoSegmentLength;  }
            set {
                _autoSegmentLength = Mathf.Max(0.01f, value);
                UpdateLineRenderers();
            }
        }

        [SerializeField]
        private bool _randomShift = false;
        public bool RandomShift {
            get { return _randomShift; }
            set {
                _randomShift = value;
                _UpdateShift();
                _UpdatePositions();
            }
        }

        [SerializeField]
        private float _randomShiftLength = 0.5f;
        public float RandomShiftLength {
            get { return _randomShiftLength; }
            set {
                _randomShiftLength = Mathf.Max(0, value);
                _UpdateShift();
                _UpdatePositions();
            }
        }

        [SerializeField]
        private float _randomShiftTime = 0.1f;
        public float RandomShiftTime {
            get { return _randomShiftTime; }
            set {
                _randomShiftTime = Mathf.Max(0.01f, value);
                _UpdateShift();
                _UpdatePositions();
            }
        }

        [SerializeField]
        private float _chainWidth = 1f;
        public float ChainWidth {
            get { return _chainWidth; }
            set {
                _chainWidth = value;
                for (int i = 0; i < _lineRenderers.Count; ++i) {
                    _lineRenderers[i].SetWidth(_chainWidth, _chainWidth);
                }
            }
        }

        private float _shiftTimer = 0;
        private MeshRenderer _meshRender;
        private bool _hasInit = false;

        private List<LineRenderer> _lineRenderers = new List<LineRenderer>();

        private Transform _cacheTransform;

        void Start() {
            _cacheTransform = transform;

            _InitMeshRender();

            UpdateLineRenderers();

            _mpb = new MaterialPropertyBlock();

#if UNITY_EDITOR
            if (pChainEffectRoot == null) {

                ChainEffectRoot root = null;
                var parent = _cacheTransform.parent;
                if (parent != null) {
                    root = parent.GetComponent<ChainEffectRoot>();
                } else {
                    root = gameObject.GetComponent<ChainEffectRoot>();
                }

                if (root != null) {
                    pChainEffectRoot = root;
                }
            }
#endif
        }

        void Update() {
            if (!pChainEffectRoot) {
                return;
            }

            if (_randomShift && Application.isPlaying) {
                _shiftTimer -= Time.deltaTime;
                if (_shiftTimer < 0) {
                    _UpdateShift();
                    _shiftTimer = _randomShiftTime;
                }
            }

            _UpdatePositions();
            _UpdateMaterial();
        }

        void OnDestroy() {
            _ClearLineRenderers();
        }

        public void UpdateLineRenderers() {
            if (!Application.isPlaying) {
                return;
            }

            _ClearLineRenderers();

            if (pChainEffectRoot == null) {
                return;
            }

            var chainFrom = pChainEffectRoot.ChainFrom;
            var chainTo = pChainEffectRoot.ChainTo;

            if (chainFrom == null || chainTo == null) {
                return;
            }

            Material mat = _meshRender.sharedMaterial;

            var from = chainFrom.position;
            var to = chainTo.position;
            var dist = Vector3.Distance(from, to);

            int seg = _autoSegment ? Mathf.CeilToInt(dist / _autoSegmentLength) : _segment;

            for (int i = 0; i < seg; ++i) {
                GameObject go = new GameObject("Seg" + i);
                go.transform.SetParent(_cacheTransform);
                go.transform.localPosition = Vector3.zero;
                go.hideFlags = HideFlags.DontSave;

                var lr = go.AddComponent<LineRenderer>();
                lr.SetWidth(_chainWidth, _chainWidth);
                lr.shadowCastingMode = UnityEngine.Rendering.ShadowCastingMode.Off;
                lr.receiveShadows = false;
                lr.useLightProbes = false;
                lr.sharedMaterial = mat;

                lr.SetVertexCount(2);

                _lineRenderers.Add(lr);

                if (RandomShift && _lineRenderers.Count < seg) {
                    var r = Random.insideUnitCircle * _randomShiftLength;
                    lr.transform.localPosition = new Vector3(r.x, r.y);
                }
            }
        }

        void _InitMeshRender() {
            _meshRender = GetComponent<MeshRenderer>();
            _meshRender.enabled = false;
            _meshRender.shadowCastingMode = ShadowCastingMode.Off;
            _meshRender.receiveShadows = false;
            _meshRender.useLightProbes = false;
        }

        void _ClearLineRenderers() {
            for (int i = 0; i < _lineRenderers.Count; i++) {
                _Destroy(_lineRenderers[i].gameObject);
            }

            _lineRenderers.Clear();
        }

        void _UpdateShift() {
            int count = _lineRenderers.Count;
            for (int i = 0; i < count; i++) {
                if (_randomShift && i < count - 1) {
                    var r = Random.insideUnitCircle * _randomShiftLength;
                    _lineRenderers[i].transform.localPosition = new Vector3(r.x, r.y);
                } else {
                    _lineRenderers[i].transform.localPosition = Vector3.zero;
                }
            }
        }

        void _UpdatePositions() {
            if (pChainEffectRoot == null) {
                return;
            }

            var chainFrom = pChainEffectRoot.ChainFrom;
            var chainTo = pChainEffectRoot.ChainTo;

            if (chainFrom == null || chainTo == null) {
                return;
            }

            var ps = chainFrom.position;
            var pe = chainTo.position;
            var vec = pe - ps;

            var step = vec.normalized * (vec.magnitude / _lineRenderers.Count);
            var right = Vector3.Normalize(Vector3.Cross(step, Vector3.up));
            var up = Vector3.Normalize(Vector3.Cross(step, right));
            var p = ps;

            for (int i = 0; i < _lineRenderers.Count; i++) {
                var lr = _lineRenderers[i];
                var localPosition = lr.transform.localPosition;

                lr.SetPosition(0, p);
                p = ps + step * (i + 1) + right * localPosition.x + up * localPosition.y;
                lr.SetPosition(1, p);
            }
        }

        void _UpdateMaterial() {
            if (_meshRender == null) return;

            _meshRender.GetPropertyBlock(_mpb);
            for (int i = 0; i < _lineRenderers.Count; i++) {
                _lineRenderers[i].SetPropertyBlock(_mpb);
            }
        }

        void _Destroy(GameObject go) {
            if (Application.isPlaying) {
                Destroy(go);
            } else {
                DestroyImmediate(go);
            }
        }

    }

}