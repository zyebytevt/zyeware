// This file is part of the ZyeWare Game Engine, and subject to the terms
// and conditions defined in the file 'LICENSE.txt', which is part
// of this source code package.
//
// Copyright 2021 ZyeByte
module zyeware.platform.opengl.renderer2d;

version (ZW_OpenGL):
package(zyeware.platform.opengl):

import std.traits : isSomeString;
import std.string : lineSplitter;
import std.typecons : Rebindable;
import std.exception : enforce;

import bmfont : BMFont = Font;

import zyeware.common;
import zyeware.core.debugging.profiler;
import zyeware.rendering;

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

bool pOldCullingValue;

Shader pDefaultShader;
BufferGroup[] pBatchBuffers;
size_t pActiveBatchBufferIndex;
ConstantBuffer pMatrixData;

QuadVertex[maxVerticesPerBatch] pBatchVertices;
uint[maxIndicesPerBatch] pBatchIndices;
size_t pCurrentQuad;

Rebindable!(const Texture2D)[] pBatchTextures;
size_t pNextFreeTexture = 1; // because 0 is the white texture

size_t r2dGetIndexForTexture(in Texture2D texture) nothrow
{
    for (size_t i = 1; i < pNextFreeTexture; ++i)
        if (texture is pBatchTextures[i])
            return i;

    if (pNextFreeTexture == pBatchTextures.length)
        return size_t.max;

    pBatchTextures[pNextFreeTexture++] = texture;
    return pNextFreeTexture - 1;
}

void r2dInitialize()
{
    pBatchTextures = new Rebindable!(const Texture2D)[8];

    pMatrixData = ConstantBuffer.create(BufferLayout([
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

        pBatchBuffers ~= batchBuffer;
    }

    // To circumvent a bug in MacOS builds that require a VAO to be bound before validating a
    // shader program in OpenGL. Due to Renderer2D being initialized early during the
    // engines lifetime, this should fix all further shader loadings.
    pBatchBuffers[0].bind();
    
    pDefaultShader = AssetManager.load!Shader("core://shaders/2d/default.shd");

    static ubyte[3] pixels = [255, 255, 255];
    pBatchTextures[0] = Texture2D.create(new Image(pixels, 3, 8, Vector2i(1)), TextureProperties.init);
}

void r2dCleanup()
{
    pDefaultShader.dispose();
    pBatchTextures[0].dispose();
    pBatchTextures.dispose();

    foreach (BufferGroup buffer; pBatchBuffers)
        buffer.dispose();
}

void r2dBegin(in Matrix4f projectionMatrix, in Matrix4f viewMatrix)
{
    debug enforce!RenderException(currentRenderer == CurrentRenderer.none,
        "A renderer is currently active, cannot begin.");

    pMatrixData.bind(ConstantBuffer.Slot.matrices);
    pMatrixData.setData(pMatrixData.getEntryOffset("viewProjection"),
        (projectionMatrix * viewMatrix).matrix);

    RenderAPI.setFlag(RenderFlag.depthTesting, false);
    pOldCullingValue = RenderAPI.getFlag(RenderFlag.culling);
    RenderAPI.setFlag(RenderFlag.culling, false);

    debug currentRenderer = CurrentRenderer.renderer2D;
}

void r2dEnd()
{
    debug enforce!RenderException(currentRenderer == CurrentRenderer.renderer2D,
        "2D renderer is not active, cannot end.");

    r2dFlush();

    RenderAPI.setFlag(RenderFlag.culling, pOldCullingValue);

    debug currentRenderer = CurrentRenderer.none;
}

void r2dFlush()
{
    debug enforce!RenderException(currentRenderer == CurrentRenderer.renderer2D,
        "2D renderer is not active, cannot flush.");

    BufferGroup activeGroup = pBatchBuffers[pActiveBatchBufferIndex++];
    pActiveBatchBufferIndex %= pBatchBuffers.length;

    activeGroup.bind();
    activeGroup.dataBuffer.setData(pBatchVertices);
    activeGroup.indexBuffer.setData(pBatchIndices);

    pDefaultShader.bind();

    for (int i = 0; i < pNextFreeTexture; ++i)
        pBatchTextures[i].bind(i);
    
    RenderAPI.drawIndexed(pCurrentQuad * 6);

    pCurrentQuad = 0;
    pNextFreeTexture = 1;
}

void r2dDrawRect(in Rect2f dimensions, in Matrix4f transform, in Color modulate = Vector4f(1), in Texture2D texture = null,
    in Rect2f region = Rect2f(0, 0, 1, 1))
{
    debug enforce!RenderException(currentRenderer == CurrentRenderer.renderer2D,
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

    if (pCurrentQuad == maxQuadsPerBatch)
        r2dFlush();

    float texIdx = 0;
    if (texture)
    {
        size_t idx = r2dGetIndexForTexture(texture);
        if (idx == size_t.max) // No more room for new textures
        {
            r2dFlush();
            idx = r2dGetIndexForTexture(texture);
        }

        texIdx = cast(float) idx;
    }

    for (size_t i; i < 4; ++i)
        pBatchVertices[pCurrentQuad * 4 + i] = QuadVertex(transform * quadPositions[i], modulate,
            quadUVs[i], texIdx);

    immutable uint currentQuadIndex = cast(uint) pCurrentQuad * 4;
    immutable size_t baseIndex = pCurrentQuad * 6;
    
    pBatchIndices[baseIndex] = currentQuadIndex + 2;
    pBatchIndices[baseIndex + 1] = currentQuadIndex + 1;
    pBatchIndices[baseIndex + 2] = currentQuadIndex;
    pBatchIndices[baseIndex + 3] = currentQuadIndex;
    pBatchIndices[baseIndex + 4] = currentQuadIndex + 3;
    pBatchIndices[baseIndex + 5] = currentQuadIndex + 2;

    ++pCurrentQuad;

    version (ZW_Profiling) ++Profiler.currentWriteData.renderData.rectCount;
}

void r2dDrawString(T)(in T text, in Font font, in Vector2f position, in Color modulate = Color.white,
    ubyte alignment = Font.Alignment.left | Font.Alignment.top)
    in (text && font)
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

                    r2dDrawRect(Rect2f(0, 0, c.width, c.height), Matrix4f.translation(Vector3f(Vector2f(position + cursor + Vector2f(c.xoffset, c.yoffset)), 0)),
                        modulate, pageTexture, region);

                    cursor.x += c.xadvance + kerning;
            }
        }

        cursor.y += font.bmFont.common.lineHeight;
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

    CurrentRenderer currentRenderer;
}