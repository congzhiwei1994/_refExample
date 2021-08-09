#version 330
uniform float AlphaMtl;
uniform float Hero_Alpha_Random;
uniform float Support_Hero_Alpha;
uniform vec3 change_color;
uniform vec4 pickcolor;
uniform float discardAmount;
uniform sampler2D sam_diffuse_0;
in vec4 v_texture0;
out vec4 gFragColor;
void main(){
float sam_diffuse_0_bias = 0.0;
vec2 local_0 = v_texture0.xy;
vec4 local_2 = texture(sam_diffuse_0, local_0, sam_diffuse_0_bias);
float local_3;
float local_8 = local_2.w;
(local_3 = local_8);
if (((local_3 - discardAmount) < 0.0))
{
discard;
}
vec4 local_9;
vec4 local_12 = vec4(0.0, 0.0, 0.0, 0.0);
(local_9 = local_12);
vec4 local_13;
vec4 local_14;

// local_13: ÌùÍ¼ÑÕÉ«
(local_13 = local_2);
(local_14 = local_14);
vec4 local_111;

// local_125: ÌùÍ¼ÑÕÉ«
vec3 local_125 = local_13.xyz;

// local_176: ÌùÍ¼ÑÕÉ«
vec4 local_127 = vec4(local_125.x, local_125.y, local_125.z, local_3);
(local_111 = local_127);
vec4 local_128;
(local_128 = local_111);
vec4 local_141;
(local_141 = local_128);
vec4 local_151;
(local_151 = local_141);
vec4 local_176;
(local_176 = local_151);

// local_231:rgb local_232:a
vec4 local_205;
vec3 local_231 = local_176.xyz;
float local_232 = local_176.w;

// local_235.rgb = change_color * ÌùÍ¼ÑÕÉ«.rgb
vec3 local_233 = (change_color * local_231);
vec4 local_234 = vec4(local_233.x, local_233.y, local_233.z, local_232);
(local_205 = local_234);
vec3 local_235;
vec3 local_248 = local_205.xyz;
(local_235 = local_248);

// local_251:Í¸Ã÷¶È
float local_251 = local_205.w;
float local_252 = (local_251 * AlphaMtl);
float local_254 = step(1.0, local_252);
float local_255 = step(1.0, AlphaMtl);
float local_256 = mix(local_254, local_255, Support_Hero_Alpha);
float local_257 = mix(local_252, Hero_Alpha_Random, local_256);
vec4 local_258 = vec4(local_235.x, local_235.y, local_235.z, local_257);
vec4 local_259 = (local_258 * pickcolor);
(gFragColor = local_259);
}
