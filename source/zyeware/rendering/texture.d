// This file is part of the ZyeWare Game Engine, and subject to the terms
// and conditions defined in the file 'LICENSE.txt', which is part
// of this source code package.
//
// Copyright 2021 ZyeByte
module zyeware.rendering.texture;

import zyeware.common;
import zyeware.rendering;

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

interface Texture
{
public:
    void bind(uint unit = 0) const;

    const(TextureProperties) properties() pure const nothrow;
    uint id() pure const nothrow;
}

@asset(Yes.cache)
interface Texture2D : Texture
{
    void bind(uint unit = 0) const;
    void setPixels(const(ubyte)[] pixels);

    const(TextureProperties) properties() pure const nothrow;
    uint id() pure const nothrow;

    Vector2i size() pure const nothrow;
    ubyte channels() pure const nothrow;

    static Texture2D create(in Image image, in TextureProperties properties)
    {
        return RenderAPI.sCreateTexture2DImpl(image, properties);
    }

    static Texture2D load(string path)
    {
        return RenderAPI.sLoadTexture2DImpl(path);
    }
}

@asset(Yes.cache)
interface TextureCubeMap : Texture
{
    void bind(uint unit = 0) const;

    const(TextureProperties) properties() pure const nothrow;
    uint id() pure const nothrow;

    static TextureCubeMap create(in Image[6] images, in TextureProperties properties)
    {
        return RenderAPI.sCreateTextureCubeMapImpl(images, properties);
    }

    static TextureCubeMap load(string path)
    {
        return RenderAPI.sLoadTextureCubeMapImpl(path);
    }
}