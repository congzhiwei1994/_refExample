using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using UnityEngine;
using UnityEditor;

namespace UME {

    public struct GUISetEnabled : IDisposable {

        public GUISetEnabled( bool enabled ) {
            this.PreviousEnabled = GUI.enabled;
            GUI.enabled = enabled;
        }

        public void Dispose() {
            GUI.enabled = this.PreviousEnabled;
        }

        [SerializeField]
        private bool PreviousEnabled;
    }
}
//EOF
