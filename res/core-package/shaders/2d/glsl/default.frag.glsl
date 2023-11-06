#include "core://shaders/include/glsl/2d/header.frag.glsl"

vec4 fragment(sampler2D sampler)
{
    return texture(sampler, vUV) * vColor;
}