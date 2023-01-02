module zyeware.rendering.properties;

import zyeware.common;
import zyeware.rendering;

struct WindowProperties
{
    string title = "ZyeWare Engine";
    Vector2ui size = Vector2ui(1280, 720);
    Image icon;
}

struct FramebufferProperties
{
    Vector2ui size;
    ubyte channels;
    bool swapChainTarget;
}

struct TextureProperties
{
    enum Filter
    {
        nearest,
        linear,
        bilinear,
        trilinear
    }

    enum WrapMode
    {
        repeat,
        mirroredRepeat,
        clampToEdge
    }

    Filter minFilter, magFilter;
    WrapMode wrapS, wrapT;
    bool generateMipmaps = true;
}

struct TerrainProperties
{
    Vector2f size;
    Vector2ui vertexCount;
    float[] heightData; // Row-major
    Texture2D[4] textures;
    Texture2D blendMap;
    Vector2f textureTiling = Vector2f(1);
}

enum RenderFlag
{
    depthTesting, /// Whether to use depth testing or not.
    depthBufferWriting, /// Whether to write to the depth buffer when drawing.
    culling, /// Whether culling is enabled or not.
    stencilTesting, /// Whether to use stencil testing or not.
    wireframe /// Whether to render in wireframe or not.
}

enum RenderCapability
{
    maxTextureSlots /// How many texture slots are available to use.
}