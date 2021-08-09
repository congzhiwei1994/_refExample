#version 330
uniform mat4 world;
uniform mat4 viewProj;
uniform float frame_time;
uniform vec4 wind_info;
uniform vec2 scene_size;
uniform float sig_x;
uniform float sig_z;
uniform float max_dist_factor;
uniform float act_factor;
uniform float wind_factor;
in vec4 position;
in vec4 texcoord0;
out vec4 v_texture0;
out vec4 v_texture5;
out float cl_changed_sig_;
void main(){

// local_0:世界坐标
vec4 local_0;
vec4 local_2;
vec4 local_3 = (world * position);
(local_2 = local_3);
(local_0 = local_2);
vec4 local_58;
float local_59;
(local_59 = 1.0);
float local_64 = (2.0 * frame_time);
float local_65 = sin(local_64);
float local_67 = -1.0;
float local_68 = -1.0;

// local_69 = -1.0
vec2 local_69 = vec2(local_67, local_68);

// local_70: sin(2.0 * frame_time)
vec2 local_70 = vec2(local_65, local_65);

// local_71: wind_factor * sin(2.0 * frame_time)
vec2 local_71 = (local_70 * wind_factor);
vec2 local_72 = (local_71 * local_69);
float local_73 = local_0.x;
float local_74 = local_0.y;
float local_75 = local_0.z;
float local_76 = local_0.w;

// local_84:摇摆力度
vec2 local_77 = vec2(local_73, local_75);
vec2 local_78 = wind_info.xy;
vec2 local_79 = wind_info.zw;
vec2 local_80 = (local_77 - local_78);
float local_81 = length(local_80);
float local_82 = (max_dist_factor - local_81);
float local_83 = (local_82 / max_dist_factor);
float local_84 = clamp(local_83, 0.0, 1.0);

// local_87: y * y * y * y
float local_85 = (local_59 * local_74);
float local_86 = (local_85 * local_85);
float local_87 = (local_86 * local_85);

// local_88:摇摆力度
float local_88 = (act_factor * local_84);

// local_91：顶点受风的偏移值(y轴越大，受风影响最大)
vec2 local_89 = (local_88 * local_79);
vec2 local_90 = (local_89 + local_72);
vec2 local_91 = (local_87 * local_90);

// local_92: y * y
float local_92 = (local_85 * local_85);
float local_93 = local_91.x;
float local_94 = local_91.y;

// local_96 = y * y - 偏移值x
float local_95 = (local_93 * local_93);
float local_96 = (local_92 - local_95);

// local_98 = y * y - 偏移值x - 偏移值y
float local_97 = (local_94 * local_94);
float local_98 = (local_96 - local_97);
float local_99 = sqrt(local_98);
float local_100 = sign(local_85);
float local_101 = (local_99 * local_100);
float local_102 = (local_73 + local_93);
float local_103 = (local_59 * local_101);
float local_104 = (local_75 + local_94);

// local_58: 风吹的世界坐标
vec4 local_105 = vec4(local_102, local_103, local_104, local_76);
(local_58 = local_105);
vec4 local_106 = (viewProj * local_58);
vec4 local_109 = vec4(0.0, 0.0, 0.001, 0.0);
vec4 local_110 = (local_106 + local_109);
(gl_Position = local_110);

// 
float local_148 = (0.0 + sig_x);
float local_149 = (0.0 + sig_z);
vec2 local_150 = vec2(local_148, local_149);
float local_151 = local_150.x;
float local_152 = local_150.y;
float local_153 = (local_151 + local_152);
float local_154 = local_0.x;
float local_156 = local_0.z;
float local_158 = (local_153 + local_154);
float local_159 = (local_158 + local_156);
float local_160 = step(0.0, local_159);
(cl_changed_sig_ = local_160);
float local_161;
(local_161 = 0.0);
vec2 local_175 = texcoord0.xy;
vec4 local_178 = vec4(local_175.x, local_175.y, 1.0, local_161);
(v_texture0 = local_178);
float local_179 = local_58.x;
float local_180 = local_58.y;
float local_181 = local_58.z;
float local_183 = scene_size.x;
float local_184 = scene_size.y;
float local_185 = (local_179 / local_183);
float local_187 = (local_185 + 0.5);
float local_188 = (local_181 / local_184);
float local_189 = (local_188 + 0.5);
vec2 local_190 = vec2(local_187, local_189);
float local_193 = (local_180 / 135.0);
float local_194 = clamp(local_193, 0.0, 1.0);
float local_195 = (1.0 - local_194);
float local_196;
(local_196 = 1.0);
vec4 local_201 = vec4(local_190.x, local_190.y, local_195, 0.0);
(v_texture5 = local_201);
}
