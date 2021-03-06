#version 330
uniform mat4 world;
uniform mat4 viewProj;
uniform vec2 scene_size;
uniform float sig_x;
uniform float sig_z;
in vec4 position;
in vec4 texcoord0;
out vec4 v_texture0;
out vec4 v_texture5;
out float cl_changed_sig_;
void main(){
vec4 local_0;
vec4 local_2;

// local_2、local_0：世界坐标
vec4 local_3 = (world * position);
(local_2 = local_3);
(local_0 = local_2);

// local_58：世界坐标
vec4 local_58;
(local_58 = local_0);

// local_106:屏幕坐标
vec4 local_106 = (viewProj * local_58);

// local_110:屏幕坐标
vec4 local_109 = vec4(0.0, 0.0, 0.001, 0.0);
vec4 local_110 = (local_106 + local_109);
(gl_Position = local_110);

// 
float local_148 = (0.0 + sig_x);
float local_149 = (0.0 + sig_z);
vec2 local_150 = vec2(local_148, local_149);
float local_151 = local_150.x;
float local_152 = local_150.y;

// local_153 = sig_x + sig_z
float local_153 = (local_151 + local_152);

// local_154:世界坐标x值
float local_154 = local_0.x;

// local_156:世界坐标z值
float local_156 = local_0.z;

// local_158: sig_x + sig_z + 世界坐标x值
float local_158 = (local_153 + local_154);

// local_159: sig_x + sig_z + 世界坐标x值 + 世界坐标z值
float local_159 = (local_158 + local_156);
float local_160 = step(0.0, local_159);
(cl_changed_sig_ = local_160);

// uv
float local_161;
(local_161 = 0.0);
vec2 local_175 = texcoord0.xy;
vec4 local_178 = vec4(local_175.x, local_175.y, 1.0, local_161);
(v_texture0 = local_178);

// 
float local_179 = local_58.x;
float local_180 = local_58.y;
float local_181 = local_58.z;
float local_183 = scene_size.x;
float local_184 = scene_size.y;

// local_190: 顶点与场景的相对坐标（0.0 - 1.0）
float local_185 = (local_179 / local_183);
float local_187 = (local_185 + 0.5);
float local_188 = (local_181 / local_184);
float local_189 = (local_188 + 0.5);
vec2 local_190 = vec2(local_187, local_189);

// local_195:顶点与场景的相对高度（0.0 - 1.0）
float local_193 = (local_180 / 135.0);
float local_194 = clamp(local_193, 0.0, 1.0);
float local_195 = (1.0 - local_194);

float local_196;
(local_196 = 1.0);
vec4 local_201 = vec4(local_190.x, local_190.y, local_195, 0.0);
(v_texture5 = local_201);
}
