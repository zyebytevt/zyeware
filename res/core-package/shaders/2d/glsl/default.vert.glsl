#include "core:shaders/include/glsl/2d/header.vert.glsl"

vec4 vertex()
{
    return iProjectionView * aPosition;
}