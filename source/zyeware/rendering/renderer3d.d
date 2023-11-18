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
import zyeware.pal.renderer.callbacks;
import zyeware.pal;

struct Renderer3D
{
    @disable this();
    @disable this(this);

public static:
    void beginScene(in Matrix4f projectionMatrix, in Matrix4f viewMatrix, Environment3D environment)
    {
        Pal.renderer3d.beginScene(projectionMatrix, viewMatrix, environment);
    }

    void end()
    {
        Pal.renderer3d.end();
    }

    void submit(in Matrix4f transform)
    {
        Pal.renderer3d.submit(transform);
    }
}