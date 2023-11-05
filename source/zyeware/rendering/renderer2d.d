// This file is part of the ZyeWare Game Engine, and subject to the terms
// and conditions defined in the file 'LICENSE.txt', which is part
// of this source code package.
//
// Copyright 2021 ZyeByte
module zyeware.rendering.renderer2d;

import std.traits : isSomeString;
import std.string : lineSplitter;
import std.typecons : Rebindable;
import std.exception : enforce;

import bmfont : BMFont = Font;

import zyeware.common;
import zyeware.core.debugging.profiler;
import zyeware.rendering;

struct Renderer2D
{
    @disable this();
    @disable this(this);

package(zyeware) static:
    Renderer2DCallbacks sCallbacks;

public static:
    void initialize()
    {
        sCallbacks.initialize();
    }

    void cleanup()
    {
        sCallbacks.cleanup();
    }

    void beginScene(in Matrix4f projectionMatrix, in Matrix4f viewMatrix)
    {
        sCallbacks.beginScene(projectionMatrix, viewMatrix);
    }

    void endScene()
    {
        sCallbacks.endScene();
    }

    void flush()
    {
        sCallbacks.flush();
    }

    void drawRectangle(in Rect2f dimensions, in Matrix4f transform, in Color modulate = Vector4f(1),
        in Texture2D texture = null, in Rect2f region = Rect2f(0, 0, 1, 1))
    {
        sCallbacks.drawRectangle(dimensions, transform, modulate, texture, region);
    }

    void drawString(T)(in T text, in Font font, in Vector2f position, in Color modulate = Color.white,
        ubyte alignment = Font.Alignment.left | Font.Alignment.top)
        if (isSomeString!T)
    {
        static if (is(T == string))
            sCallbacks.drawString(text, font, position, modulate, alignment);
        else static if (is(T == wstring))
            sCallbacks.drawWString(text, font, position, modulate, alignment);
        else static if (is(T == dstring))
            sCallbacks.drawDString(text, font, position, modulate, alignment);
        else
            static assert(false, "Unsupported string type for rendering");
    }
}