module zyeware.pal.graphics.opengl.renderer2d.types;

import zyeware;


struct BatchVertex2D
{
    vec4 position;
    vec2 uv;
    col color;
    float textureIndex;
}

struct GlBuffer
{
    uint vao;
    uint vbo;
    uint ibo;
}