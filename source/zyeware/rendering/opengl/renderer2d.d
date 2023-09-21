module zyeware.rendering.opengl.renderer2d;

import std.traits : isSomeString;
import std.string : lineSplitter;
import std.typecons : Rebindable;

import zyeware.common;
import zyeware.rendering;

class OGLRenderer2D : Renderer2D
{
protected:
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

    struct Buffer
    {
        uint vao;
        uint vbo;
        uint ibo;
    }

    Buffer[2] mBuffers;
    size_t mActiveBuffer = 0;

    QuadVertex[maxVerticesPerBatch] mBatchVertices;
    uint[maxIndicesPerBatch] mBatchIndices;
    size_t mCurrentQuadCount = 0;

    Rebindable!(const Texture2D)[] mBatchTextures;
    size_t mNextFreeTexture = 1; // because 0 is the white texture
    bool mOldCullingValue;

    Shader mDefaultShader;
    Matrix4f mProjectionViewMatrix;

    size_t getIndexForTexture(in Texture2D texture) nothrow
    {
        for (size_t i = 1; i < mNextFreeTexture; ++i)
            if (texture is mBatchTextures[i])
                return i;

        if (mNextFreeTexture == mBatchTextures.length)
            return size_t.max;

        mBatchTextures[mNextFreeTexture++] = texture;
        return mNextFreeTexture - 1;
    }

    void createBuffer(ref Buffer buffer)
    {
        glGenVertexArrays(1, &buffer.vao);
        glBindVertexArray(buffer.vao);

        glGenBuffers(1, &buffer.vbo);
        glBindBuffer(GL_ARRAY_BUFFER, buffer.vbo);
        glBufferData(GL_ARRAY_BUFFER, maxVerticesPerBatch * QuadVertex.sizeof, null, GL_DYNAMIC_DRAW);

        glEnableVertexAttribArray(0);
        glVertexAttribPointer(0, 4, GL_FLOAT, GL_FALSE, QuadVertex.sizeof, cast(void*)QuadVertex.position.offsetof);
        glEnableVertexAttribArray(1);
        glVertexAttribPointer(1, 4, GL_FLOAT, GL_FALSE, QuadVertex.sizeof, cast(void*)QuadVertex.color.offsetof);
        glEnableVertexAttribArray(2);
        glVertexAttribPointer(2, 2, GL_FLOAT, GL_FALSE, QuadVertex.sizeof, cast(void*)QuadVertex.uv.offsetof);
        glEnableVertexAttribArray(3);
        glVertexAttribPointer(3, 1, GL_FLOAT, GL_FALSE, QuadVertex.sizeof, cast(void*)QuadVertex.textureIndex.offsetof);
        
        glGenBuffers(1, &buffer.ibo);
        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, buffer.ibo);
        glBufferData(GL_ELEMENT_ARRAY_BUFFER, maxIndicesPerBatch * uint.sizeof, null, GL_DYNAMIC_DRAW);
    }

    pragma(inline, true)
    void drawStringImpl(T)(in T text, in Font font, in Vector2f position, in Color modulate, ubyte alignment)
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
                            cast(float) (c.x + c.width) / size.x, cast(float) (c.y + c.height) / size.y);

                        drawRect(Rect2f(0, 0, c.width, c.height), Matrix4f.translation(Vector3f(Vector2f(position + cursor + Vector2f(c.xoffset, c.yoffset)), 0)),
                            modulate, pageTexture, region);

                        cursor.x += c.xadvance + kerning;
                }
            }

            cursor.y += font.bmFont.common.lineHeight;
        }
    }

public:
    /// Initializes the renderer.
    void initialize()
    {
        mBatchTextures = new Rebindable!(const Texture2D)[8];

        for (size_t i; i < mBuffers.length; ++i)
            createBuffer(mBuffers[i]);

        // To circumvent a bug in MacOS builds that require a VAO to be bound before validating a
        // shader program in OpenGL. Due to Renderer2D being initialized early during the
        // engines lifetime, this should fix all further shader loadings.
        glBindVertexArray(mBuffers[0].vao);

        mDefaultShader = AssetManager.load!Shader("core://shaders/2d/default.shd");

        static ubyte[3] pixels = [255, 255, 255];
        mBatchTextures[0] = new Texture2D(new Image(pixels, 3, 8, Vector2i(1)), TextureProperties.init);
    }

    void cleanup()
    {
        destroy(mBatchTextures[0]);

        for (size_t i; i < mBuffers.length; ++i)
        {
            glDeleteVertexArrays(1, &mBuffers[i].vao);
            glDeleteBuffers(1, &mBuffers[i].vbo);
            glDeleteBuffers(1, &mBuffers[i].ibo);
        }
    }

    void beginScene(in Matrix4f projectionMatrix, in Matrix4f viewMatrix)
    {
        mProjectionViewMatrix = projectionMatrix * viewMatrix;

        ZyeWare.graphics.api.setRenderFlag(RenderFlag.depthTesting, false);
        mOldCullingValue = ZyeWare.graphics.api.getRenderFlag(RenderFlag.culling);
        ZyeWare.graphics.api.setRenderFlag(RenderFlag.culling, false);
    }

    void endScene()
    {
        flush();

        ZyeWare.graphics.api.setRenderFlag(RenderFlag.culling, mOldCullingValue);
    }

    void flush()
    {
        Buffer* activeBuffer = &mBuffers[mActiveBuffer++];
        mActiveBuffer %= mBuffers.length;

        glBindVertexArray(activeBuffer.vao);

        glBindBuffer(GL_ARRAY_BUFFER, activeBuffer.vbo);
        glBufferSubData(GL_ARRAY_BUFFER, 0, mCurrentQuadCount * QuadVertex.sizeof * 4, cast(void*)mBatchVertices.ptr);

        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, activeBuffer.ibo);
        glBufferSubData(GL_ELEMENT_ARRAY_BUFFER, 0, mCurrentQuadCount * uint.sizeof * 6, cast(void*)mBatchIndices.ptr);

        mDefaultShader.bind();
        mDefaultShader.setUniform("iProjectionView", mProjectionViewMatrix);
        mDefaultShader.setUniform("iTextureCount", mNextFreeTexture);

        for (size_t i; i < mNextFreeTexture; ++i)
            mBatchTextures[i].bind(i);

        glDrawElements(GL_TRIANGLES, mCurrentQuadCount * 6, GL_UNSIGNED_INT, null);

        mCurrentQuadCount = 0;
        mNextFreeTexture = 1;
    }

    void drawRectangle(in Rect2f dimensions, in Matrix4f transform, in Color modulate = Vector4f(1),
        in Texture2D texture = null, in Rect2f region = Rect2f(0, 0, 1, 1))
    {
        if (mCurrentQuadCount == maxQuadsPerBatch)
            flush();

        float texIdx;
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

        static Vector4f[4] quadPositions;
        quadPositions[0] = Vector4f(dimensions.x, dimensions.y, 0, 1);
        quadPositions[1] = Vector4f(dimensions.x + dimensions.width, dimensions.y, 0, 1);
        quadPositions[2] = Vector4f(dimensions.x + dimensions.width, dimensions.y + dimensions.height, 0, 1);
        quadPositions[3] = Vector4f(dimensions.x, dimensions.y + dimensions.height, 0, 1);

        static Vector2f[4] quadUVs;
        quadUVs[0] = Vector2f(region.x, region.y);
        quadUVs[1] = Vector2f(region.x + region.width, region.y);
        quadUVs[2] = Vector2f(region.x + region.width, region.y + region.height);
        quadUVs[3] = Vector2f(region.x, region.y + region.height);

        for (size_t i; i < 4; ++i)
            sBatchVertices[sCurrentQuad * 4 + i] = QuadVertex(transform * quadPositions[i], modulate,
                quadUVs[i], texIdx);

        immutable uint currentQuadIndex = mCurrentQuadCount * 4;
        immutable size_t baseIndex = mCurrentQuadCount * 6;

        mBatchIndices[baseIndex + 0] = currentQuadIndex + 2;
        mBatchIndices[baseIndex + 1] = currentQuadIndex + 1;
        mBatchIndices[baseIndex + 2] = currentQuadIndex + 0;
        mBatchIndices[baseIndex + 3] = currentQuadIndex + 0;
        mBatchIndices[baseIndex + 4] = currentQuadIndex + 3;
        mBatchIndices[baseIndex + 5] = currentQuadIndex + 2;

        ++mCurrentQuadCount;

        // TODO: Add to profiler rect count
    }

    void drawString(in string text, in Font font, in Vector2f position, in Color modulate = Color.white,
        ubyte alignment = Font.Alignment.left | Font.Alignment.top)
    {
        drawStringImpl!string(text, font, position, modulate, alignment);
    }

    void drawWString(in wstring text, in Font font, in Vector2f position, in Color modulate = Color.white,
        ubyte alignment = Font.Alignment.left | Font.Alignment.top)
    {
        drawStringImpl!wstring(text, font, position, modulate, alignment);
    }

    void drawDString(in dstring text, in Font font, in Vector2f position, in Color modulate = Color.white,
        ubyte alignment = Font.Alignment.left | Font.Alignment.top)
    {
        drawStringImpl!dstring(text, font, position, modulate, alignment);
    }
}