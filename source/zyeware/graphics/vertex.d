module zyeware.graphics.vertex;

import zyeware;

struct Vertex2d
{
    vec2 position = vec2.zero;
    vec2 uv = vec2.zero;
    color modulate = color("white");
}

struct Vertex3d
{
    vec3 position = vec3.zero;
    vec3 normal = vec3.zero;
    vec2 uv = vec2.zero;
    color modulate = color("white");
}
