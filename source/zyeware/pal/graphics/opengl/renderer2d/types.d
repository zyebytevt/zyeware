module zyeware.pal.graphics.opengl.Renderer2d.types;
version (ZW_PAL_OPENGL)  : import zyeware;

package(zyeware.pal.graphics.opengl):

struct BatchVertex2D {
    vec4 position;
    vec2 uv;
    color modulate;
    float textureIndex;
}

struct GlBuffer {
    uint vao;
    uint vbo;
    uint ibo;
}
