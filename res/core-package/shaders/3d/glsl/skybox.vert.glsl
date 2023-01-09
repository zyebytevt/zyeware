#version 410 core

// ===== ATTRIBUTES =====
layout(location = 0) in vec3 aPosition;

// ===== INPUTS =====
layout(std140, shared, row_major) uniform Matrices
{
    mat4 mvp;
} iMatrices;

// ===== VARIANTS =====
out vec3 vUV;

// ===== FUNCTIONS =====
void main()
{
    vUV = aPosition;
    vec4 pos = iMatrices.mvp * vec4(aPosition, 1.0);
    gl_Position = pos.xyzz;
}