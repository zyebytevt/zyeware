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

struct RenderAPI
{
    @disable this();
    @disable this(this);

package(zyeware) static:
    void function() sInitializeImpl;
    void function() sLoadLibrariesImpl;
    void function() sCleanupImpl;

    void function(in Color) nothrow sSetClearColorImpl;
    void function() nothrow sClearImpl;
    void function(int, int, uint, uint) nothrow sSetViewportImpl;
    void function(size_t) nothrow sDrawIndexedImpl;
    void function(ref ConstantBuffer, in Renderer3D.Light[]) nothrow sPackLightConstantBufferImpl;
    bool function(RenderFlag) nothrow sGetFlagImpl;
    void function(RenderFlag, bool) nothrow sSetFlagImpl;
    size_t function(RenderCapability) nothrow sGetCapabilityImpl;
    
    BufferGroup function() sCreateBufferGroupImpl;
    DataBuffer function(size_t, BufferLayout, bool) sCreateDataBufferImpl;
    DataBuffer function(const void[], BufferLayout, bool) sCreateDataBufferWithDataImpl;
    IndexBuffer function(size_t, bool) sCreateIndexBufferImpl;
    IndexBuffer function(const uint[], bool) sCreateIndexBufferWithDataImpl;
    ConstantBuffer function(in BufferLayout) sCreateConstantBufferImpl;

    Framebuffer function(in FramebufferProperties) sCreateFramebufferImpl;
    Texture2D function(in Image, in TextureProperties) sCreateTexture2DImpl;
    TextureCubeMap function(in Image[6], in TextureProperties) sCreateTextureCubeMapImpl;
    Window function(in WindowProperties) sCreateWindowImpl;
    Shader function() sCreateShaderImpl;

    Texture2D function(string path) sLoadTexture2DImpl;
    TextureCubeMap function(string path) sLoadTextureCubeMapImpl;
    Shader function(string path) sLoadShaderImpl;

    pragma(inline, true)
    void initialize()
    {
        sInitializeImpl();
    }

    pragma(inline, true)
    void loadLibraries()
    {
        sLoadLibrariesImpl();
    }

    pragma(inline, true)
    void cleanup()
    {
        sCleanupImpl();
    }

public static:
    /// Sets which color to use for clearing the screen.
    ///
    /// Params:
    ///     value = The color to use.
    pragma(inline, true)
    void setClearColor(Color value) nothrow
    {
        sSetClearColorImpl(value);
    }

    /// Clears the screen with the color specified with `setClearColor`.
    pragma(inline, true)
    void clear() nothrow
    {
        sClearImpl();
    }

    /// Sets the viewport of the window.
    ///
    /// Params:
    ///     x = The x coordinate of the viewport.
    ///     y = The y coordinate of the viewport.
    ///     width = The width of the viewport.
    ///     height = The height of the viewport.
    pragma(inline, true)
    void setViewport(int x, int y, uint width, uint height) nothrow
    {
        // TODO: Change to vectors
        sSetViewportImpl(x, y, width, height);
    }

    /// Draws the currently bound `BufferGroup` to the screen.
    ///
    /// Params:
    ///     count = How many indicies to actually draw.
    pragma(inline, true)
    void drawIndexed(size_t count) nothrow
    {
        sDrawIndexedImpl(count);
    }

    /// Packs a lights array into a constant buffer.
    ///
    /// Params:
    ///     buffer = The constant buffer to use.
    ///     lights = The lights array.
    pragma(inline, true)
    void packLightConstantBuffer(ref ConstantBuffer buffer, in Renderer3D.Light[] lights) nothrow
    {
        sPackLightConstantBufferImpl(buffer, lights);
    }

    /// Gets a render flag.
    ///
    /// Params:
    ///     flag = The flag to query for.
    pragma(inline, true)
    bool getFlag(RenderFlag flag) nothrow
    {
        return sGetFlagImpl(flag);
    }

    /// Sets a render flag.
    ///
    /// Params:
    ///     flag = The flag to set.
    ///     value = Whether to enable or disable the flag.
    pragma(inline, true)
    void setFlag(RenderFlag flag, bool value) nothrow
    {
        sSetFlagImpl(flag, value);
    }

    /// Queries a render capability.
    pragma(inline, true)
    size_t getCapability(RenderCapability capability) nothrow
    {
        return sGetCapabilityImpl(capability);
    }
}