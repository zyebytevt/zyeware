module zyeware.pal.graphics.opengl.api.types; version(ZW_PAL_OPENGL):

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