#include "core://shaders/include/glsl/2d/header.frag.glsl"

uniform vec2 waveStrength;

vec4 fragment(sampler2D sampler)
{
    return texture(sampler, vUV + vec2(sin(iTime + vUV.y * 10.0) * waveStrength.x, 0)) * vColor;
}