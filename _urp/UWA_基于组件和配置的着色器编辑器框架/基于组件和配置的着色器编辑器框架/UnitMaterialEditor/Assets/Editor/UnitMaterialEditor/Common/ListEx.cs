using System;
using System.Collections.Generic;

namespace UME {

    public static class ListExtra {

        public static void Resize<T>( this List<T> list, int sz, T c ) {
            int cur = list.Count;
            if ( sz < cur ) {
                list.RemoveRange( sz, cur - sz );
            } else if ( sz > cur ) {
                //this bit is purely an optimisation, to avoid multiple automatic capacity changes.
                if ( sz > list.Capacity ) {
                    list.Capacity = sz;
                }
                int count = sz - cur;
                for ( int i = 0; i < count; ++i ) {
                    list.Add( c );
                }
            }
        }

        public static void Resize<T>( this List<T> list, int sz ) {
            Resize( list, sz, default( T ) );
        }

        public static int FindIndex<T, C>( this IList<T> list, C ctx, Func<T, C, bool> match ) {
            for ( int i = 0, count = list.Count; i < count; ++i ) {
                if ( match( list[ i ], ctx ) ) {
                    return i;
                }
            }
            return -1;
        }
    }
}
//EOF
