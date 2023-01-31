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
    void function() initialize;
    void function() loadLibraries;
    void function() cleanup;

    // TODO: Add functions for creating platform dependent objects (e.g. shader, texture etc.)

public static:
    /// Sets which color to use for clearing the screen.
    ///
    /// Params:
    ///     value = The color to use.
    void function(Color value) nothrow setClearColor;

    /// Clears the screen with the color specified with `setClearColor`.
    void function() nothrow clear;

    /// Sets the viewport of the window.
    ///
    /// Params:
    ///     x = The x coordinate of the viewport.
    ///     y = The y coordinate of the viewport.
    ///     width = The width of the viewport.
    ///     height = The height of the viewport.
    void function(int x, int y, uint width, uint height) nothrow setViewport;

    /// Draws the currently bound `BufferGroup` to the screen.
    ///
    /// Params:
    ///     count = How many indicies to actually draw.
    void function(size_t count) nothrow drawIndexed;

    /// Packs a lights array into a constant buffer.
    ///
    /// Params:
    ///     buffer = The constant buffer to use.
    ///     lights = The lights array.
    void function(ref ConstantBuffer buffer, in Renderer3D.Light[] lights) nothrow packLightConstantBuffer;

    /// Gets a render flag.
    ///
    /// Params:
    ///     flag = The flag to query for.
    bool function(RenderFlag flag) nothrow getFlag;

    /// Sets a render flag.
    ///
    /// Params:
    ///     flag = The flag to set.
    ///     value = Whether to enable or disable the flag.
    void function(RenderFlag flag, bool value) nothrow setFlag;

    /// Queries a render capability.
    size_t function(RenderCapability capability) nothrow getCapability;
}