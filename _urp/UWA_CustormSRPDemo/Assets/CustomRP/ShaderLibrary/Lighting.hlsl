//光照计算相关库
#ifndef CUSTOM_LIGHTING_INCLUDED
#define CUSTOM_LIGHTING_INCLUDED
//计算入射光照
float3 IncomingLight (Surface surface, Light light) {
	return saturate(dot(surface.normal, light.direction)* light.attenuation) * light.color;
}
//入射光乘以光照照射到表面的直接照明颜色,得到最终的照明颜色
float3 GetLighting (Surface surface, BRDF brdf, Light light) {
	return IncomingLight(surface, light) * DirectBRDF(surface, brdf, light);
}

//根据物体的表面信息和灯光属性获取最终光照结果
float3 GetLighting(Surface surfaceWS, BRDF brdf) {
	//得到表面阴影数据
	ShadowData shadowData = GetShadowData(surfaceWS);
	//可见光的光照结果进行累加得到最终光照结果
	float3 color = 0.0;
	for (int i = 0; i < GetDirectionalLightCount(); i++) {
		Light light = GetDirectionalLight(i, surfaceWS, shadowData);
		color += GetLighting(surfaceWS, brdf, light);
	}
	return color;
}



#endif
