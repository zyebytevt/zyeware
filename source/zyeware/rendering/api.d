// This file is part of the ZyeWare Game Engine, and subject to the terms
// and conditions defined in the file 'LICENSE.txt', which is part
// of this source code package.
//
// Copyright 2021 ZyeByte
module zyeware.rendering.api;

import zyeware.common;
import zyeware.rendering;

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

    // TODO: Add functions for creating platform dependent objects (e.g. shader, texture etc.)

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
    size_t getCapability(RenderCapability capability) nothrow
    {
        return sGetCapabilityImpl(capability);
    }
}