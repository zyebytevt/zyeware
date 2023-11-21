module zyeware.pal.graphicsDriver.callbacks;

import zyeware.common;
import zyeware.rendering;
import zyeware.pal.graphicsDriver.types;

struct GraphicsDriver
{
public:
    void function() initialize;
    void function() loadLibraries;
    void function() cleanup;

    NativeHandle function(in Vertex3D[] vertices, in uint[] indices) createMesh;
    NativeHandle function(in Image image, in TextureProperties properties) createTexture2D;
    NativeHandle function(in Image[6] images, in TextureProperties properties) createTextureCubeMap;
    NativeHandle function(in FramebufferProperties properties) createFramebuffer;
    NativeHandle function(in ShaderProperties properties) createShader;

    void function(NativeHandle mesh) nothrow freeMesh;
    void function(NativeHandle texture) nothrow freeTexture2D;
    void function(NativeHandle texture) nothrow freeTextureCubeMap;
    void function(NativeHandle framebuffer) nothrow freeFramebuffer;
    void function(NativeHandle shader) nothrow freeShader;

    void function(in NativeHandle shader, in string name, in float value) nothrow setShaderUniform1f;
    void function(in NativeHandle shader, in string name, in Vector2f value) nothrow setShaderUniform2f;
    void function(in NativeHandle shader, in string name, in Vector3f value) nothrow setShaderUniform3f;
    void function(in NativeHandle shader, in string name, in Vector4f value) nothrow setShaderUniform4f;
    void function(in NativeHandle shader, in string name, in int value) nothrow setShaderUniform1i;
    void function(in NativeHandle shader, in string name, in Matrix4f value) nothrow setShaderUniformMat4f;

    void function(Rect2i region) nothrow setViewport;
    void function(RenderFlag flag, bool value) nothrow setRenderFlag;
    bool function(RenderFlag flag) nothrow getRenderFlag;
    size_t function(RenderCapability capability) nothrow getCapability;
    void function(Color clearColor) nothrow clearScreen;

    void function(in NativeHandle target) nothrow setRenderTarget;
    void function(in NativeHandle framebuffer, Rect2i srcRegion, Rect2i dstRegion) nothrow presentToScreen;
    NativeHandle function(in NativeHandle framebuffer) nothrow getTextureFromFramebuffer;
}