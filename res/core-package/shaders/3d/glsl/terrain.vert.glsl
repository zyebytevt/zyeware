#version 420 core

// ===== ATTRIBUTES =====
layout(location = 0) in vec3 aPosition;
layout(location = 1) in vec2 aUV;
layout(location = 2) in vec3 aNormal;
layout(location = 3) in vec4 aColor;

// ===== INPUTS =====
#include "core:shaders/include/glsl/uniforms3d.glsl"

// ===== VARIANTS =====
out vec2 vUV;
out vec4 vColor;
out vec4 vWorldPosition;
out vec3 vToCameraVector;
out vec3 vNormal;

// ===== FUNCTIONS =====
void main()
{
    vWorldPosition = iMatrices.model * vec4(aPosition, 1.0);
    vToCameraVector = iEnvironment.cameraPosition.xyz - vWorldPosition.xyz;

    vUV = aUV;
    vColor = aColor;
    vNormal = aNormal;
    gl_Position = iMatrices.mvp * vec4(aPosition, 1.0);
}