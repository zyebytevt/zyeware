// This file is part of the ZyeWare Game Engine, and subject to the terms
// and conditions defined in the file 'LICENSE.txt', which is part
// of this source code package.
//
// Copyright 2021 ZyeByte
module zyeware.rendering.Renderer3d;

import std.typecons : Rebindable;
import std.exception : enforce;

import zyeware;
import zyeware.pal.pal;

struct Renderer3d {
    @disable this();
    @disable this(this);

public static:
    /// Clears the screen.
    ///
    /// Params:
    ///     clearColor = The modulate to clear the screen to.
    pragma(inline, true)
    void clearScreen(in color clearColor) nothrow {
        Pal.graphics.api.clearScreen(clearColor);
    }

    void beginScene(in mat4 projectionMatrix, in mat4 viewMatrix, Environment3D environment) {
        Pal.graphics.Renderer3d.beginScene(projectionMatrix, viewMatrix, environment);
    }

    void end() {
        Pal.graphics.Renderer3d.end();
    }

    void submit(in mat4 transform) {
        Pal.graphics.Renderer3d.submit(transform);
    }
}
