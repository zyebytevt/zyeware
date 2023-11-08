module zyeware.pal.renderer.opengl.renderer2d;

import std.traits : isSomeString;
import std.string : lineSplitter;
import std.typecons : Rebindable;

import bindbc.opengl;
import bmfont : BMFont = Font;

import zyeware.common;
import zyeware.rendering;
import zyeware.pal.renderer.callbacks;
import zyeware.pal.graphics.callbacks;
import zyeware.pal.graphics.opengl;
import zyeware.pal.graphics.types;

private:

enum maxMaterialsPerDrawCall = 8;
enum maxMaterialsPerBatch = 8;
enum maxVerticesPerBatch = 20000;
enum maxIndicesPerBatch = 30000;

struct BatchVertex2D
{
    Vector4f position;
    Color color;
    Vector2f uv;
    float textureIndex;
}

struct GlBuffer
{
    uint vao;
    uint vbo;
    uint ibo;
}

struct Batch
{
    Rebindable!(const Material) material;

    BatchVertex2D[] vertices;
    uint[] indices;
    Rebindable!(const Texture2D)[] textures;

    size_t currentVertexCount = 0;
    size_t currentIndexCount = 0;
    size_t currentTextureCount = 1; // because 0 is the white texture

    size_t getIndexForTexture(in Texture2D texture) nothrow
    {
        for (size_t i = 1; i < currentTextureCount; ++i)
            if (texture is textures[i])
                return i;

        if (currentTextureCount == textures.length)
            return size_t.max;

        textures[currentTextureCount++] = texture;
        return currentTextureCount - 1;
    }

    void flush(in GlBuffer buffer)
    {
        glBindVertexArray(buffer.vao);

        glBindBuffer(GL_ARRAY_BUFFER, buffer.vbo);
        glBufferSubData(GL_ARRAY_BUFFER, 0, currentVertexCount * BatchVertex2D.sizeof, cast(void*) vertices.ptr);

        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, buffer.ibo);
        glBufferSubData(GL_ELEMENT_ARRAY_BUFFER, 0, currentIndexCount * uint.sizeof, cast(void*) indices.ptr);

        auto shader = material.shader;

        glUseProgram(*(cast(uint*) shader.handle));
        palGlSetShaderUniformMat4f(shader.handle, "iProjectionView", pProjectionViewMatrix);
        palGlSetShaderUniform1i(shader.handle, "iTextureCount", cast(int) currentTextureCount);
        palGlSetShaderUniform1f(shader.handle, "iTime", ZyeWare.upTime.toFloatSeconds);

        foreach (string parameter; material.parameterList)
        {
            import std.sumtype : match;

            material.getParameter(parameter).match!(
                (const(void[]) value) {},
                (int value) { palGlSetShaderUniform1i(shader.handle, parameter, value); },
                (float value) { palGlSetShaderUniform1f(shader.handle, parameter, value); },
                (Vector2f value) { palGlSetShaderUniform2f(shader.handle, parameter, value); },
                (Vector3f value) { palGlSetShaderUniform3f(shader.handle, parameter, value); },
                (Vector4f value) { palGlSetShaderUniform4f(shader.handle, parameter, value); }
            );
        }

        for (uint i; i < currentTextureCount; ++i)
        {
            glActiveTexture(GL_TEXTURE0 + i);
            glBindTexture(GL_TEXTURE_2D, *(cast(uint*) textures[i].handle));
        }

        glDrawElements(GL_TRIANGLES, cast(int) currentIndexCount, GL_UNSIGNED_INT, null);

        material = null;

        currentVertexCount = 0;
        currentIndexCount = 0;
        currentTextureCount = 1;
    }
}

// Buffers important for rendering
GlBuffer[2] pRenderBuffers;
Batch[maxMaterialsPerDrawCall] pBatches;
size_t currentMaterialCount = 0;

Matrix4f pProjectionViewMatrix;
Texture2D pWhiteTexture;
Material pDefaultMaterial;

size_t getIndexForMaterial(in Material material) nothrow
{
    for (size_t i = 0; i < currentMaterialCount; ++i)
        if (material is pBatches[i].material)
            return i;

    if (currentMaterialCount == pBatches.length)
        return size_t.max;

    pBatches[currentMaterialCount++].material = material;
    return currentMaterialCount - 1;
}

void createBuffer(ref GlBuffer buffer)
{
    glGenVertexArrays(1, &buffer.vao);
    glBindVertexArray(buffer.vao);

    glGenBuffers(1, &buffer.vbo);
    glBindBuffer(GL_ARRAY_BUFFER, buffer.vbo);
    glBufferData(GL_ARRAY_BUFFER, maxVerticesPerBatch * BatchVertex2D.sizeof, null, GL_DYNAMIC_DRAW);

    glEnableVertexAttribArray(0);
    glVertexAttribPointer(0, 4, GL_FLOAT, GL_FALSE, BatchVertex2D.sizeof, cast(void*)BatchVertex2D.position.offsetof);
    glEnableVertexAttribArray(1);
    glVertexAttribPointer(1, 4, GL_FLOAT, GL_FALSE, BatchVertex2D.sizeof, cast(void*)BatchVertex2D.color.offsetof);
    glEnableVertexAttribArray(2);
    glVertexAttribPointer(2, 2, GL_FLOAT, GL_FALSE, BatchVertex2D.sizeof, cast(void*)BatchVertex2D.uv.offsetof);
    glEnableVertexAttribArray(3);
    glVertexAttribPointer(3, 1, GL_FLOAT, GL_FALSE, BatchVertex2D.sizeof, cast(void*)BatchVertex2D.textureIndex.offsetof);
    
    glGenBuffers(1, &buffer.ibo);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, buffer.ibo);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, maxIndicesPerBatch * uint.sizeof, null, GL_DYNAMIC_DRAW);
}

// TODO: Font rendering needs to be improved.
void drawStringImpl(T)(in T text, in Font font, in Vector2f position, in Color modulate, ubyte alignment, in Material material)
    if (isSomeString!T)
{
    Vector2f cursor = Vector2f.zero;

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
                        cast(float) c.width / size.x, cast(float) c.height / size.y);

                    drawRectangle(Rect2f(0, 0, c.width, c.height), Matrix4f.translation(Vector3f(Vector2f(position + cursor + Vector2f(c.xoffset, c.yoffset)), 0)),
                        modulate, pageTexture, material, region);

                    cursor.x += c.xadvance + kerning;
            }
        }

        cursor.y += font.bmFont.common.lineHeight;
    }
}

/// Initializes the renderer.
void initialize()
{
    for (size_t i; i < pRenderBuffers.length; ++i)
        createBuffer(pRenderBuffers[i]);

    // To circumvent a bug in MacOS builds that require a VAO to be bound before validating a
    // shader program in OpenGL. Due to Renderer2D being initialized early during the
    // engines lifetime, this should fix all further shader loadings.
    glBindVertexArray(pRenderBuffers[0].vao);

    static ubyte[3] pixels = [255, 255, 255];
    pWhiteTexture = new Texture2D(new Image(pixels, 3, 8, Vector2i(1)), TextureProperties.init);

    for (size_t i; i < pBatches.length; ++i)
    {
        pBatches[i].vertices = new BatchVertex2D[maxVerticesPerBatch + 2000];
        pBatches[i].indices = new uint[maxIndicesPerBatch + 3000];
        pBatches[i].textures = new Rebindable!(const Texture2D)[maxMaterialsPerBatch];

        pBatches[i].textures[0] = pWhiteTexture;
    }

    pDefaultMaterial = AssetManager.load!Material("core://materials/2d/default.mtl");
}

void cleanup()
{
    destroy(pWhiteTexture);

    for (size_t i; i < pBatches.length; ++i)
    {
        destroy(pBatches[i].vertices);
        destroy(pBatches[i].indices);
        destroy(pBatches[i].textures);
    }

    for (size_t i; i < pRenderBuffers.length; ++i)
    {
        glDeleteVertexArrays(1, &pRenderBuffers[i].vao);
        glDeleteBuffers(1, &pRenderBuffers[i].vbo);
        glDeleteBuffers(1, &pRenderBuffers[i].ibo);
    }
}

void beginScene(in Matrix4f projectionMatrix, in Matrix4f viewMatrix)
{
    pProjectionViewMatrix = projectionMatrix * viewMatrix;

    palGlSetRenderFlag(RenderFlag.culling, false);
}

void endScene()
{
    flush();
}

void flush()
{
    if (currentMaterialCount == 0)
        return;

    size_t currentBufferIndex = 0;
    for (size_t i; i < currentMaterialCount; ++i)
    {
        if (pBatches[i].currentVertexCount == 0)
            continue;
        
        pBatches[i].flush(pRenderBuffers[currentBufferIndex]);
        currentBufferIndex = (currentBufferIndex + 1) % 2;
    }

    currentMaterialCount = 0;
}

void drawRectangle(in Rect2f dimensions, in Matrix4f transform, in Color modulate = Vector4f(1),
    in Texture2D texture = null, in Material material = null, in Rect2f region = Rect2f(0, 0, 1, 1))
{
    const(Material) mat = material ? material : pDefaultMaterial;

    size_t batchIndex = getIndexForMaterial(mat);
    if (batchIndex == size_t.max)
    {
        flush();
        batchIndex = getIndexForMaterial(mat);
    }
    
    Batch* batch = &pBatches[batchIndex];
    if (batch.material !is mat)
        batch.material = mat;

    if (batch.currentVertexCount >= maxVerticesPerBatch)
        flush();

    float texIdx;
    if (texture)
    {
        size_t idx = batch.getIndexForTexture(texture);
        if (idx == size_t.max) // No more room for new textures
        {
            flush();
            idx = batch.getIndexForTexture(texture);
        }

        texIdx = cast(float) idx;
    }

    static Vector4f[4] quadPositions;
    quadPositions[0] = Vector4f(dimensions.position.x, dimensions.position.y, 0, 1);
    quadPositions[1] = Vector4f(dimensions.position.x + dimensions.size.x, dimensions.position.y, 0, 1);
    quadPositions[2] = Vector4f(dimensions.position.x + dimensions.size.x, dimensions.position.y + dimensions.size.y, 0, 1);
    quadPositions[3] = Vector4f(dimensions.position.x, dimensions.position.y + dimensions.size.y, 0, 1);

    static Vector2f[4] quadUVs;
    quadUVs[0] = Vector2f(region.position.x, region.position.y);
    quadUVs[1] = Vector2f(region.position.x + region.size.x, region.position.y);
    quadUVs[2] = Vector2f(region.position.x + region.size.x, region.position.y + region.size.y);
    quadUVs[3] = Vector2f(region.position.x, region.position.y + region.size.y);

    for (size_t i; i < 4; ++i)
        batch.vertices[batch.currentVertexCount + i] = BatchVertex2D(transform * quadPositions[i], modulate,
            quadUVs[i], texIdx);

    batch.indices[batch.currentIndexCount + 0] = cast(uint) batch.currentVertexCount + 2;
    batch.indices[batch.currentIndexCount + 1] = cast(uint) batch.currentVertexCount + 1;
    batch.indices[batch.currentIndexCount + 2] = cast(uint) batch.currentVertexCount + 0;
    batch.indices[batch.currentIndexCount + 3] = cast(uint) batch.currentVertexCount + 0;
    batch.indices[batch.currentIndexCount + 4] = cast(uint) batch.currentVertexCount + 3;
    batch.indices[batch.currentIndexCount + 5] = cast(uint) batch.currentVertexCount + 2;

    batch.currentIndexCount += 6;
    batch.currentVertexCount += 4;

    // TODO: Add to profiler rect count
}

void drawString(in string text, in Font font, in Vector2f position, in Color modulate = Color.white,
    ubyte alignment = Font.Alignment.left | Font.Alignment.top, in Material material = null)
{
    drawStringImpl!string(text, font, position, modulate, alignment, material);
}

void drawWString(in wstring text, in Font font, in Vector2f position, in Color modulate = Color.white,
    ubyte alignment = Font.Alignment.left | Font.Alignment.top, in Material material = null)
{
    drawStringImpl!wstring(text, font, position, modulate, alignment, material);
}

void drawDString(in dstring text, in Font font, in Vector2f position, in Color modulate = Color.white,
    ubyte alignment = Font.Alignment.left | Font.Alignment.top, in Material material = null)
{
    drawStringImpl!dstring(text, font, position, modulate, alignment, material);
}

public:

Renderer2DCallbacks generateRenderer2DPALCallbacks()
{
    return Renderer2DCallbacks(
        &initialize,
        &cleanup,
        &beginScene,
        &endScene,
        &flush,
        &drawRectangle,
        &drawString,
        &drawWString,
        &drawDString
    );
}