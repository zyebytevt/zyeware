// This file is part of the ZyeWare Game Engine, and subject to the terms
// and conditions defined in the file 'LICENSE.txt', which is part
// of this source code package.
//
// Copyright © 2021-2024 ZyeByte. All rights reserved.
module zyeware.rendering.renderer;

import std.traits : isSomeString;
import std.typecons : Rebindable;

import zyeware;
import zyeware.subsystems.graphics;

struct Renderer
{
private static:
    Rebindable!(const Camera) mActiveCamera;
    bool mBatchActive;

public static:
    /// Clears the screen.
    ///
    /// Params:
    ///     clearColor = The color to clear the screen with.
    pragma(inline, true) void clearScreen(in color clearColor) nothrow
    {
        GraphicsSubsystem.callbacks.clearScreen(clearColor);
    }

    /// Starts batching render commands. Must be called before any rendering is done.
    ///
    /// Params:
    ///     camera = The camera to use. If `null`, uses a default projection.
    void begin2d(in Camera camera)
    in (!mBatchActive,
        "A 2D render batch is already active. Call `end2d` before starting a new batch.")
    {
        immutable mat4 projectionMatrix = camera ? camera.getProjectionMatrix() : mat4.orthographic(0,
            1, 1, 0, -1, 1);
        immutable mat4 viewMatrix = camera ? camera.getViewMatrix() : mat4.identity;

        mActiveCamera = camera;
        begin2d(projectionMatrix, viewMatrix);
    }

    /// Starts batching render commands. Must be called before any rendering is done.
    ///
    /// Params:
    ///     projectionMatrix = The projection matrix to use.
    ///     viewMatrix = The view matrix to use.
    void begin2d(in mat4 projectionMatrix, in mat4 viewMatrix = mat4.identity)
    {
        mBatchActive = true;
        GraphicsSubsystem.callbacks.r2dBegin(projectionMatrix, viewMatrix);
    }

    /// Ends batching render commands. Calling this results in all render commands being flushed to the GPU.
    pragma(inline, true) void end2d()
    {
        GraphicsSubsystem.callbacks.r2dEnd();
        mActiveCamera = null;
        mBatchActive = false;
    }

    /// Draws a mesh.
    ///
    /// Params:
    ///     mesh = The mesh to draw.
    ///     position = 2D transform where to draw the mesh to.
    pragma(inline, true) void drawMesh2d(in Mesh2d mesh, in mat4 transform)
    {
        GraphicsSubsystem.callbacks.r2dDrawVertices(mesh.vertices, mesh.indices, transform,
            mesh.texture, mesh.material);
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
    pragma(inline, true) void drawRect2d(in rect dimensions, in vec2 position, in vec2 scale,
        in color modulate = color.white, in Texture2d texture = null, int layer = 0,
        in Material material = null, in rect region = rect(0, 0, 1, 1))
    {
        drawRect2d(dimensions, mat4.translation(vec3(position,
                layer / 100f)) * mat4.scaling(scale.x, scale.y, 1), modulate,
            texture, material, region);
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
    pragma(inline, true) void drawRect2d(in rect dimensions, in vec2 position, in vec2 scale,
        float rotation, in color modulate = color.white, in Texture2d texture = null,
        int layer = 0, in Material material = null, in rect region = rect(0, 0, 1, 1))
    {
        drawRect2d(dimensions, mat4.translation(vec3(position,
                layer / 100f)) * mat4.rotation(rotation, vec3(0, 0,
                1)) * mat4.scaling(scale.x, scale.y, 1), modulate, texture, material, region);
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
    pragma(inline, true) void drawRect2d(in rect dimensions, in mat4 transform,
        in color modulate = color.white, in Texture2d texture = null,
        in Material material = null, in rect region = rect(0, 0, 1, 1))
    {
        // TODO: Font rendering needs to be improved.

        static vec2[4] quadPositions;
        quadPositions[0] = vec2(dimensions.x, dimensions.y);
        quadPositions[1] = vec2(dimensions.x + dimensions.width, dimensions.y);
        quadPositions[2] = vec2(dimensions.x + dimensions.width, dimensions.y + dimensions.height);
        quadPositions[3] = vec2(dimensions.x, dimensions.y + dimensions.height);

        static vec2[4] quadUVs;
        quadUVs[0] = vec2(region.x, region.y);
        quadUVs[1] = vec2(region.x + region.width, region.y);
        quadUVs[2] = vec2(region.x + region.width, region.y + region.height);
        quadUVs[3] = vec2(region.x, region.y + region.height);

        static Vertex2d[4] vertices;
        static uint[6] indices;

        for (size_t i; i < 4; ++i)
            vertices[i] = Vertex2d(quadPositions[i], quadUVs[i], modulate);

        indices[0] = 2;
        indices[1] = 1;
        indices[2] = 0;
        indices[3] = 0;
        indices[4] = 3;
        indices[5] = 2;

        GraphicsSubsystem.callbacks.r2dDrawVertices(vertices, indices, transform, texture, material);
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
    pragma(inline, true) void drawString2d(T)(in T text, in BitmapFont font, in vec2 position,
        in color modulate = color.white,
        ubyte alignment = BitmapFont.Alignment.left | BitmapFont.Alignment.top,
        in Material material = null)
        if (isSomeString!T)
    {
        vec2 cursor = vec2.zero;

        if (alignment & BitmapFont.Alignment.middle || alignment & BitmapFont.Alignment.bottom)
        {
            immutable int height = font.getTextHeight(text);
            cursor.y -= (alignment & BitmapFont.Alignment.middle) ? height / 2 : height;
        }

        foreach (T line; text.lineSplitter)
        {
            if (alignment & BitmapFont.Alignment.center || alignment & BitmapFont.Alignment.right)
            {
                immutable int width = font.getTextWidth(line);
                cursor.x = -((alignment & BitmapFont.Alignment.center) ? width / 2 : width);
            }
            else
                cursor.x = 0;

            for (size_t i; i < line.length; ++i)
            {
                switch (line[i])
                {
                case '\t':
                    cursor.x += 40;
                    break;

                default:
                    BitmapFont.Glyph c = font.getGlyph(line[i]);
                    if (c == BitmapFont.Glyph.init)
                        break;

                    immutable int kerning = i > 0 ? font.getKerning(line[i - 1], line[i]) : 1;

                    if (c.size.x > 0 && c.size.y > 0)
                    {
                        const(Texture2d) pageTexture = font.getPageTexture(c.pageIndex);

                        drawRect2d(rect(0, 0, c.size.x, c.size.y),
                            mat4.translation(vec3(vec2(position + cursor + vec2(c.offset.x,
                                c.offset.y)), 0)), modulate, pageTexture, material,
                            rect(c.uv1.x, c.uv1.y, c.uv2.x, c.uv2.y));
                    }

                    cursor.x += c.advance.x + kerning;
                }
            }

            cursor.y += font.lineHeight;
        }
    }

    static const(Camera) activeCamera() nothrow @nogc => mActiveCamera;
}
