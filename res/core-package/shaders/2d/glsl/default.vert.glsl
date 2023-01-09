#version 410 core

// ===== ATTRIBUTES =====
layout(location = 0) in vec4 aPosition;
layout(location = 1) in vec4 aColor;
layout(location = 2) in vec2 aUV;
layout(location = 3) in float aTexIndex;

// ===== INPUTS =====
layout(std140, shared, row_major) uniform Matrices
{
    mat4 viewProjection;
} iMatrices;

// ===== VARIANTS =====
out vec4 vColor;
out vec2 vUV;
flat out float vTexIndex;

// ===== FUNCTIONS =====
void main()
{
    vUV = aUV;
    vColor = aColor;
    vTexIndex = aTexIndex;

    gl_Position = iMatrices.viewProjection * aPosition;
}