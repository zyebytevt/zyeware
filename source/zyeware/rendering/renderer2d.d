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

import zyeware;
import zyeware.core.debugging.profiler;

import zyeware.pal;

struct Renderer2D
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

    /// Starts batching render commands. Must be called before any rendering is done.
    ///
    /// Params:
    ///     projectionMatrix = The projection matrix to use.
    ///     viewMatrix = The view matrix to use.
    void beginScene(in Matrix4f projectionMatrix, in Matrix4f viewMatrix)
    {
        Pal.graphics.renderer2d.beginScene(projectionMatrix, viewMatrix);
    }

    /// Ends batching render commands. Calling this results in all render commands being flushed to the GPU.
    void endScene()
    {
        Pal.graphics.renderer2d.endScene();
    }

    /// Flushes all render commands to the GPU.
    void flush()
    {
        Pal.graphics.renderer2d.flush();
    }

    /// Draws a mesh.
    ///
    /// Params:
    ///     mesh = The mesh to draw.
    ///     position = 2D transform where to draw the mesh to.
    void drawMesh(in Mesh2D mesh, in Matrix4f transform)
    {
        Pal.graphics.renderer2d.drawVertices(mesh.vertices, mesh.indices, transform, mesh.texture, mesh.material);
    }

    /// Draws a rectangle.
    ///
    /// Params:
    ///     dimensions = The dimensions of the rectangle to draw.
    ///     position = 2D position where to draw the rectangle to.
    ///     scale = How much to scale the dimensions.
    ///     modulate = The color of the rectangle. If a texture is supplied, it will be tinted in this color.
    ///     texture = The texture to use. If `null`, draws a blank rectangle.
    ///     material = The material to use. If `null`, uses the default material.
    ///     region = The region of the rectangle to use. Has no effect if no texture is supplied.
    pragma(inline, true)
    void drawRectangle(in Rect2f dimensions, in Vector2f position, in Vector2f scale, in Color modulate = Color.white,
        in Texture2D texture = null, in Material material = null, in Rect2f region = Rect2f(0, 0, 1, 1))
    {
        Pal.graphics.renderer2d.drawRectangle(dimensions, Matrix4f.translation(Vector3f(position, 0))
            * Matrix4f.scaling(scale.x, scale.y, 1), modulate, texture, material, region);
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
    ///     material = The material to use. If `null`, uses the default material.
    ///     region = The region of the rectangle to use. Has no effect if no texture is supplied.
    pragma(inline, true)
    void drawRectangle(in Rect2f dimensions, in Vector2f position, in Vector2f scale, float rotation, in Color modulate = Vector4f(1),
        in Texture2D texture = null, in Material material = null, in Rect2f region = Rect2f(0, 0, 1, 1))
    {
        Pal.graphics.renderer2d.drawRectangle(dimensions, Matrix4f.translation(Vector3f(position, 0))
            * Matrix4f.rotation(rotation, Vector3f(0, 0, 1)) * Matrix4f.scaling(scale.x, scale.y, 1),
            modulate, texture, material, region);
    }

    /// Draws a rectangle.
    ///
    /// Params:
    ///     dimensions = The dimensions of the rectangle to draw.
    ///     transform = A 4x4 matrix used for transformation of the rectangle.
    ///     modulate = The color of the rectangle. If a texture is suppliedW, it will be tinted in this color.
    ///     texture = The texture to use. If `null`, draws a blank rectangle.
    ///     material = The material to use. If `null`, uses the default material.
    ///     region = The region of the rectangle to use. Has no effect if no texture is supplied.
    void drawRectangle(in Rect2f dimensions, in Matrix4f transform, in Color modulate = Vector4f(1),
        in Texture2D texture = null, in Material material = null, in Rect2f region = Rect2f(0, 0, 1, 1))
    {
        Pal.graphics.renderer2d.drawRectangle(dimensions, transform, modulate, texture, material, region);
    }

    /// Draws text to the screen.
    ///
    /// Params:
    ///     T = The type of string to draw.
    ///     text = The text to draw.
    ///     font = The font to use.
    ///     position = The position to draw the text to.
    ///     modulate = The color of the text.
    ///     alignment = The alignment of the text.
    ///     material = The material to use. If `null`, uses the default material.
    void drawString(T)(in T text, in BitmapFont font, in Vector2f position, in Color modulate = Color.white,
        ubyte alignment = BitmapFont.Alignment.left | BitmapFont.Alignment.top, in Material material = null)
        if (isSomeString!T)
    {
        static if (is(T == string))
            Pal.graphics.renderer2d.drawString(text, font, position, modulate, alignment, material);
        else static if (is(T == wstring))
            Pal.graphics.renderer2d.drawWString(text, font, position, modulate, alignment, material);
        else static if (is(T == dstring))
            Pal.graphics.renderer2d.drawDString(text, font, position, modulate, alignment, material);
        else
            static assert(false, "Unsupported string type for rendering");
    }
}