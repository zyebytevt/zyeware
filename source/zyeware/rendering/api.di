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
    void initialize();
    void loadLibraries();
    void cleanup();

public static:
    /// Sets which color to use for clearing the screen.
    ///
    /// Params:
    ///     value = The color to use.
    void setClearColor(Color value) nothrow;

    /// Clears the screen with the color specified with `setClearColor`.
    void clear() nothrow;

    /// Sets the viewport of the window.
    ///
    /// Params:
    ///     x = The x coordinate of the viewport.
    ///     y = The y coordinate of the viewport.
    ///     width = The width of the viewport.
    ///     height = The height of the viewport.
    void setViewport(int x, int y, uint width, uint height) nothrow;

    /// Draws the currently bound `BufferGroup` to the screen.
    ///
    /// Params:
    ///     count = How many indicies to actually draw.
    void drawIndexed(size_t count) nothrow;

    /// Packs a lights array into a constant buffer.
    ///
    /// Params:
    ///     buffer = The constant buffer to use.
    ///     lights = The lights array.
    void packLightConstantBuffer(ref ConstantBuffer buffer, in Renderer3D.Light[] lights) nothrow;

    /// Gets a render flag.
    ///
    /// Params:
    ///     flag = The flag to query for.
    bool getFlag(RenderFlag flag) nothrow;

    /// Sets a render flag.
    ///
    /// Params:
    ///     flag = The flag to set.
    ///     value = Whether to enable or disable the flag.
    void setFlag(RenderFlag flag, bool value) nothrow;

    /// Queries a render capability.
    size_t getCapability(RenderCapability capability) nothrow;
}