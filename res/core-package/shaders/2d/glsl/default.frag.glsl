#version 420 core

// ===== OUTPUTS =====
layout(location = 0) out vec4 oColor;

// ===== INPUTS =====
layout(binding = 0) uniform sampler2D iTextures[8];

// ===== VARIANTS =====
in vec4 vColor;
in vec2 vUV;
flat in float vTexIndex;

// ===== FUNCTIONS =====
void main()
{
    oColor = texture(iTextures[int(vTexIndex)], vUV) * vColor;
}