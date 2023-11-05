// This file is part of the ZyeWare Game Engine, and subject to the terms
// and conditions defined in the file 'LICENSE.txt', which is part
// of this source code package.
//
// Copyright 2021 ZyeByte
module zyeware.rendering.api;

import zyeware.common;
import zyeware.rendering;

/// Used for selecting a rendering backend at the start of the engine.
enum RenderBackend
{
    headless, /// A dummy API, does nothing.
    openGl, /// Uses OpenGL for rendering.
}

enum RenderFlag
{
    depthTesting, /// Whether to use depth testing or not.
    depthBufferWriting, /// Whether to write to the depth buffer when drawing.
    culling, /// Whether culling is enabled or not.
    stencilTesting, /// Whether to use stencil testing or not.
    wireframe /// Whether to render in wireframe or not.
}

enum RenderCapability
{
    maxTextureSlots /// How many texture slots are available to use.
}

struct GraphicsAPICallbacks
{
public:
    void function() initialize;
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

    void function(in NativeHandle target) nothrow setRenderTarget;
    void function(in NativeHandle framebuffer, Rect2i srcRegion, Rect2i dstRegion) nothrow presentToScreen;
}

struct GraphicsAPI
{
    @disable this();
    @disable this(this);
    
package(zyeware) static:
    GraphicsAPICallbacks sCallbacks;

public static:
    void initialize()
    {
        sCallbacks.initialize();
    }

    void cleanup()
    {
        sCallbacks.cleanup();
    }

    NativeHandle createMesh(in Vertex3D[] vertices, in uint[] indices)
    {
        return sCallbacks.createMesh(vertices, indices);
    }

    NativeHandle createTexture2D(in Image image, in TextureProperties properties)
    {
        return sCallbacks.createTexture2D(image, properties);
    }

    NativeHandle createTextureCubeMap(in Image[6] images, in TextureProperties properties)
    {
        return sCallbacks.createTextureCubeMap(images, properties);
    }

    NativeHandle createFramebuffer(in FramebufferProperties properties)
    {
        return sCallbacks.createFramebuffer(properties);
    }   

    NativeHandle createShader(in ShaderProperties properties)
    {
        return sCallbacks.createShader(properties);
    }

    void freeMesh(NativeHandle mesh) nothrow
    {
        sCallbacks.freeMesh(mesh);
    }

    void freeTexture2D(NativeHandle texture) nothrow
    {
        sCallbacks.freeTexture2D(texture);
    }

    void freeTextureCubeMap(NativeHandle texture) nothrow
    {
        sCallbacks.freeTextureCubeMap(texture);
    }

    void freeFramebuffer(NativeHandle framebuffer) nothrow
    {
        sCallbacks.freeFramebuffer(framebuffer);
    }

    void freeShader(NativeHandle shader) nothrow
    {
        sCallbacks.freeShader(shader);
    }

    void setShaderUniform(T)(in NativeHandler shader, in string name, in T value) nothrow
    {
        static if (is(T == float))
            sCallbacks.setShaderUniform1f(shader, name, value);
        else static if (is(T == Vector2f))
            sCallbacks.setShaderUniform2f(shader, name, value);
        else static if (is(T == Vector3f))
            sCallbacks.setShaderUniform3f(shader, name, value);
        else static if (is(T == Vector4f))
            sCallbacks.setShaderUniform4f(shader, name, value);
        else static if (is(T == int))
            sCallbacks.setShaderUniform1i(shader, name, value);
        else static if (is(T == Matrix4f))
            sCallbacks.setShaderUniformMat4f(shader, name, value);
        else
            static assert(false, "Unsupported type " ~ T.stringof ~ " for setShaderUniform");
    }

    void setViewport(Rect2i region) nothrow
    {
        sCallbacks.setViewport(region);
    }

    void setRenderFlag(RenderFlag flag, bool value) nothrow
    {
        sCallbacks.setRenderFlag(flag, value);
    }

    bool getRenderFlag(RenderFlag flag) nothrow
    {
        return sCallbacks.getRenderFlag(flag);
    }

    size_t getCapability(RenderCapability capability) nothrow
    {
        return sCallbacks.getCapability(capability);
    }

    void renderTarget(in NativeHandle target) nothrow
    {
        sCallbacks.setRenderTarget(target);
    }

    void presentToScreen(in NativeHandle framebuffer, Rect2i srcRegion, Rect2i dstRegion) nothrow
    {
        sCallbacks.presentToScreen(framebuffer, srcRegion, dstRegion);
    }
}