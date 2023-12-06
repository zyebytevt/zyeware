module zyeware.pal.graphics.opengl.renderer2d.types;

import zyeware;


struct BatchVertex2D
{
    Vector4f position;
    Vector2f uv;
    Color color;
    float textureIndex;
}

struct GlBuffer
{
    uint vao;
    uint vbo;
    uint ibo;
}