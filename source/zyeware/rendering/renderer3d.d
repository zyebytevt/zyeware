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

interface Renderer3D
{
    void beginScene(in Matrix4f projectionMatrix, in Matrix4f viewMatrix, Environment3D environment);
    void end();
    void submit(in Matrix4f transform);
}