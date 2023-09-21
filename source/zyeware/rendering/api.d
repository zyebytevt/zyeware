// This file is part of the ZyeWare Game Engine, and subject to the terms
// and conditions defined in the file 'LICENSE.txt', which is part
// of this source code package.
//
// Copyright 2021 ZyeByte
module zyeware.rendering.api;

import zyeware.common;
import zyeware.rendering;

// RIDs are used to identify resources.
struct RID
{
    ushort category; // The category of the resource. This is set by the API.
    ushort id; // The ID of the resource. This is set by the API.
}

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

interface GraphicsAPI
{
    void initialize();
    void cleanup();

    void free(in RID rid) nothrow;

    RID createMesh(in Vertex3D[] vertices, in uint[] indices);
    RID createTexture2D(in Image image, in TextureProperties properties);
    RID createTextureCubeMap(in Image[6] images, in TextureProperties properties);
    RID createFramebuffer(in FramebufferProperties properties);
    RID createShader(in ShaderProperties properties);

    void setShaderUniform1f(in RID shader, in string name, in float value) nothrow;
    void setShaderUniform2f(in RID shader, in string name, in Vector2f value) nothrow;
    void setShaderUniform3f(in RID shader, in string name, in Vector3f value) nothrow;
    void setShaderUniform4f(in RID shader, in string name, in Vector4f value) nothrow;
    void setShaderUniform1i(in RID shader, in string name, in int value) nothrow;
    void setShaderUniformMat4f(in RID shader, in string name, in Matrix4f value) nothrow;

    void setViewport(Rect2i region) nothrow;

    void setRenderFlag(RenderFlag flag, bool value) nothrow;
    bool getRenderFlag(RenderFlag flag) nothrow;

    size_t getCapability(RenderCapability capability) nothrow;
}

interface RenderResource
{
    RID rid() pure const nothrow;
}