// This file is part of the ZyeWare Game Engine, and subject to the terms
// and conditions defined in the file 'LICENSE.txt', which is part
// of this source code package.
//
// Copyright 2021 ZyeByte
module zyeware.rendering.renderer3d;

import std.typecons : Rebindable;
import std.exception : enforce;

import zyeware.common;
import zyeware.rendering;
import zyeware.pal;

struct Renderer3D
{
    @disable this();
    @disable this(this);

public static:
    /// Clears the screen.
    ///
    /// Params:
    ///     clearColor = The color to clear the screen to.
    pragma(inline, true)
    void clearScreen(in Color clearColor) nothrow
    {
        Pal.graphics.api.clearScreen(clearColor);
    }

    void beginScene(in Matrix4f projectionMatrix, in Matrix4f viewMatrix, Environment3D environment)
    {
        Pal.graphics.renderer3d.beginScene(projectionMatrix, viewMatrix, environment);
    }

    void end()
    {
        Pal.graphics.renderer3d.end();
    }

    void submit(in Matrix4f transform)
    {
        Pal.graphics.renderer3d.submit(transform);
    }
}