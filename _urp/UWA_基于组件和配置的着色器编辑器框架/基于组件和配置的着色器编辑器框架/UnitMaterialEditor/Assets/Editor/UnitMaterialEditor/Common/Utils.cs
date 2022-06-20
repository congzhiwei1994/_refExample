using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading;
using System.IO;
using System.Reflection;
using System.Runtime.InteropServices;
using UnityEngine;

namespace UME {

    public static class Utils {

        public static Type FindTypeInAssembly( String typeName, Assembly assembly = null ) {
            Type type = null;
            if ( assembly == null ) {
                type = Type.GetType( typeName, false );
            }
            if ( type == null && assembly != null ) {
                var types = assembly.GetTypes();
                for ( int j = 0; j < types.Length; ++j ) {
                    var b = types[ j ];
                    if ( b.FullName == typeName ) {
                        type = b;
                        break;
                    }
                }
            }
            if ( type == null ) {
                Debug.LogWarningFormat( "FindType( \"{0}\", \"{1}\" ) failed!",
                    typeName, assembly != null ? assembly.FullName : "--" );
            }
            return type;
        }

        public static Type FindType( String typeName, String assemblyName = null ) {
            Type type = null;
            try {
                if ( String.IsNullOrEmpty( assemblyName ) ) {
                    type = Type.GetType( typeName, false );
                }
                if ( type == null ) {
                    var asm = AppDomain.CurrentDomain.GetAssemblies();
                    for ( int i = 0; i < asm.Length; ++i ) {
                        var a = asm[ i ];
                        if ( String.IsNullOrEmpty( assemblyName ) || a.GetName().Name == assemblyName ) {
                            var types = a.GetTypes();
                            for ( int j = 0; j < types.Length; ++j ) {
                                var b = types[ j ];
                                if ( b.FullName == typeName ) {
                                    type = b;
                                    goto END;
                                }
                            }
                        }
                    }
                }
            } catch ( ReflectionTypeLoadException ex ) {
                foreach ( Exception inner in ex.LoaderExceptions ) {
                    Debug.LogError( inner.Message );
                }
            }
        END:
            if ( type == null ) {
                Debug.LogWarningFormat( "FindType( \"{0}\", \"{1}\" ) failed!",
                    typeName, assemblyName ?? String.Empty );
            }
            return type;
        }

        public static object RflxGetValue( String typeName, String memberName, String assemblyName = null ) {
            object value = null;
            var type = FindType( typeName, assemblyName );
            if ( type != null ) {
                var smembers = type.GetMembers( BindingFlags.Static | BindingFlags.Public | BindingFlags.NonPublic );
                for ( int i = 0, count = smembers.Length; i < count && value == null; ++i ) {
                    var m = smembers[ i ];
                    if ( ( m.MemberType == MemberTypes.Field || m.MemberType == MemberTypes.Property ) &&
                        m.Name == memberName ) {
                        var pi = m as PropertyInfo;
                        if ( pi != null ) {
                            value = pi.GetValue( null, null );
                        } else {
                            var fi = m as FieldInfo;
                            if ( fi != null ) {
                                value = fi.GetValue( null );
                            }
                        }
                    }
                }
            }
            if ( value == null ) {
                Debug.LogErrorFormat( "RflxGetValue( \"{0}\", \"{1}\", \"{2}\" ) failed!",
                    typeName, memberName, assemblyName ?? String.Empty );
            }
            return value;
        }

        public static bool RflxSetValue( String typeName, String memberName, object value, String assemblyName = null ) {
            var type = FindType( typeName, assemblyName );
            if ( type != null ) {
                var smembers = type.GetMembers( BindingFlags.Static | BindingFlags.Public | BindingFlags.NonPublic );
                for ( int i = 0; i < smembers.Length; ++i ) {
                    var m = smembers[ i ];
                    if ( ( m.MemberType == MemberTypes.Field || m.MemberType == MemberTypes.Property ) &&
                        m.Name == memberName ) {
                        var pi = m as PropertyInfo;
                        if ( pi != null ) {
                            pi.SetValue( null, value, null );
                            return true;
                        } else {
                            var fi = m as FieldInfo;
                            if ( fi != null ) {
                                if ( fi.IsLiteral == false && fi.IsInitOnly == false ) {
                                    fi.SetValue( null, value );
                                    return true;
                                } else {
                                    return false;
                                }
                            }
                        }
                    }
                }
            }
            Debug.LogErrorFormat( "RflxSetValue( \"{0}\", \"{1}\", {2}, \"{3}\" ) failed!",
                typeName, memberName, value != null ? value : "null", assemblyName ?? String.Empty );
            return false;
        }

        public static object RflxGetValue( Type type, String memberName ) {
            object value = null;
            if ( type != null ) {
                var smembers = type.GetMembers( BindingFlags.Static | BindingFlags.Public | BindingFlags.NonPublic );
                for ( int i = 0, count = smembers.Length; i < count && value == null; ++i ) {
                    var m = smembers[ i ];
                    if ( ( m.MemberType == MemberTypes.Field || m.MemberType == MemberTypes.Property ) &&
                        m.Name == memberName ) {
                        var pi = m as PropertyInfo;
                        if ( pi != null ) {
                            value = pi.GetValue( null, null );
                        } else {
                            var fi = m as FieldInfo;
                            if ( fi != null ) {
                                value = fi.GetValue( null );
                            }
                        }
                    }
                }
            }
            if ( value == null ) {
                Debug.LogErrorFormat( "RflxGetValue( \"{0}\", \"{1}\" ) failed!",
                    type != null ? type.FullName : "null", memberName );
            }
            return value;
        }

        public static bool RflxSetValue( Type type, String memberName, object value ) {
            if ( type != null ) {
                var smembers = type.GetMembers( BindingFlags.Static | BindingFlags.Public | BindingFlags.NonPublic );
                for ( int i = 0; i < smembers.Length; ++i ) {
                    var m = smembers[ i ];
                    if ( ( m.MemberType == MemberTypes.Field || m.MemberType == MemberTypes.Property ) &&
                        m.Name == memberName ) {
                        var pi = m as PropertyInfo;
                        if ( pi != null ) {
                            pi.SetValue( null, value, null );
                            return true;
                        } else {
                            var fi = m as FieldInfo;
                            if ( fi != null && fi.IsLiteral == false && fi.IsInitOnly == false ) {
                                fi.SetValue( null, value );
                                return true;
                            }
                        }
                    }
                }
            }
            Debug.LogErrorFormat( "RflxSetValue( \"{0}\", \"{1}\", {2} ) failed!",
                type != null ? type.FullName : "null", memberName, value != null ? value : "null" );
            return false;
        }

        public static object RflxStaticCall( String typeName, String funcName, object[] parameters = null, String assemblyName = null ) {
            var type = FindType( typeName, assemblyName );
            if ( type != null ) {
                var f = type.GetMethod( funcName, BindingFlags.NonPublic | BindingFlags.Public | BindingFlags.Static );
                if ( f != null ) {
                    var r = f.Invoke( null, parameters );
                    return r;
                }
            }
            Debug.LogErrorFormat( "RflxStaticCall( \"{0}\", \"{1}\", {2}, \"{3}\" ) failed!",
                typeName, funcName, parameters ?? new object[] { }, assemblyName ?? String.Empty );
            return null;
        }

        public static object RflxStaticCall( Type type, String funcName, object[] parameters = null ) {
            if ( type != null ) {
                var f = type.GetMethod( funcName, BindingFlags.NonPublic | BindingFlags.Public | BindingFlags.Static );
                if ( f != null ) {
                    var r = f.Invoke( null, parameters );
                    return r;
                }
            }
            Debug.LogErrorFormat( "RflxStaticCall( \"{0}\", \"{1}\", {2} ) failed!",
                type != null ? type.FullName : "null", funcName, parameters ?? new object[] { } );
            return null;
        }

    }
}
