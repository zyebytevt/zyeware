#version 420 core

// ===== ATTRIBUTES =====
layout(location = 0) in vec4 aPosition;
layout(location = 1) in vec4 aColor;
layout(location = 2) in vec2 aUV;
layout(location = 3) in float aTexIndex;

// ===== INPUTS =====
uniform mat4 iProjectionView;
uniform int iTextureCount;
uniform float iTime;

// ===== VARIANTS =====
out vec4 vColor;
out vec2 vUV;
flat out float vTexIndex;

// ===== FUNCTIONS =====

vec4 vertex();

void main()
{
    vUV = aUV;
    vColor = aColor;
    vTexIndex = aTexIndex;

    gl_Position = vertex();
}