// This file is part of the ZyeWare Game Engine, and subject to the terms
// and conditions defined in the file 'LICENSE.txt', which is part
// of this source code package.
//
// Copyright 2021 ZyeByte
module zyeware.rendering.renderer3d;

import std.typecons : Rebindable;
import std.exception : enforce;

import zyeware;

import zyeware.pal;

struct Renderer3D
{
    @disable this();
    @disable this(this);

public static:
    /// Clears the screen.
    ///
    /// Params:
    ///     clearColor = The modulate to clear the screen to.
    pragma(inline, true)
    void clearScreen(in color clearColor) nothrow
    {
        Pal.graphics.api.clearScreen(clearColor);
    }

    void beginScene(in mat4 projectionMatrix, in mat4 viewMatrix, Environment3D environment)
    {
        Pal.graphics.renderer3d.beginScene(projectionMatrix, viewMatrix, environment);
    }

    void end()
    {
        Pal.graphics.renderer3d.end();
    }

    void submit(in mat4 transform)
    {
        Pal.graphics.renderer3d.submit(transform);
    }
}