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

vertex VertexOut vertexShader(const device Vertex *vertexArray [[buffer(0)]], unsigned int vertexId [[vertex_id]]) {
	
	Vertex in = vertexArray[vertexId];
	VertexOut out;
	out.color = in.color;
	out.pos = float4(in.pos.x, in.pos.y, 0.0, 1.0);
	out.brightness = float(1);
	return out;
}

fragment float4 fragmentShader(VertexOut interpolated [[stage_in]], constant FragmentUniforms &uniforms [[buffer(0)]]) {
	
	return float4(interpolated.brightness * cos(uniforms.currentTime) * interpolated.color.rgb, interpolated.color.a);
}
