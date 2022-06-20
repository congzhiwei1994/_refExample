using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace UME {

    public class GlobalBuffer<T> : List<T>, IDisposable {

        const int MaxStackSize = 16;
        const int MaxCapacity = 256;

        static List<GlobalBuffer<T>> _poolOnStack = new List<GlobalBuffer<T>>();

#if UNITY_EDITOR
        static int _allocNumOnStack = 0;
        String _stackInfo = String.Empty;
#endif
        bool _dispose = false;


        GlobalBuffer()
            : base() {
        }

        public static void ClearAll() {
            lock ( _poolOnStack ) {
                _poolOnStack.Clear();
                _poolOnStack.TrimExcess();
            }
        }

        public static GlobalBuffer<T> Get() {
            lock ( _poolOnStack ) {
                GlobalBuffer<T> ret = null;
                var last = _poolOnStack.Count - 1;
                if ( last >= 0 ) {
                    ret = _poolOnStack[ last ];
                    _poolOnStack.RemoveAt( last );
                    ret._dispose = false;
                } else {
                    ret = new GlobalBuffer<T>();
                }
#if UNITY_EDITOR
                System.Threading.Interlocked.Increment( ref _allocNumOnStack );
#endif
                return ret;
            }
        }

        public void Dispose() {
            try {
                if ( _dispose ) {
                    return;
                }
                _dispose = true;
                Clear();
            } finally {
#if UNITY_EDITOR
                System.Threading.Interlocked.Decrement( ref _allocNumOnStack );
#endif
                lock ( _poolOnStack ) {
                    if ( _poolOnStack.Count > 0 && this.Capacity > MaxCapacity ) {
                        this.Capacity = MaxCapacity;
                    }
                    if ( _poolOnStack.Count < MaxStackSize ) {
                        _poolOnStack.Add( this );
                    } else {
#if UNITY_EDITOR
                        UnityEngine.Debug.LogError( "GlobalBuffer stack overflow!" );
#endif
                    }
                }
            }
        }

        public List<T> ToList() {
            var count = Count;
            var ret = new List<T>( count );
            for ( int i = 0; i < count; ++i ) {
                ret.Add( base[ i ] );
            }
            return ret;
        }

        public List<T> CopyTo( List<T> _out ) {
            if ( _out != null ) {
                _out.Clear();
                for ( int i = 0; i < Count; ++i ) {
                    _out.Add( base[ i ] );
                }
            }
            return _out;
        }
    }
}
