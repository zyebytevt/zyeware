// This file is part of the ZyeWare Game Engine, and subject to the terms
// and conditions defined in the file 'LICENSE.txt', which is part
// of this source code package.
//
// Copyright 2021 ZyeByte
module zyeware.graphics.renderer;

import std.traits : isSomeString;

import zyeware;
import zyeware.pal.pal;

struct Renderer {
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
    pragma(inline, true)
    void begin2d(in Camera camera) {
        immutable mat4 projectionMatrix = camera ? camera.getProjectionMatrix() : mat4.orthographic(0, 1, 1, 0, -1, 1);
        immutable mat4 viewMatrix = camera ? camera.getViewMatrix() : mat4.identity;

        Pal.graphics.r2d.begin(projectionMatrix, viewMatrix);
    }

    /// Ends batching render commands. Calling this results in all render commands being flushed to the GPU.
    pragma(inline, true)
    void end2d() {
        Pal.graphics.r2d.end();
    }

    /// Draws a mesh.
    ///
    /// Params:
    ///     mesh = The mesh to draw.
    ///     position = 2D transform where to draw the mesh to.
    pragma(inline, true)
    void drawMesh2d(in Mesh2d mesh, in mat4 transform) {
        Pal.graphics.r2d.drawVertices(mesh.vertices, mesh.indices, transform, mesh.texture, mesh
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
    void drawRect2d(in rect dimensions, in vec2 position, in vec2 scale,
        in color modulate = color.white, in Texture2d texture = null, int layer = 0,
        in Material material = null, in rect region = rect(0, 0, 1, 1)) {
        Pal.graphics.r2d.drawRectangle(dimensions, mat4.translation(vec3(position, layer / 100f))
                * mat4.scaling(
                    scale.x, scale.y, 1), modulate, texture, material, region);
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
    void drawRect2d(in rect dimensions, in vec2 position, in vec2 scale, float rotation,
        in color modulate = color.white, in Texture2d texture = null, int layer = 0,
        in Material material = null, in rect region = rect(0, 0, 1, 1)) {
        Pal.graphics.r2d.drawRectangle(dimensions, mat4.translation(vec3(position, layer / 100f))
                * mat4.rotation(
                    rotation, vec3(0, 0, 1)) * mat4.scaling(scale.x, scale.y, 1),
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
    pragma(inline, true)
    void drawRect2d(in rect dimensions, in mat4 transform, in color modulate = color.white,
        in Texture2d texture = null, in Material material = null, in rect region = rect(0, 0, 1, 1)) {
        Pal.graphics.r2d.drawRectangle(dimensions, transform, modulate, texture, material, region);
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
    pragma(inline, true)
    void drawString2d(T)(in T text, in BitmapFont font, in vec2 position, in color modulate = color.white,
        ubyte alignment = BitmapFont.Alignment.left | BitmapFont.Alignment.top, in Material material = null)
            if (isSomeString!T) {
        static if (is(T == string))
            Pal.graphics.r2d.drawString(text, font, position, modulate, alignment, material);
        else static if (is(T == wstring))
            Pal.graphics.r2d.drawWString(text, font, position, modulate, alignment, material);
        else static if (is(T == dstring))
            Pal.graphics.r2d.drawDString(text, font, position, modulate, alignment, material);
        else
            static assert(false, "Unsupported string type for rendering");
    }
}
