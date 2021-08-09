#version 330
uniform vec4 FogColor;
uniform float AlphaMtl;
uniform vec4 fow_color;
uniform vec4 changed_color;
uniform vec4 pickcolor;
uniform float adjust_multi;
uniform float adjust_area;
uniform float adjust_alpha;
uniform float scene_illum;
uniform sampler2D sam_diffuse_0;
uniform sampler2D sam_fow_3;
in vec4 v_texture0;
in vec4 v_texture5;
in float cl_changed_sig_;
out vec4 gFragColor;
void main(){
float sam_diffuse_0_bias = 0.0;
float sam_fow_3_bias = 0.0;
vec3 local_0;
float local_1;
vec3 local_15;

// local_0:����ɫ
vec3 local_18 = FogColor.xyz;
(local_15 = local_18);
(local_0 = local_15);

(local_1 = 0.5);

// local_122:����ͼ��ɫ
vec2 local_21 = v_texture0.xy;
vec4 local_23 = texture(sam_diffuse_0, local_21, sam_diffuse_0_bias);
vec4 local_24;
(local_24 = local_23);
vec4 local_122;
(local_122 = local_24);

float local_133;
(local_133 = cl_changed_sig_);

vec3 local_135;
float local_136;

// local_138: baseColor.r
float local_138 = local_122.x;

// local_139: baseColor.g
float local_139 = local_122.y;

// local_142: 2 * baseColor.g - baseColor.r;
float local_141 = (2.0 * local_139);
float local_142 = (local_141 - local_138);

// local_144: baseColor.b
float local_144 = local_122.z;

// local_146 = 2 * baseColor.g - baseColor.r - baseColor.b
float local_146 = (local_142 - local_144);
float local_147 = (local_146 + adjust_area);
(local_136 = local_147);
float local_174 = (local_136 * adjust_alpha);
float local_175 = clamp(local_174, 0.0, 1.0);
float local_177 = (local_175 * 2.0);

// local_183:
vec3 local_178 = local_122.xyz;
vec3 local_180 = changed_color.xyz;
vec3 local_182 = (local_178 * local_180);
vec3 local_183 = (local_182 * adjust_multi);

float local_184 = (local_133 * local_177);
vec3 local_185 = vec3(local_184, local_184, local_184);
vec3 local_186 = mix(local_178, local_183, local_185);
(local_135 = local_186);
vec3 local_189 = (local_135 * local_0);

// ������ͼ
vec3 local_190;
vec2 local_191 = v_texture5.xy;
vec4 local_193 = texture(sam_fow_3, local_191, sam_fow_3_bias);

// local_194:�Ƿ�������
float local_194 = local_193.x;
float local_198 = (1.0 - local_194);
float local_200 = (local_198 + 0.5);
float local_201 = (local_198 + 0.5);
float local_202 = (local_200 * local_201);
float local_203 = (local_202 - 0.5);
float local_204 = clamp(local_203, 0.0, 1.0);
float local_206 = fow_color.w;
float local_207 = (local_204 * local_206);

vec3 local_211 = vec3(0.0, 0.168, 0.29800001);
float local_214 = mix(0.64999998, 1.0, local_1);
float local_216 = v_texture5.z;
float local_218 = (local_214 * local_216);
vec3 local_219 = vec3(local_218, local_218, local_218);
vec3 local_220 = mix(local_189, local_211, local_219);

vec3 local_221 = vec3(local_207, local_207, local_207);
vec3 local_222 = mix(local_189, local_220, local_221);
(local_190 = local_222);
vec3 local_223;
(local_223 = local_190);
vec3 local_241;
(local_241 = local_223);

vec3 local_252 = (local_241 * scene_illum);
float local_254 = local_122.w;
float local_255 = (local_254 * AlphaMtl);
vec4 local_256 = vec4(local_252.x, local_252.y, local_252.z, local_255);
vec4 local_257 = (local_256 * pickcolor);
(gFragColor = local_257);
}
