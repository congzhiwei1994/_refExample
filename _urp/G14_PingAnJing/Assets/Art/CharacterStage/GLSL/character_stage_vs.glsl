#version 330
uniform vec4 shadowShakeFrequency;
uniform vec4 shadowShakeAmplitude;
uniform float shadowShineFrequency;
uniform vec3 glowFactor;
uniform mat4 lvp;
uniform vec4 ShadowLightAttr[5];
uniform float frame_time;
uniform mat4 wvp;
uniform mat4 world;
uniform vec4 FogInfo;
in vec4 texcoord0;
in vec4 position;
out vec4 v_texture0;
out float v_texture1;
out float v_texture2;
out vec4 v_texture3;
out vec4 screenPos;
out vec4 v_world_pos_temp;
out vec4 v_shakeAmount_temp;
out vec2 v_shineAmount_temp;
out vec4 v_shakeAmount02_temp;
out float v_glowIntensity_temp;
void main(){
vec4 local_0 = (wvp * position);
(gl_Position = local_0);

// local_1:世界坐标
vec4 local_1 = (world * position);
(v_world_pos_temp = local_1);

// local_6:uv
vec2 local_2 = texcoord0.xy;
vec4 local_6 = vec4(local_2.x, local_2.y, 1.0, 0.0);
(v_texture0 = local_6);

// local_13:雾
float local_8 = local_1.y;
float local_11 = FogInfo.z;
float local_12 = FogInfo.w;
float local_13;
{
float local_15 = (local_12 - local_8);
float local_16 = (local_12 - local_11);
float local_17 = (local_15 / local_16);
float local_18 = clamp(local_17, 0.0, 1.0);
(local_13 = local_18);
}

float local_21 = local_0.z;
float local_24 = (15.0 * local_8);
float local_25 = (local_21 - local_24);
(v_texture1 = local_25);
float local_27 = (1.0 - local_13);
(v_texture2 = local_27);

// v_texture3:shadowmap空间坐标
vec4 local_29 = ShadowLightAttr[3];
vec3 local_32 = vec3(1.0, 0.0, 0.0);
vec3 local_33 = local_29.xyz;
vec2 local_35;
float local_36;
float local_37;
{
vec4 local_39 = (lvp * local_1);
vec3 local_40 = local_39.xyz;
float local_41 = local_39.w;
vec3 local_42 = vec3(local_41, local_41, local_41);
vec3 local_43 = (local_40 / local_42);
vec2 local_44 = local_43.xy;
float local_45 = local_43.z;
vec2 local_46;
vec2 local_48 = vec2(0.5, 0.5);
(local_46 = local_48);
vec2 local_52 = (local_44 * local_46);
vec2 local_54 = vec2(0.5, 0.5);
vec2 local_55 = (local_52 + local_54);
vec3 local_56 = (-local_32);
vec3 local_57 = normalize(local_33);
float local_58 = dot(local_56, local_57);
float local_59 = clamp(local_58, 0.0, 1.0);
(local_35 = local_55);
(local_36 = local_45);
(local_37 = local_59);
}
vec4 local_61 = vec4(local_35.x, local_35.y, local_36, local_37);
(v_texture3 = local_61);

(screenPos = local_0);
vec2 local_62;
vec2 local_63;
vec2 local_64;
vec2 local_65;
float local_66;
float local_67;
float local_68 = shadowShakeFrequency.x;
float local_69 = shadowShakeFrequency.y;
float local_70 = shadowShakeFrequency.z;

// local_82:两次sin叠加
float local_72 = (frame_time * local_68);
float local_73 = sin(local_72);
float local_75 = (frame_time * local_68);
float local_77 = (local_75 * 1.7);
float local_78 = (0.31999999 + local_77);
float local_79 = sin(local_78);
float local_81 = (local_79 * 0.37);
float local_82 = (local_73 + local_81);

// local_98:两次sin叠加
float local_84 = -1.3;
float local_86 = (frame_time * local_68);
float local_87 = (0.67000002 + local_86);
float local_88 = sin(local_87);
float local_89 = (local_84 * local_88);
float local_91 = (frame_time * local_68);
float local_93 = (local_91 * 1.37);
float local_94 = (1.0700001 + local_93);
float local_95 = sin(local_94);
float local_97 = (local_95 * 0.56999999);
float local_98 = (local_89 + local_97);

vec2 local_99 = vec2(local_82, local_98);
float local_100 = shadowShakeAmplitude.x;
float local_101 = shadowShakeAmplitude.y;
float local_102 = shadowShakeAmplitude.z;
vec2 local_104 = (local_99 * local_100);

// local_113:两次sin叠加
float local_105 = (frame_time * local_69);
float local_106 = sin(local_105);
float local_107 = (frame_time * local_69);
float local_109 = (local_107 * 2.7);
float local_110 = (0.31999999 + local_109);
float local_111 = sin(local_110);
float local_112 = (local_111 * 0.67000002);
float local_113 = (local_106 + local_112);

// local_128:两次sin叠加
float local_115 = -0.76999998;
float local_116 = (frame_time * local_69);
float local_117 = (0.76999998 + local_116);
float local_118 = sin(local_117);
float local_119 = (local_115 * local_118);
float local_121 = (frame_time * local_69);
float local_123 = (local_121 * 2.3699999);
float local_124 = (1.17 + local_123);
float local_125 = sin(local_124);
float local_127 = (local_125 * 0.47);
float local_128 = (local_119 + local_127);

vec2 local_129 = vec2(local_113, local_128);
vec2 local_130 = (local_129 * local_101);

// local_142:两次sin叠加
float local_132 = (frame_time * local_70);
float local_133 = sin(local_132);
float local_134 = (0.63999999 * local_133);
float local_136 = (frame_time * local_70);
float local_138 = (local_136 * 2.3);
float local_139 = (1.3200001 + local_138);
float local_140 = sin(local_139);
float local_141 = (local_140 * 0.56999999);
float local_142 = (local_134 + local_141);

// local_155:两次sin叠加
float local_144 = (frame_time * local_70);
float local_145 = (0.47 + local_144);
float local_146 = sin(local_145);
float local_147 = (1.1 * local_146);
float local_149 = (frame_time * local_70);
float local_151 = (local_149 * 1.87);
float local_152 = (1.77 + local_151);
float local_153 = sin(local_152);
float local_154 = (local_153 * 0.76999998);
float local_155 = (local_147 + local_154);

vec2 local_156 = vec2(local_142, local_155);
vec2 local_157 = (local_156 * local_102);

vec2 local_159 = vec2(0.0, 0.0);
float local_162 = (shadowShineFrequency * frame_time);
float local_163 = sin(local_162);
float local_164 = (1.0 + local_163);
float local_165 = (0.5 * local_164);
float local_166 = (shadowShineFrequency * frame_time);
float local_168 = (local_166 * 0.75999999);
float local_170 = (local_168 + 0.93000001);
float local_171 = sin(local_170);
float local_172 = (1.0 + local_171);
float local_173 = (0.5 * local_172);

(local_62 = local_104);
(local_63 = local_130);
(local_64 = local_157);
(local_65 = local_159);
(local_66 = local_165);
(local_67 = local_173);
float local_180;
float local_181 = glowFactor.x;
float local_182 = glowFactor.y;
float local_183 = glowFactor.z;
float local_185 = (frame_time * local_183);
float local_186 = sin(local_185);
float local_187 = (0.5 * local_186);
float local_188 = (0.5 + local_187);
float local_189 = mix(local_181, local_182, local_188);
(local_180 = local_189);

vec4 local_191 = vec4(local_62.x, local_62.y, local_63.x, local_63.y);
(v_shakeAmount_temp = local_191);
vec4 local_192 = vec4(local_64.x, local_64.y, local_65.x, local_65.y);
(v_shakeAmount02_temp = local_192);
vec2 local_193 = vec2(local_66, local_67);
(v_shineAmount_temp = local_193);
(v_glowIntensity_temp = local_180);
}
