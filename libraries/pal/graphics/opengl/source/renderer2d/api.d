module zyeware.pal.graphics.opengl.renderer2d.api;

import std.traits : isSomeString;
import std.string : lineSplitter;
import std.typecons : Rebindable;

import bindbc.opengl;

import zyeware;

import zyeware.pal.graphics.types;

import zyeware.pal.graphics.opengl.api.api;
import zyeware.pal.graphics.opengl.renderer2d.types;

package(zyeware.pal.graphics.opengl):

enum maxMaterialsPerDrawCall = 8;
enum maxTexturesPerBatch = 8;
enum maxVerticesPerBatch = 20000;
enum maxIndicesPerBatch = 30000;

struct Batch
{
    Rebindable!(const Material) material;

    BatchVertex2D[] vertices;
    uint[] indices;
    Rebindable!(const Texture2d)[] textures;

    size_t currentVertexCount = 0;
    size_t currentIndexCount = 0;
    size_t currentTextureCount = 1; // because 0 is the white texture

    size_t getIndexForTexture(in Texture2d texture) nothrow
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
        setShaderUniformMat4f(shader.handle, "iProjectionView", pProjectionViewMatrix);
        setShaderUniform1i(shader.handle, "iTextureCount", cast(int) currentTextureCount);
        setShaderUniform1f(shader.handle, "iTime", ZyeWare.upTime.toFloatSeconds);

        foreach (string parameter; material.parameterList)
        {
            import std.sumtype : match;

            material.getParameter(parameter).match!(
                (const(void[]) value) {},
                (int value) { setShaderUniform1i(shader.handle, parameter, value); },
                (float value) { setShaderUniform1f(shader.handle, parameter, value); },
                (vec2 value) { setShaderUniform2f(shader.handle, parameter, value); },
                (vec3 value) { setShaderUniform3f(shader.handle, parameter, value); },
                (vec4 value) { setShaderUniform4f(shader.handle, parameter, value); }
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
Batch[] pBatches;
size_t currentMaterialCount = 0;

mat4 pProjectionViewMatrix;
Texture2d pWhiteTexture;
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
    glVertexAttribPointer(1, 2, GL_FLOAT, GL_FALSE, BatchVertex2D.sizeof, cast(void*)BatchVertex2D.uv.offsetof);
    glEnableVertexAttribArray(2);
    glVertexAttribPointer(2, 4, GL_FLOAT, GL_FALSE, BatchVertex2D.sizeof, cast(void*)BatchVertex2D.modulate.offsetof);
    glEnableVertexAttribArray(3);
    glVertexAttribPointer(3, 1, GL_FLOAT, GL_FALSE, BatchVertex2D.sizeof, cast(void*)BatchVertex2D.textureIndex.offsetof);
    
    glGenBuffers(1, &buffer.ibo);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, buffer.ibo);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, maxIndicesPerBatch * uint.sizeof, null, GL_DYNAMIC_DRAW);
}

// TODO: Font rendering needs to be improved.
void drawStringImpl(T)(in T text, in BitmapFont font, in vec2 position, in color modulate, ubyte alignment, in Material material)
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

                        drawRectangle(rect(0, 0, c.size.x, c.size.y), mat4.translation(vec3(vec2(position + cursor + vec2(c.offset.x, c.offset.y)), 0)),
                            modulate, pageTexture, material, rect(c.uv1.x, c.uv1.y, c.uv2.x, c.uv2.y));
                    }

                    cursor.x += c.advance.x + kerning;
            }
        }

        cursor.y += font.lineHeight;
    }
}

void initializeBatch(ref Batch batch)
{
    batch.vertices = new BatchVertex2D[maxVerticesPerBatch + 2000];
    batch.indices = new uint[maxIndicesPerBatch + 3000];
    batch.textures = new Rebindable!(const Texture2d)[maxTexturesPerBatch];

    batch.textures[0] = pWhiteTexture;
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
    pWhiteTexture = new Texture2d(new Image(pixels, 3, 8, vec2i(1)), TextureProperties.init);

    pBatches.length = 1;
    initializeBatch(pBatches[0]);

    pDefaultMaterial = AssetManager.load!Material("core:materials/2d/default.mtl");
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

void beginScene(in mat4 projectionMatrix, in mat4 viewMatrix)
{
    pProjectionViewMatrix = projectionMatrix * viewMatrix;

    setRenderFlag(RenderFlag.culling, false);
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

void drawVertices(in Vertex2D[] vertices, in uint[] indices, in mat4 transform,
    in Texture2d texture = null, in Material material = null)
{
    const(Material) mat = material ? material : pDefaultMaterial;

    size_t batchIndex = getIndexForMaterial(mat);
    if (batchIndex == size_t.max)
    {
        if (pBatches.length < maxMaterialsPerDrawCall)
        {
            pBatches.length += 1;
            initializeBatch(pBatches[pBatches.length - 1]);
            batchIndex = pBatches.length - 1;
        }
        else
        {
            flush();
            batchIndex = 0;
        }
    }

    Batch* batch = &pBatches[batchIndex];
    
    if (batch.currentVertexCount >= maxVerticesPerBatch)
        flush();
    
    if (batch.material !is mat)
        batch.material = mat;

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

    foreach (size_t i, const Vertex2D vertex; vertices)
        batch.vertices[batch.currentVertexCount + i] = BatchVertex2D(transform * vec4(vertex.position, 0, 1), vertex.uv, vertex.modulate, texIdx);

    foreach (size_t i, uint index; indices)
        batch.indices[batch.currentIndexCount + i] = cast(uint) batch.currentVertexCount + index;

    batch.currentVertexCount += vertices.length;
    batch.currentIndexCount += indices.length;
}

void drawRectangle(in rect dimensions, in mat4 transform, in color modulate = vec4(1),
    in Texture2d texture = null, in Material material = null, in rect region = rect(0, 0, 1, 1))
{
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

    static Vertex2D[4] vertices;
    static uint[6] indices;

    for (size_t i; i < 4; ++i)
        vertices[i] = Vertex2D(quadPositions[i], quadUVs[i], modulate);

    indices[0] = 2;
    indices[1] = 1;
    indices[2] = 0;
    indices[3] = 0;
    indices[4] = 3;
    indices[5] = 2;

    drawVertices(vertices, indices, transform, texture, material);
}

void drawString(in string text, in BitmapFont font, in vec2 position, in color modulate = color("white"),
    ubyte alignment = BitmapFont.Alignment.left | BitmapFont.Alignment.top, in Material material = null)
{
    drawStringImpl!string(text, font, position, modulate, alignment, material);
}

void drawWString(in wstring text, in BitmapFont font, in vec2 position, in color modulate = color("white"),
    ubyte alignment = BitmapFont.Alignment.left | BitmapFont.Alignment.top, in Material material = null)
{
    drawStringImpl!wstring(text, font, position, modulate, alignment, material);
}

void drawDString(in dstring text, in BitmapFont font, in vec2 position, in color modulate = color("white"),
    ubyte alignment = BitmapFont.Alignment.left | BitmapFont.Alignment.top, in Material material = null)
{
    drawStringImpl!dstring(text, font, position, modulate, alignment, material);
}