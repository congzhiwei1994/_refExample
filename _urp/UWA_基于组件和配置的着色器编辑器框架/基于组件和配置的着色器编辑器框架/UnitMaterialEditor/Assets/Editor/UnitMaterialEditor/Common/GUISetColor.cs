using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using UnityEngine;
using UnityEditor;

namespace UME {

    public struct GUISetColor : IDisposable {

        public GUISetColor( Color newColor ) {
            this.PreviousColor = GUI.color;
            GUI.color = newColor;
        }

        public void Dispose() {
            GUI.color = this.PreviousColor;
        }

        [SerializeField]
        private Color PreviousColor;
    }
}
//EOF
