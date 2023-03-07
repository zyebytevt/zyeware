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

/// The `Renderer2D` struct gives access to the 2D rendering API.
struct Renderer2D
{
    @disable this();
    @disable this(this);

private static:
    enum maxQuadsPerBatch = 5000;
    enum maxVerticesPerBatch = maxQuadsPerBatch * 4;
    enum maxIndicesPerBatch = maxQuadsPerBatch * 6;

    struct QuadVertex
    {
        Vector4f position;
        Color color;
        Vector2f uv;
        float textureIndex;
    }

    bool sOldCullingValue;

    Shader sDefaultShader;
    BufferGroup[] sBatchBuffers;
    size_t sActiveBatchBufferIndex;
    ConstantBuffer sMatrixData;

    QuadVertex[maxVerticesPerBatch] sBatchVertices;
    uint[maxIndicesPerBatch] sBatchIndices;
    size_t sCurrentQuad;

    Rebindable!(const Texture2D)[] sBatchTextures;
    size_t sNextFreeTexture = 1; // because 0 is the white texture

    size_t getIndexForTexture(in Texture2D texture) nothrow
    {
        for (size_t i = 1; i < sNextFreeTexture; ++i)
            if (texture is sBatchTextures[i])
                return i;

        if (sNextFreeTexture == sBatchTextures.length)
            return size_t.max;

        sBatchTextures[sNextFreeTexture++] = texture;
        return sNextFreeTexture - 1;
    }

package(zyeware) static:
    void initialize()
    {
        sBatchTextures = new Rebindable!(const Texture2D)[8];

        sMatrixData = ConstantBuffer.create(BufferLayout([
            BufferElement("viewProjection", BufferElement.Type.mat4)
        ]));

        for (size_t i; i < 2; ++i)
        {
            auto batchBuffer = BufferGroup.create();

            batchBuffer.dataBuffer = DataBuffer.create(maxVerticesPerBatch * QuadVertex.sizeof, BufferLayout([
                BufferElement("aPosition", BufferElement.Type.vec4),
                BufferElement("aColor", BufferElement.Type.vec4),
                BufferElement("aUV", BufferElement.Type.vec2),
                BufferElement("aTexIndex", BufferElement.Type.float_)
            ]), Yes.dynamic);

            batchBuffer.indexBuffer = IndexBuffer.create(maxIndicesPerBatch * uint.sizeof, Yes.dynamic);

            sBatchBuffers ~= batchBuffer;
        }

        // To circumvent a bug in MacOS builds that require a VAO to be bound before validating a
        // shader program in OpenGL. Due to Renderer2D being initialized early during the
        // engines lifetime, this should fix all further shader loadings.
        sBatchBuffers[0].bind();
        
        sDefaultShader = AssetManager.load!Shader("core://shaders/2d/default.shd");

        static ubyte[3] pixels = [255, 255, 255];
        sBatchTextures[0] = Texture2D.create(new Image(pixels, 3, 8, Vector2i(1)), TextureProperties.init);
    }

    void cleanup()
    {
        sDefaultShader.dispose();
        sBatchTextures[0].dispose();
        sBatchTextures.dispose();

        foreach (BufferGroup buffer; sBatchBuffers)
            buffer.dispose();
    }

public static:
    /// Starts a 2D scene. This must be called before any 2D drawing commands.
    ///
    /// Params:
    ///     projectionMatrix = A 4x4 matrix used for projection.
    ///     viewMatrix = A 4x4 matrix used for view.
    void begin(in Matrix4f projectionMatrix, in Matrix4f viewMatrix)
    {
        debug enforce!RenderException(pCurrentRenderer == CurrentRenderer.none,
            "A renderer is currently active, cannot begin.");

        sMatrixData.bind(ConstantBuffer.Slot.matrices);
        sMatrixData.setData(sMatrixData.getEntryOffset("viewProjection"),
            (projectionMatrix * viewMatrix).matrix);

        RenderAPI.setFlag(RenderFlag.depthTesting, false);
        sOldCullingValue = RenderAPI.getFlag(RenderFlag.culling);
        RenderAPI.setFlag(RenderFlag.culling, false);

        debug pCurrentRenderer = CurrentRenderer.renderer2D;
    }

    /// Ends a 2D scene. This must be called at the end of all 2D drawing commands, as it flushes
    /// everything to the screen.
    void end()
    {
        debug enforce!RenderException(pCurrentRenderer == CurrentRenderer.renderer2D,
        "2D renderer is not active, cannot end.");

        flush();

        RenderAPI.setFlag(RenderFlag.culling, sOldCullingValue);

        debug pCurrentRenderer = CurrentRenderer.none;
    }

    /// Flushes all currently cached drawing commands to the screen.
    void flush()
    {
        debug enforce!RenderException(pCurrentRenderer == CurrentRenderer.renderer2D,
            "2D renderer is not active, cannot flush.");

        BufferGroup activeGroup = sBatchBuffers[sActiveBatchBufferIndex++];
        sActiveBatchBufferIndex %= sBatchBuffers.length;

        activeGroup.bind();
        activeGroup.dataBuffer.setData(sBatchVertices);
        activeGroup.indexBuffer.setData(sBatchIndices);

        sDefaultShader.bind();

        for (int i = 0; i < sNextFreeTexture; ++i)
            sBatchTextures[i].bind(i);
        
        RenderAPI.drawIndexed(sCurrentQuad * 6);

        sCurrentQuad = 0;
        sNextFreeTexture = 1;
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
        drawRect(dimensions, Matrix4f.translation(Vector3f(position, 0)) * Matrix4f.scaling(scale.x, scale.y, 1),
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
        drawRect(dimensions, Matrix4f.translation(Vector3f(position, 0)) * Matrix4f.rotation(rotation, Vector3f(0, 0, 1))
            * Matrix4f.scaling(scale.x, scale.y, 1), modulate, texture, region);
    }

    /// Draws a rectangle.
    ///
    /// Params:
    ///     dimensions = The dimensions of the rectangle to draw.
    ///     transform = A 4x4 matrix used for transformation of the rectangle.
    ///     modulate = The color of the rectangle. If a texture is suppliedW, it will be tinted in this color.
    ///     texture = The texture to use. If `null`, draws a blank rectangle.
    ///     region = The region of the rectangle to use. Has no effect if no texture is supplied.
    void drawRect(in Rect2f dimensions, in Matrix4f transform, in Color modulate = Vector4f(1), in Texture2D texture = null,
        in Rect2f region = Rect2f(0, 0, 1, 1))
    {
        debug enforce!RenderException(pCurrentRenderer == CurrentRenderer.renderer2D,
            "2D renderer is not active, cannot draw.");

        static Vector4f[4] quadPositions; 
        quadPositions[0] = Vector4f(dimensions.min.x, dimensions.min.y, 0.0f, 1);
        quadPositions[1] = Vector4f(dimensions.max.x, dimensions.min.y, 0.0f, 1);
        quadPositions[2] = Vector4f(dimensions.max.x, dimensions.max.y, 0.0f, 1);
        quadPositions[3] = Vector4f(dimensions.min.x, dimensions.max.y, 0.0f, 1);
            
        static Vector2f[4] quadUVs;
        quadUVs[0] = Vector2f(region.min.x, region.min.y);
        quadUVs[1] = Vector2f(region.max.x, region.min.y);
        quadUVs[2] = Vector2f(region.max.x, region.max.y);
        quadUVs[3] = Vector2f(region.min.x, region.max.y);

        if (sCurrentQuad == maxQuadsPerBatch)
            flush();

        float texIdx = 0;
        if (texture)
        {
            size_t idx = getIndexForTexture(texture);
            if (idx == size_t.max) // No more room for new textures
            {
                flush();
                idx = getIndexForTexture(texture);
            }

            texIdx = cast(float) idx;
        }

        for (size_t i; i < 4; ++i)
            sBatchVertices[sCurrentQuad * 4 + i] = QuadVertex(transform * quadPositions[i], modulate,
                quadUVs[i], texIdx);

        immutable uint currentQuadIndex = cast(uint) sCurrentQuad * 4;
        immutable size_t baseIndex = sCurrentQuad * 6;
        
        sBatchIndices[baseIndex] = currentQuadIndex + 2;
        sBatchIndices[baseIndex + 1] = currentQuadIndex + 1;
        sBatchIndices[baseIndex + 2] = currentQuadIndex;
        sBatchIndices[baseIndex + 3] = currentQuadIndex;
        sBatchIndices[baseIndex + 4] = currentQuadIndex + 3;
        sBatchIndices[baseIndex + 5] = currentQuadIndex + 2;

        ++sCurrentQuad;

        version (ZW_Profiling) ++Profiler.currentWriteData.renderData.rectCount;
    }

    /// Draws some string to the screen.
    ///
    /// Params:
    ///     text = The text to draw. May be of any string type.
    ///     font = The font to use.
    ///     position = 2D position where to draw the text to.
    ///     modulate = The color of the text.
    ///     alignment = How to align the text. Horizontal and vertical alignment can be OR'd together.
    pragma(inline, true)
    void drawString(T)(in T text, in Font font, in Vector2f position, in Color modulate = Color.white,
        ubyte alignment = Font.Alignment.left | Font.Alignment.top)
        if (isSomeString!T)
    {
        Vector2f cursor = Vector2f(0);

        if (alignment & Font.Alignment.middle || alignment & Font.Alignment.bottom)
        {
            immutable int height = font.getTextHeight(text);
            cursor.y -= (alignment & Font.Alignment.middle) ? height / 2 : height;
        }

        foreach (T line; text.lineSplitter)
        {
            if (alignment & Font.Alignment.center || alignment & Font.Alignment.right)
            {
                immutable int width = font.getTextWidth(line);
                cursor.x = -((alignment & Font.Alignment.center) ? width / 2 : width);
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
                        BMFont.Char c = font.bmFont.getChar(line[i]);
                        if (c == BMFont.Char.init)
                            break;

                        immutable int kerning = i > 0 ? font.bmFont.getKerning(line[i - 1], line[i]) : 1;

                        const(Texture2D) pageTexture = font.getPageTexture(c.page);
                        immutable Vector2f size = pageTexture.size;

                        immutable Rect2f region = Rect2f(cast(float) c.x / size.x, cast(float) c.y / size.y,
                            cast(float) (c.x + c.width) / size.x, cast(float) (c.y + c.height) / size.y);

                        drawRect(Rect2f(0, 0, c.width, c.height), Matrix4f.translation(Vector3f(Vector2f(position + cursor + Vector2f(c.xoffset, c.yoffset)), 0)),
                            modulate, pageTexture, region);

                        cursor.x += c.xadvance + kerning;
                }
            }

            cursor.y += font.bmFont.common.lineHeight;
        }
    }
}

debug
{
    /// This enum and associated variable is used to keep track
    /// which of the renderers has the current "context", as mixing
    /// submit and render calls is undocumented behavior.
    enum CurrentRenderer : ubyte
    {
        none,
        renderer2D,
        renderer3D
    }

    CurrentRenderer pCurrentRenderer;
}