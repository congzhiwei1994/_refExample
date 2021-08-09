#version 330
uniform mat4 wvp;
uniform mat4 world;
uniform float pro_z_bias;
in vec4 texcoord0;
in vec4 position;
in vec4 normal;
out vec4 v_texture0;
void main(){
vec4 local_0;
vec4 local_1;
(local_0 = position);
(local_1 = normal);
vec4 local_432 = (wvp * local_0);
vec4 local_434 = vec4(0.0, 0.0, pro_z_bias, 0.0);
vec4 local_435 = (local_432 + local_434);
(gl_Position = local_435);
float local_551;
(local_551 = 0.0);
float local_565 = texcoord0.x;
float local_566 = texcoord0.y;
vec4 local_569 = vec4(local_565, local_566, 0.0, local_551);
(v_texture0 = local_569);
}
