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
import zyeware.pal.pal;

struct Renderer2D {
    @disable this();
    @disable this(this);

public static:
    /// Clears the screen.
    ///
    /// Params:
    ///     clearColor = The color to clear the screen with.
    pragma(inline, true)
    void clearScreen(in color clearColor) nothrow {
        Pal.graphics.api.clearScreen(clearColor);
    }

    /// Starts batching render commands. Must be called before any rendering is done.
    ///
    /// Params:
    ///     camera = The camera to use. If `null`, uses a default projection.
    void beginScene(in Camera camera) {
        immutable mat4 projectionMatrix = camera ? camera.getProjectionMatrix() : mat4.orthographic(0, 1, 1, 0, -1, 1);
        immutable mat4 viewMatrix = camera ? camera.getViewMatrix() : mat4.identity;

        Pal.graphics.renderer2d.beginScene(projectionMatrix, viewMatrix);
    }

    /// Ends batching render commands. Calling this results in all render commands being flushed to the GPU.
    void endScene() {
        Pal.graphics.renderer2d.endScene();
    }

    /// Flushes all render commands to the GPU.
    void flush() {
        Pal.graphics.renderer2d.flush();
    }

    /// Draws a mesh.
    ///
    /// Params:
    ///     mesh = The mesh to draw.
    ///     position = 2D transform where to draw the mesh to.
    void drawMesh(in Mesh2D mesh, in mat4 transform) {
        Pal.graphics.renderer2d.drawVertices(mesh.vertices, mesh.indices, transform, mesh.texture, mesh
                .material);
    }

    /// Draws a rectangle.
    ///
    /// Params:
    ///     dimensions = The dimensions of the rectangle to draw.
    ///     position = 2D position where to draw the rectangle to.
    ///     scale = How much to scale the dimensions.
    ///     modulate = The modulate of the rectangle. If a texture is supplied, it will be tinted in this modulate.
    ///     texture = The texture to use. If `null`, draws a blank rectangle.
    ///     material = The material to use. If `null`, uses the default material.
    ///     region = The region of the rectangle to use. Has no effect if no texture is supplied.
    pragma(inline, true)
    void drawRectangle(in rect dimensions, in vec2 position, in vec2 scale, in color modulate = color(
            "white"),
        in Texture2d texture = null, in Material material = null, in rect region = rect(0, 0, 1, 1)) {
        Pal.graphics.renderer2d.drawRectangle(dimensions, mat4.translation(vec3(position, 0))
                * mat4.scaling(scale.x, scale.y, 1), modulate, texture, material, region);
    }

    /// Draws a rectangle.
    ///
    /// Params:
    ///     dimensions = The dimensions of the rectangle to draw.
    ///     position = 2D position where to draw the rectangle to.
    ///     scale = How much to scale the dimensions.
    ///     rotation = The rotation of the rectangle, in radians.
    ///     modulate = The modulate of the rectangle. If a texture is supplied, it will be tinted in this modulate.
    ///     texture = The texture to use. If `null`, draws a blank rectangle.
    ///     material = The material to use. If `null`, uses the default material.
    ///     region = The region of the rectangle to use. Has no effect if no texture is supplied.
    pragma(inline, true)
    void drawRectangle(in rect dimensions, in vec2 position, in vec2 scale, float rotation, in color modulate = vec4(1),
        in Texture2d texture = null, in Material material = null, in rect region = rect(0, 0, 1, 1)) {
        Pal.graphics.renderer2d.drawRectangle(dimensions, mat4.translation(vec3(position, 0))
                * mat4.rotation(rotation, vec3(0, 0, 1)) * mat4.scaling(scale.x, scale.y, 1),
            modulate, texture, material, region);
    }

    /// Draws a rectangle.
    ///
    /// Params:
    ///     dimensions = The dimensions of the rectangle to draw.
    ///     transform = A 4x4 matrix used for transformation of the rectangle.
    ///     modulate = The modulate of the rectangle. If a texture is suppliedW, it will be tinted in this modulate.
    ///     texture = The texture to use. If `null`, draws a blank rectangle.
    ///     material = The material to use. If `null`, uses the default material.
    ///     region = The region of the rectangle to use. Has no effect if no texture is supplied.
    void drawRectangle(in rect dimensions, in mat4 transform, in color modulate = vec4(1),
        in Texture2d texture = null, in Material material = null, in rect region = rect(0, 0, 1, 1)) {
        Pal.graphics.renderer2d.drawRectangle(dimensions, transform, modulate, texture, material, region);
    }

    /// Draws text to the screen.
    ///
    /// Params:
    ///     T = The type of string to draw.
    ///     text = The text to draw.
    ///     font = The font to use.
    ///     position = The position to draw the text to.
    ///     modulate = The modulate of the text.
    ///     alignment = The alignment of the text.
    ///     material = The material to use. If `null`, uses the default material.
    void drawString(T)(in T text, in BitmapFont font, in vec2 position, in color modulate = color(
            "white"),
        ubyte alignment = BitmapFont.Alignment.left | BitmapFont.Alignment.top, in Material material = null)
            if (isSomeString!T) {
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
