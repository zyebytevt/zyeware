#version 410 core

// ===== OUTPUTS =====
layout(location = 0) out vec4 oColor;

// ===== INPUTS =====
uniform samplerCube iTexture;

// ===== VARIANTS =====
in vec3 vUV;

// ===== FUNCTIONS =====
void main()
{
    oColor = texture(iTexture, vUV);
}