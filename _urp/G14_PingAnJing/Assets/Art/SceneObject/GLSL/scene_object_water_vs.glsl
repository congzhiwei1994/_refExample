#version 330
uniform vec2 scene_size;
uniform float u_UVTiling1;
uniform float u_UVTiling2;
uniform float u_uvSpeedU1;
uniform float u_uvSpeedV1;
uniform float u_uvSpeedU2;
uniform float u_uvSpeedV2;
uniform mat4 wvp;
uniform mat4 world;
uniform float FrameTime;
uniform mat4 texTrans0;
in vec4 texcoord0;
in vec4 position;
out vec4 uv01;
out vec4 v_texture2;
out vec2 v_texture3;
out vec2 v_texture4;
out vec3 v_texture5;
out vec3 new_binormal;
out vec3 vertex_normal_world;
out vec4 v_texture8;
void main(){
vec4 local_0 = (wvp * position);
(gl_Position = local_0);
vec2 local_1 = texcoord0.xy;
vec4 local_5 = vec4(local_1.x, local_1.y, 1.0, 0.0);
vec4 local_6 = (texTrans0 * local_5);

// local_7: 世界坐标
vec4 local_7 = (world * position);
(v_texture2 = local_7);

// local_11: 法线
mat3 local_8 = mat3(world);
vec3 local_9 = vec3(0.0, 1.0, 0.0);
vec3 local_10 = (local_8 * local_9);
vec3 local_11 = normalize(local_10);
(vertex_normal_world = local_11);

// local_14: 切线
vec3 local_12 = vec3(0.0, 0.0, 1.0);
vec3 local_13 = (local_8 * local_12);
vec3 local_14 = normalize(local_13);

// local_15:副法线
vec3 local_15 = cross(local_11, local_14);
(v_texture5 = local_14);
(new_binormal = local_15);

// local_20:世界坐标xz
float local_16 = local_7.x;
float local_18 = local_7.z;
vec2 local_20 = vec2(local_16, local_18);

vec2 local_22 = (local_20 * 0.001);
vec2 local_23 = vec2(u_UVTiling1, u_UVTiling1);
vec2 local_24 = (local_22 * local_23);
vec2 local_25 = vec2(FrameTime, FrameTime);
vec2 local_26 = vec2(u_uvSpeedU1, u_uvSpeedV1);
vec2 local_27 = (local_25 * local_26);
vec2 local_28 = (local_24 + local_27);

vec2 local_29 = (local_20 * 0.001);
vec2 local_30 = vec2(u_UVTiling2, u_UVTiling2);
vec2 local_31 = (local_29 * local_30);
vec2 local_32 = vec2(FrameTime, FrameTime);
vec2 local_33 = vec2(u_uvSpeedU2, u_uvSpeedV2);
vec2 local_34 = (local_32 * local_33);
vec2 local_35 = (local_31 + local_34);
(v_texture3 = local_28);
(v_texture4 = local_35);
vec2 local_36 = local_6.xy;

// uv
vec4 local_38 = vec4(local_36.x, local_36.y, 1.0, 0.0);
(uv01 = local_38);

// v_texture8:顶点与场景的相对坐标
float local_47 = scene_size.x;
float local_48 = scene_size.y;
float local_49 = (local_16 / local_47);
float local_51 = (local_49 + 0.5);
float local_52 = (local_18 / local_48);
float local_53 = (local_52 + 0.5);
vec2 local_54 = vec2(local_51, local_53);
float local_55;
(local_55 = 1.0);
vec4 local_60 = vec4(local_54.x, local_54.y, 0.0, 0.0);
(v_texture8 = local_60);
}
