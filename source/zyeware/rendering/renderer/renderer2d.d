// This file is part of the ZyeWare Game Engine, and subject to the terms
// and conditions defined in the file 'LICENSE.txt', which is part
// of this source code package.
//
// Copyright 2021 ZyeByte
module zyeware.rendering.renderer.renderer2d;

import std.traits : isSomeString;
import std.string : lineSplitter;
import std.typecons : Rebindable;
import std.exception : enforce;

import bmfont : BMFont = Font;

import zyeware.common;
import zyeware.core.debugging.profiler;
import zyeware.rendering;

/// The `Renderer2D` struct gives access to the 2D rendering API.
struct Renderer2D
{
    @disable this();
    @disable this(this);

package(zyeware) static:
    void function() sInitialize;
    void function() sCleanup;
    void function(in Matrix4f, in Matrix4f) sBeginImpl;
    void function() sEndImpl;
    void function() sFlushImpl;
    void function(in Rect2f, in Matrix4f, in Color, in Texture2D, in Rect2f) sDrawRectImpl;
    void function(in dstring, in Font, in Vector2f, in Color, ubyte alignment) sDrawTextImpl;

public static:
    /// Starts a 2D scene. This must be called before any 2D drawing commands.
    ///
    /// Params:
    ///     projectionMatrix = A 4x4 matrix used for projection.
    ///     viewMatrix = A 4x4 matrix used for view.
    pragma(inline, true)
    void begin(in Matrix4f projectionMatrix, in Matrix4f viewMatrix)
    {
        sBeginImpl(projectionMatrix, viewMatrix);
    }

    /// Ends a 2D scene. This must be called at the end of all 2D drawing commands, as it flushes
    /// everything to the screen.
    pragma(inline, true)
    void end()
    {
        sEndImpl();
    }

    /// Flushes all currently cached drawing commands to the screen.
    pragma(inline, true)
    void flush()
    {
        sFlushImpl();
    }

    /// Draws a rectangle.
    ///
    /// Params:
    ///     dimensions = The dimensions of the rectangle to draw.
    ///     position = 2D position where to draw the rectangle to.
    ///     scale = How much to scale the dimensions.
    ///     modulate = The color of the rectangle. If a texture is supplied, it will be tinted in this color.
    ///     texture = The texture to use. If `null`, draws a blank rectangle.
    ///     region = The region of the rectangle to use. Has no effect if no texture is supplied.
    pragma(inline, true)
    void drawRect(in Rect2f dimensions, in Vector2f position, in Vector2f scale, in Color modulate = Color.white,
        in Texture2D texture = null, in Rect2f region = Rect2f(0, 0, 1, 1))
    {
        sDrawRectImpl(dimensions, Matrix4f.translation(Vector3f(position, 0)) * Matrix4f.scaling(scale.x, scale.y, 1),
            modulate, texture, region);
    }

    /// Draws a rectangle.
    ///
    /// Params:
    ///     dimensions = The dimensions of the rectangle to draw.
    ///     position = 2D position where to draw the rectangle to.
    ///     scale = How much to scale the dimensions.
    ///     rotation = The rotation of the rectangle, in radians.
    ///     modulate = The color of the rectangle. If a texture is supplied, it will be tinted in this color.
    ///     texture = The texture to use. If `null`, draws a blank rectangle.
    ///     region = The region of the rectangle to use. Has no effect if no texture is supplied.
    pragma(inline, true)
    void drawRect(in Rect2f dimensions, in Vector2f position, in Vector2f scale, float rotation, in Color modulate = Vector4f(1),
        in Texture2D texture = null, in Rect2f region = Rect2f(0, 0, 1, 1))
    {
        sDrawRectImpl(dimensions, Matrix4f.translation(Vector3f(position, 0)) * Matrix4f.rotation(rotation, Vector3f(0, 0, 1))
            * Matrix4f.scaling(scale.x, scale.y, 1), modulate, texture, region);
    }

    /// Draws a rectangle.
    ///
    /// Params:
    ///     dimensions = The dimensions of the rectangle to draw.
    ///     transform = A 4x4 matrix used for transformation of the rectangle.
    ///     modulate = The color of the rectangle. If a texture is supplied, it will be tinted in this color.
    ///     texture = The texture to use. If `null`, draws a blank rectangle.
    ///     region = The region of the rectangle to use. Has no effect if no texture is supplied.
    pragma(inline, true)
    void drawRect(in Rect2f dimensions, in Matrix4f transform, in Color modulate = Vector4f(1), in Texture2D texture = null,
        in Rect2f region = Rect2f(0, 0, 1, 1))
    {
        sDrawRectImpl(dimensions, transform, modulate, texture, region);
    }

    /// Draws some text to screen.
    ///
    /// Params:
    ///     text = The text to draw. May be of any string type.
    ///     font = The font to use.
    ///     position = 2D position where to draw the text to.
    ///     modulate = The color of the text.
    ///     alignment = How to align the text. Horizontal and vertical alignment can be OR'd together.
    pragma(inline, true)
    void drawText(in dstring text, in Font font, in Vector2f position, in Color modulate = Color.white,
        ubyte alignment = Font.Alignment.left | Font.Alignment.top)
    {
        sDrawTextImpl(text, font, position, modulate, alignment);
    }
}