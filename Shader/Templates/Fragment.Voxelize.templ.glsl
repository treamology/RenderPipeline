#version 430

// Shader used for Voxelization, required for GI

%DEFINES%

#define IS_VOXELIZE_SHADER 1

#pragma include "Includes/Configuration.inc.glsl"
#pragma include "Includes/Structures/VertexOutput.struct.glsl"
#pragma include "Includes/Structures/MaterialOutput.struct.glsl"

%INCLUDES%
%INOUT%

layout(location=0) in VertexOutput vOutput;
layout(location=4) flat in MaterialOutput mOutput;

// Voxel data
uniform vec3 voxelGridPosition;
uniform writeonly image3D RESTRICT VoxelGridDest;

uniform samplerCube ScatteringIBLDiffuse;
uniform samplerCube ScatteringIBLSpecular;

uniform sampler2D p3d_Texture0;

void main() {
    vec3 basecolor = texture(p3d_Texture0, vOutput.texcoord).xyz;
    // basecolor = pow(basecolor, vec3(2.2));
    basecolor *= mOutput.color;

    // Simplified ambient term
    vec3 ambient_diff = texture(ScatteringIBLDiffuse, vOutput.normal).xyz * 0.2;
    vec3 ambient_spec = textureLod(ScatteringIBLSpecular, vOutput.normal, 6).xyz * 0.2;

    vec3 ambient = ambient_diff * basecolor * (1 - mOutput.metallic);
    ambient += ambient_spec * basecolor * mOutput.metallic;

    vec3 shading_result = ambient;

    // Tonemapping to pack color
    shading_result = shading_result / (1.0 + shading_result);

    // Get destination voxel
    const int resolution = GET_SETTING(VXGI, grid_resolution);
    const float ws_size = GET_SETTING(VXGI, grid_ws_size);
    vec3 vs_coord = (vOutput.position - voxelGridPosition + ws_size) / (2.0 * ws_size);
    ivec3 vs_icoord = ivec3(vs_coord * resolution + 1e-5);

    // Write voxel
    imageStore(VoxelGridDest, vs_icoord, vec4(shading_result, 1.0));
}

