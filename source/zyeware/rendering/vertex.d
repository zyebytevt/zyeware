module zyeware.rendering.vertex;

import zyeware;

struct Vertex2D
{
    vec2 position = vec2.zero;
    vec2 uv = vec2.zero;
    color modulate = color.white;
}

struct Vertex3D
{
    vec3 position = vec3.zero;
    vec3 normal = vec3.zero;
    vec2 uv = vec2.zero;
    color modulate = color.white;
}