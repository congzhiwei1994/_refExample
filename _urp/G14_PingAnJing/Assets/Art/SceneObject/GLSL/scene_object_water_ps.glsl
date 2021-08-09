#version 330
uniform vec4 fow_color;
uniform vec4 gradient_color;
uniform float normal_factor;
uniform float diff_tiling;
uniform float wave_factor;
uniform float nov_factor1;
uniform float nov_factor2;
uniform float water_alpha;
uniform float reflect_factor;
uniform vec4 WaterColor;
uniform vec4 FogColor;
uniform vec4 cam_pos;
uniform sampler2D sam_diffuse_0;
uniform sampler2D sam_other0_1;
uniform sampler2D sam_other1_2;
uniform sampler2D sam_fow_3;
in vec4 uv01;
in vec4 v_texture2;
in vec2 v_texture3;
in vec2 v_texture4;
in vec3 v_texture5;
in vec3 new_binormal;
in vec3 vertex_normal_world;
in vec4 v_texture8;
out vec4 gFragColor;
void main(){
float sam_other0_1_bias = -1.0;
float sam_other1_2_bias = -1.0;
float sam_diffuse_0_bias = -0.5;
float sam_fow_3_bias = 0.0;
vec4 local_0 = texture(sam_other0_1, v_texture3, sam_other0_1_bias);
vec4 local_1 = texture(sam_other0_1, v_texture4, sam_other0_1_bias);

// local_8:wave0.xy
vec2 local_2 = local_0.xy;
vec2 local_5 = (local_2 * 2.0);
vec2 local_7 = vec2(1.0, 1.0);
vec2 local_8 = (local_5 - local_7);

// local_13:wave1.xy
vec2 local_9 = local_1.xy;
vec2 local_11 = (local_9 * 2.0);
vec2 local_12 = vec2(1.0, 1.0);
vec2 local_13 = (local_11 - local_12);

float local_14 = local_8.x;
float local_15 = local_8.y;
float local_16 = (local_14 * normal_factor);
vec3 local_17 = vec3(local_16, local_16, local_16);
vec3 local_18 = (v_texture5 * local_17);
float local_19 = (local_15 * normal_factor);
vec3 local_20 = vec3(local_19, local_19, local_19);
vec3 local_21 = (new_binormal * local_20);
vec3 local_22 = (local_18 + local_21);
vec3 local_23 = (local_22 + vertex_normal_world);
vec3 local_24 = normalize(local_23);

float local_25 = local_13.x;
float local_26 = local_13.y;
float local_27 = (local_25 * normal_factor);
vec3 local_28 = vec3(local_27, local_27, local_27);
vec3 local_29 = (v_texture5 * local_28);
float local_30 = (local_26 * normal_factor);
vec3 local_31 = vec3(local_30, local_30, local_30);
vec3 local_32 = (new_binormal * local_31);
vec3 local_33 = (local_29 + local_32);
vec3 local_34 = (local_33 + vertex_normal_world);
vec3 local_35 = normalize(local_34);

// local_38:wave
vec3 local_37 = vec3(0.5, 0.5, 0.5);
vec3 local_38 = mix(local_24, local_35, local_37);

// local_44:相机到顶点方向
vec3 local_39 = cam_pos.xyz;
vec3 local_41 = v_texture2.xyz;
vec3 local_43 = (local_39 - local_41);
vec3 local_44 = normalize(local_43);

// local_50:specular
vec3 local_45 = vec3(wave_factor, wave_factor, wave_factor);
vec3 local_46 = mix(vertex_normal_world, local_38, local_45);
float local_47 = dot(local_44, local_46);
float local_48 = clamp(local_47, 0.0, 1.0);
float local_49 = smoothstep(nov_factor1, nov_factor2, local_48);
float local_50 = (1.0 - local_49);

// local_57:反射贴图
vec3 local_51 = (local_44 + local_38);
vec3 local_52 = vec3(1.0, 1.0, 1.0);
vec3 local_53 = (local_51 + local_52);
vec3 local_54 = (local_53 * 0.5);
vec2 local_55 = local_54.xy;
vec4 local_57 = texture(sam_other1_2, local_55, sam_other1_2_bias);

// local_80: base * fogcolor
vec2 local_58 = uv01.xy;
vec2 local_60 = (local_58 * diff_tiling);
vec4 local_61 = texture(sam_diffuse_0, local_60, sam_diffuse_0_bias);
vec3 local_62;
vec3 local_76 = FogColor.xyz;
(local_62 = local_76);
vec3 local_78 = local_61.xyz;
vec3 local_80 = (local_78 * local_62);

vec3 local_81 = WaterColor.xyz;
float local_83 = (local_50 * water_alpha);
vec3 local_84 = vec3(local_83, local_83, local_83);
vec3 local_85 = mix(local_80, local_81, local_84);

vec3 local_86 = local_57.xyz;
vec3 local_88 = (local_86 * 0.5);
float local_89 = (reflect_factor + local_50);
vec3 local_90 = (local_88 * local_89);
vec3 local_91 = (local_85 + local_90);
float local_92;
(local_92 = 1.0);
vec3 local_96;

// 迷雾贴图
vec2 local_97 = v_texture8.xy;
vec4 local_99 = texture(sam_fow_3, local_97, sam_fow_3_bias);

float local_100 = local_99.x;
float local_104 = (1.0 - local_100);
float local_107 = smoothstep(0.23100001, 0.76899999, local_104);
float local_109 = fow_color.w;
float local_110 = (local_107 * local_109);
vec3 local_114 = vec3(0.0, 0.168, 0.29800001);
vec3 local_115 = gradient_color.xyz;
float local_118 = v_texture8.z;
vec3 local_120 = vec3(local_118, local_118, local_118);
vec3 local_121 = mix(local_114, local_115, local_120);
vec3 local_122 = vec3(local_110, local_110, local_110);
vec3 local_123 = mix(local_91, local_121, local_122);
(local_96 = local_123);
vec3 local_124;
(local_124 = local_96);
vec4 local_142 = vec4(local_124.x, local_124.y, local_124.z, 1.0);
(gFragColor = local_142);
}
