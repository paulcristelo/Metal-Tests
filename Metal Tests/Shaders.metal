//
//  Shaders.metal
//  Metal Tests
//
//  Created by Paul Cristelo on 10/20/23.
//

#include <metal_stdlib>
#include "ShaderDefinitions.h"
using namespace metal;

struct VertexOut {
	float4 color;
	float4 pos [[position]];
	float brightness;
};

float3 palette(float t) {
	float3 a = float3(1.148, 0.088, -0.422);
	float3 b = float3(0.508, 0.508, 0.500);
	float3 c = float3(1.000, 2.000, -0.982);
	float3 d = float3(1.968, 0.333, 0.667);
	return a + b * cos(6.28318 * (c * t + d));
}

vertex VertexOut vertexShader(const device Vertex *vertexArray [[buffer(0)]], unsigned int vertexId [[vertex_id]]) {
	
	Vertex in = vertexArray[vertexId];
	VertexOut out;
	out.color = in.color;
	out.pos = float4(in.pos.x, in.pos.y, 0.0, 1.0);
	out.brightness = float(1);
	return out;
}

fragment float4 fragmentShader(VertexOut interpolated [[stage_in]], constant FragmentUniforms &uniforms [[buffer(0)]]) {
	
	float2 uv = (interpolated.pos.xy * 2 - uniforms.resolution) / uniforms.resolution.y;
	float2 center = uv;
	float3 finalColor = float3(0.0);
	float coeff = 8;
	
	for (float i = 0; i < 2; i++) {
		uv = fract(uv * 1.5) - 0.5;
		
		float dist = length(uv);
		float3 color = palette(length(center) + uniforms.currentTime + i * 0.4);
		
		dist = sin(dist * coeff + uniforms.currentTime) / coeff;
		dist = abs(dist);
		dist = 0.01 / dist;
		
		finalColor += color * dist;
	}
	return float4(finalColor, 1.0);
}
