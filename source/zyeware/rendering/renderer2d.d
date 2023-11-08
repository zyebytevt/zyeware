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
import zyeware.pal.renderer.callbacks;
import zyeware.pal;

struct Renderer2D
{
    @disable this();
    @disable this(this);

public static:
    void initialize()
    {
        PAL.renderer2D.initialize();
    }

    void cleanup()
    {
        PAL.renderer2D.cleanup();
    }

    void beginScene(in Matrix4f projectionMatrix, in Matrix4f viewMatrix)
    {
        PAL.renderer2D.beginScene(projectionMatrix, viewMatrix);
    }

    void endScene()
    {
        PAL.renderer2D.endScene();
    }

    void flush()
    {
        PAL.renderer2D.flush();
    }

    void drawRectangle(in Rect2f dimensions, in Matrix4f transform, in Color modulate = Vector4f(1),
        in Texture2D texture = null, in Material material = null, in Rect2f region = Rect2f(0, 0, 1, 1))
    {
        PAL.renderer2D.drawRectangle(dimensions, transform, modulate, texture, material, region);
    }

    void drawString(T)(in T text, in Font font, in Vector2f position, in Color modulate = Color.white,
        ubyte alignment = Font.Alignment.left | Font.Alignment.top, in Material material = null)
        if (isSomeString!T)
    {
        static if (is(T == string))
            PAL.renderer2D.drawString(text, font, position, modulate, alignment, material);
        else static if (is(T == wstring))
            PAL.renderer2D.drawWString(text, font, position, modulate, alignment, material);
        else static if (is(T == dstring))
            PAL.renderer2D.drawDString(text, font, position, modulate, alignment, material);
        else
            static assert(false, "Unsupported string type for rendering");
    }
}