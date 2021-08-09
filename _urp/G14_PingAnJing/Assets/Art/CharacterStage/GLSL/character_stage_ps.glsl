#version 330
uniform float shadow_density;
uniform float shadow_alpha;
uniform vec4 shadow_color01;
uniform vec4 shadow_color02;
uniform vec2 shadow_color_trans;
uniform vec2 shadowClination;
uniform vec4 shadowPosFactor01;
uniform vec4 glowPosFactor01;
uniform vec2 glowDiffFactor;
uniform vec4 glowColor;
uniform vec2 glowPosBias;
uniform vec4 u_shadowmap_info;
uniform vec2 shadow_bias_factor;
uniform vec4 FogColor;
uniform vec4 FogInfo;
uniform float HeightFogDensity;
uniform float AlphaMtl;
uniform vec4 ambient_color;
uniform sampler2D sam_diffuse_0;
uniform sampler2D sam_other1_2;
uniform sampler2DShadow sam_shadow_4;
in vec4 v_texture0;
in float v_texture1;
in float v_texture2;
in vec4 v_texture3;
in vec4 screenPos;
in vec4 v_world_pos_temp;
in vec4 v_shakeAmount_temp;
in vec2 v_shineAmount_temp;
in vec4 v_shakeAmount02_temp;
in float v_glowIntensity_temp;
out vec4 gFragColor;
void main(){

// local_241:主贴图颜色
float sam_diffuse_0_bias = -0.5;
float sam_other1_2_bias = -1.0;
vec2 local_0 = v_texture0.xy;
vec4 local_2 = texture(sam_diffuse_0, local_0, sam_diffuse_0_bias);
vec4 local_3;
(local_3 = local_2);
vec4 local_241;
float local_242;
(local_241 = local_3);
(local_242 = 1.0);

// local_277 :阴影值
float local_277;
float local_278;
{
float local_280 = shadow_bias_factor.x;
float local_281 = shadow_bias_factor.y;
float local_284 = v_texture3.w;
float local_285 = (1.0 - local_284);
float local_286 = (local_280 * local_285);
float local_287 = (local_286 + local_281);
float local_289 = clamp(local_287, 0.0, 1.0);
vec2 local_290 = v_texture3.xy;
float local_293 = v_texture3.z;
float local_295 = (local_293 - local_289);
float local_296;
float local_298 = (local_295 * 0.5);
float local_299 = (local_298 + 0.5);
(local_296 = local_299);
float local_300;
vec4 local_308 = vec4(local_290.x, local_290.y, local_296, 1.0);
float local_309 = textureProj(sam_shadow_4, local_308);
(local_300 = local_309);
float local_310 = local_290.x;
float local_311 = local_290.y;
float local_312 = (1.0 - local_310);
float local_313 = (1.0 - local_311);
vec4 local_314 = vec4(local_310, local_312, local_311, local_313);
vec4 local_315 = sign(local_314);
vec4 local_317 = vec4(1.0, 1.0, 1.0, 1.0);
float local_318 = dot(local_315, local_317);
float local_319 = step(3.5, local_318);
float local_320 = (1.0 - local_319);
float local_321 = (local_300 + local_320);
float local_322 = clamp(local_321, 0.0, 1.0);
(local_278 = local_322);
}
(local_277 = local_278);

float local_325;
vec2 local_327 = vec2(0.5, 0.5);
float local_328 = v_world_pos_temp.x;
float local_329 = v_world_pos_temp.y;
float local_330 = v_world_pos_temp.z;

// local_332:世界坐标xz
vec2 local_332 = vec2(local_328, local_330);
float local_334 = -0.70999998;
float local_336 = -45.529999;
vec2 local_337 = vec2(local_334, local_336);

// local_338:xz - (-0.70999998, -45.529999)
vec2 local_338 = (local_332 - local_337);
vec2 local_339 = shadowPosFactor01.xy;
vec2 local_340 = shadowPosFactor01.zw;
vec2 local_341 = (local_338 * local_339);
vec2 local_342 = (local_327 + local_341);
vec2 local_343 = (local_342 + local_340);
float local_345 = (local_329 - 4.6999998);
vec2 local_346 = (shadowClination * local_345);
vec2 local_347 = (local_343 + local_346);

vec2 local_348 = v_shakeAmount_temp.xy;
vec2 local_349 = v_shakeAmount_temp.zw;
vec2 local_350 = (local_347 + local_348);
vec4 local_351 = texture(sam_other1_2, local_350, sam_other1_2_bias);
float local_352 = local_351.x;

vec2 local_356 = (local_347 + local_348);
vec2 local_357 = (local_356 + local_349);
vec4 local_358 = texture(sam_other1_2, local_357, sam_other1_2_bias);
float local_360 = local_358.y;

vec2 local_362 = (local_347 + local_348);
vec2 local_363 = v_shakeAmount02_temp.xy;
vec2 local_365 = (local_362 + local_363);
vec4 local_366 = texture(sam_other1_2, local_365, sam_other1_2_bias);
float local_368 = local_366.y;

float local_371 = v_shineAmount_temp.x;
float local_372 = v_shineAmount_temp.y;
float local_373 = mix(local_360, 1.0, local_371);
float local_374 = mix(local_368, 1.0, local_372);
float local_375 = min(local_277, local_352);
float local_376 = min(local_373, local_375);
float local_377 = min(local_374, local_376);
(local_325 = local_377);

// local_386:xz
float local_378;
float local_379;
vec2 local_381 = vec2(0.5, 0.5);
float local_382 = v_world_pos_temp.x;
float local_383 = v_world_pos_temp.y;
float local_384 = v_world_pos_temp.z;
vec2 local_386 = vec2(local_382, local_384);
float local_388 = -0.70999998;
float local_390 = -45.529999;
vec2 local_391 = vec2(local_388, local_390);
vec2 local_392 = (local_386 - local_391);
vec2 local_393 = glowPosFactor01.xy;
vec2 local_395 = (local_392 * local_393);
vec2 local_396 = (local_381 + local_395);
vec2 local_397 = (local_396 + glowPosBias);
float local_399 = (local_383 - 4.6999998);
vec2 local_400 = (shadowClination * local_399);
vec2 local_401 = (local_397 + local_400);

vec2 local_402 = v_shakeAmount_temp.xy;
vec2 local_403 = v_shakeAmount_temp.zw;
vec2 local_404 = (local_402 + local_403);
vec2 local_405 = v_shakeAmount02_temp.xy;
vec2 local_407 = (local_404 + local_405);
float local_409 = glowPosFactor01.z;
vec2 local_411 = (local_407 * local_409);
vec2 local_412 = (local_401 + local_411);
vec4 local_413 = texture(sam_other1_2, local_412, sam_other1_2_bias);
float local_415 = local_413.z;

float local_418 = (local_415 * 2.0);
float local_420 = (local_418 - 1.0);
float local_421 = clamp(local_420, 0.0, 1.0);

float local_422 = (local_415 * 2.0);
float local_423 = clamp(local_422, 0.0, 1.0);

// local_430:灰度
vec3 local_427 = vec3(0.30000001, 0.58999997, 0.11);
vec3 local_428 = local_241.xyz;
float local_430 = dot(local_427, local_428);

float local_431 = (local_325 * local_421);
float local_432 = glowDiffFactor.x;
float local_433 = glowDiffFactor.y;
float local_434 = smoothstep(local_432, local_433, local_430);
float local_435 = (local_431 * local_434);
float local_436;
(local_436 = local_435);
float local_443 = min(local_325, local_423);

// local_378: glow
(local_378 = local_436);

// local_379:shadow
(local_379 = local_443);

float local_445 = local_241.x;
float local_446 = local_241.y;
float local_447 = local_241.z;
float local_448 = local_241.w;
float local_449 = (local_445 + local_446);
float local_450 = (local_449 + local_447);
float local_452 = (local_450 / 3.0);

// local_453:透明度
float local_453;
float local_459 = local_3.w;
float local_460 = (local_459 * local_242);
(local_453 = local_460);

// local_463:环境光
vec3 local_463;
vec3 local_470 = ambient_color.xyz;
(local_463 = local_470);

vec3 local_472;
vec3 local_473;
vec3 local_479 = local_241.xyz;
vec3 local_481 = (local_479 * local_463);
(local_473 = local_481);
(local_472 = local_473);

float local_485 = mix(shadow_alpha, 1.0, local_379);
float local_486 = shadow_color_trans.x;
float local_487 = shadow_color_trans.y;
float local_488 = smoothstep(local_486, local_487, local_379);
vec4 local_489 = vec4(local_488, local_488, local_488, local_488);
vec4 local_490 = mix(shadow_color01, shadow_color02, local_489);
vec3 local_491 = local_490.xyz;
vec3 local_493 = vec3(shadow_density, shadow_density, shadow_density);
vec3 local_494 = mix(local_472, local_491, local_493);
vec3 local_495 = (local_494 * local_485);
vec3 local_496 = ambient_color.xyz;
vec3 local_498 = (local_495 * local_496);
vec3 local_499 = vec3(local_379, local_379, local_379);
vec3 local_500 = mix(local_498, local_472, local_499);

vec3 local_501 = vec3(1.0, 1.0, 1.0);
vec3 local_503 = vec3(1.0, 1.0, 1.0);
vec3 local_504 = (local_503 - local_500);
vec3 local_505 = (2.0 * local_504);
vec3 local_506 = vec3(1.0, 1.0, 1.0);
vec3 local_507 = glowColor.xyz;
vec3 local_509 = (local_506 - local_507);
vec3 local_510 = (local_505 * local_509);
vec3 local_511 = (local_501 - local_510);
float local_513 = glowPosFactor01.w;
vec3 local_514 = (local_511 * local_513);
float local_515 = (local_378 * v_glowIntensity_temp);
vec3 local_516 = vec3(local_515, local_515, local_515);
vec3 local_517 = mix(local_500, local_514, local_516);
vec4 local_518 = vec4(local_517.x, local_517.y, local_517.z, local_448);

// 
vec3 local_519;
float local_520 = FogInfo.x;
float local_521 = FogInfo.y;
float local_524;
{
float local_526 = smoothstep(local_520, local_521, v_texture1);
float local_527 = clamp(local_526, 0.0, 1.0);
(local_524 = local_527);
}
vec3 local_529 = FogColor.xyz;
float local_530 = FogColor.w;
float local_531 = min(local_530, local_524);
float local_532 = (local_524 * v_texture2);
float local_533 = (local_532 * HeightFogDensity);
float local_534 = (local_531 + local_533);
float local_535 = clamp(local_534, 0.0, 1.0);
vec3 local_536 = local_518.xyz;
vec3 local_539 = vec3(1.0, 1.0, 1.0);
float local_542 = mix(0.0, local_452, 0.5);
vec3 local_543 = vec3(local_542, local_542, local_542);
vec3 local_544 = mix(local_529, local_539, local_543);
vec3 local_545 = vec3(local_535, local_535, local_535);
vec3 local_546 = mix(local_536, local_544, local_545);
(local_519 = local_546);
float local_549 = (local_453 * AlphaMtl);
vec4 local_550 = vec4(local_519.x, local_519.y, local_519.z, local_549);
(gFragColor = local_550);
}
