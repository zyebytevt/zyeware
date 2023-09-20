module zyeware.rendering.opengl.renderer2d;

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

    Rebindable!(const Texture2D)[] mBatchTextures;
    size_t mNextFreeTexture = 1; // because 0 is the white texture

    Shader mDefaultShader;

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

public:
    void initialize()
    {
        mBatchTextures = new Rebindable!(const Texture2D)[8];

        mDefaultShader = AssetManager.load!Shader("core://shaders/2d/default.shd");

        static ubyte[3] pixels = [255, 255, 255];
        mBatchTextures[0] = new Texture2D(new Image(pixels, 3, 8, Vector2i(1)), TextureProperties.init);
    }

    void cleanup()
    {
        destroy(mBatchTextures[0]);
    }

    void beginScene(in Matrix4f projectionMatrix, in Matrix4f viewMatrix)
    {
        
    }

    void endScene()
    {

    }

    void drawRectangle(in Rect2f dimensions, in Matrix4f transform, in Color modulate = Vector4f(1),
        in Texture2D texture = null, in Rect2f region = Rect2f(0, 0, 1, 1))
    {
        
    }

    void drawString(in string text, in Font font, in Vector2f position, in Color modulate = Color.white,
        ubyte alignment = Font.Alignment.left | Font.Alignment.top)
    {

    }

    void drawWString(in wstring text, in Font font, in Vector2f position, in Color modulate = Color.white,
        ubyte alignment = Font.Alignment.left | Font.Alignment.top)
    {
        
    }

    void drawDString(in dstring text, in Font font, in Vector2f position, in Color modulate = Color.white,
        ubyte alignment = Font.Alignment.left | Font.Alignment.top)
    {
        
    }
}