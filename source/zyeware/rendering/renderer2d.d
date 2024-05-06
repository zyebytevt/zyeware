// This file is part of the ZyeWare Game Engine, and subject to the terms
// and conditions defined in the file 'LICENSE.txt', which is part
// of this source code package.
//
// Copyright © 2021-2024 ZyeByte. All rights reserved.
module zyeware.rendering.renderer2d;

import std.traits : isSomeString;
import std.typecons : Rebindable, rebindable;
import std.sumtype : match;

import zyeware;
import zyeware.subsystems.graphics;

struct Renderer2d
{
private static:
    Rebindable!(const Camera) sCamera;
    recti sViewport;
    bool sBatchActive;

    BufferGroup[2] sRenderBuffers;
    Batch[] sBatches;
    Rebindable!(const Material) sDefaultMaterial;

    Texture2d sWhiteTexture;

    BufferGroup createRenderBuffer()
    {
        auto dataBuffer = new DataBuffer(BatchVertex.sizeof * Batch.maxVertices, BufferLayout([
            BufferElement(BufferElement.Type.vec4),
            BufferElement(BufferElement.Type.vec2),
            BufferElement(BufferElement.Type.vec4),
            BufferElement(BufferElement.Type.float_),
        ]), Yes.dynamic);

        auto IndexBuffer = new IndexBuffer(uint.sizeof * Batch.maxIndices, Yes.dynamic);

        return new BufferGroup(dataBuffer, IndexBuffer);
    }

package(zyeware) static:
    void load()
    {
        static ubyte[3] pixels = [255, 255, 255];
        sWhiteTexture = new Texture2d(new Image(pixels, 3, 8, vec2i(1)), TextureProperties.init);
    
        for (size_t i; i < sRenderBuffers.length; ++i)
            sRenderBuffers[i] = createRenderBuffer();

        sBatches ~= Batch(sWhiteTexture);

        sDefaultMaterial = rebindable(AssetManager.load!Material("core:materials/2d/default.mtl"));
    }

    void unload()
    {

    }

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
    void begin(in Camera camera, in recti viewport = recti.identity)
    in (!sBatchActive,
        "A 2D render batch is already active. Call `end2d` before starting a new batch.")
    {
        immutable mat4 projectionMatrix = camera ? camera.getProjectionMatrix() : mat4.orthographic(0,
            1, 1, 0, -1, 1);
        immutable mat4 viewMatrix = camera ? camera.getViewMatrix() : mat4.identity;

        sCamera = camera;
        begin(projectionMatrix, viewMatrix, viewport);
    }

    /// Starts batching render commands. Must be called before any rendering is done.
    ///
    /// Params:
    ///     projectionMatrix = The projection matrix to use.
    ///     viewMatrix = The view matrix to use.
    void begin(in mat4 projectionMatrix, in mat4 viewMatrix = mat4.identity, in recti viewport = recti.identity)
    {
        sViewport = viewport;
        sBatchActive = true;

        GraphicsSubsystem.callbacks.setViewport(sViewport);
    }

    /// Ends batching render commands. Calling this results in all render commands being flushed to the GPU.
    void end()
    {
        sCamera = null;
        sBatchActive = false;
    }

    /// Draws a mesh.
    ///
    /// Params:
    ///     mesh = The mesh to draw.
    ///     position = 2D transform where to draw the mesh to.
    pragma(inline, true) void drawMesh(in Mesh2d mesh, in mat4 transform)
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
    pragma(inline, true) void drawRect(in rect dimensions, in vec2 position, in vec2 scale,
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
    pragma(inline, true) void drawRect(in rect dimensions, in vec2 position, in vec2 scale,
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
    pragma(inline, true) void drawRect(in rect dimensions, in mat4 transform,
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
    pragma(inline, true) void drawString(T)(in T text, in BitmapFont font, in vec2 position,
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

    static const(Camera) camera() nothrow @nogc => sCamera;
    static recti viewport() nothrow @nogc => sViewport;
}

private:

struct BatchVertex
{
    vec4 position;
    color modulate;
    vec2 uv;
    float textureIndex;
}

struct Batch
{
    enum maxTextures = 8;
    enum maxVertices = 20000;
    enum maxIndices = 30000;

    Signal!() mustFlush;

    Rebindable!(const Material) material;
    BatchVertex[] vertices;
    uint[] indices;
    Rebindable!(const Texture2d)[] textures;

    this(in Texture2d whiteTexture)
    {
        textures.reserve(maxTextures);
        vertices.reserve(maxVertices);
        indices.reserve(maxIndices);

        textures ~= rebindable(whiteTexture);
    }

    size_t getIndexForTexture(in Texture2d texture)
    {
        for (size_t i = 1; i < textures.length; ++i)
            if (texture is textures[i])
                return i;

        if (textures.length >= maxTextures)
            mustFlush();

        textures ~= rebindable(texture);
        return textures.length - 1;
    }

    void addVertices(in BatchVertex[] vertices)
    {
        if (vertices.length + this.vertices.length >= maxVertices)
            mustFlush();

        foreach (const ref vertex; vertices)
            this.vertices ~= vertex;
    }

    void addIndices(in uint[] indices)
    {
        if (indices.length + this.indices.length >= maxIndices)
            mustFlush();

        foreach (const ref index; indices)
            this.indices ~= index;
    }

    void flush(BufferGroup bufferGroup, in mat4 projectionView)
    {
        bufferGroup.bind();

        bufferGroup.dataBuffer.update(vertices);
        bufferGroup.indexBuffer.update(indices);

        auto shader = material.shader;
        shader.bind();

        shader.setUniform("iProjectionView", projectionView);
        shader.setUniform("iTextureCount", cast(int) textures.length);
        shader.setUniform("iTime", ZyeWare.upTime.toFloatSeconds);

        foreach (string parameter; material.parameterList)
        {
             material.getParameter(parameter).match!(
                (const(void[]) value) {},
                (int value) { shader.setUniform(parameter, value); },
                (float value) { shader.setUniform(parameter, value); },
                (vec2 value) { shader.setUniform(parameter, value); },
                (vec3 value) { shader.setUniform(parameter, value); },
                (vec4 value) { shader.setUniform(parameter, value); }
            );
        }

        foreach (size_t i, texture; textures)
            texture.bind(i);

        GraphicsSubsystem.callbacks.drawIndexed(DrawMode.triangles, indices.length);

        material = null;
        vertices.length = 0;
        indices.length = 0;
        textures.length = 1;
    }
}