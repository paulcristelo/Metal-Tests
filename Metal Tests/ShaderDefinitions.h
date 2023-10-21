//
//  ShaderDefinitions.h
//  Metal Tests
//
//  Created by Paul Cristelo on 10/20/23.
//

#ifndef ShaderDefinitions_h
#define ShaderDefinitions_h

#include <simd/simd.h>

struct Vertex {
	vector_float4 color;
	vector_float2 pos;
	float brightness;
};

struct FragmentUniforms {
	float currentTime;
	float dt;
	
};

#endif /* ShaderDefinitions_h */
