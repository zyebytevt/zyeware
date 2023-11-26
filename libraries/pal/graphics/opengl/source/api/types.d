module zyeware.pal.graphics.opengl.api.types;

package(zyeware.pal.graphics.opengl):

struct MeshData
{
    uint vao;
    uint vbo;
    uint ibo;
}

struct FramebufferData
{
    uint id;
    uint colorAttachmentId;
    uint depthAttachmentId;
}

struct UniformLocationKey
{
    uint id;
    string name;
}