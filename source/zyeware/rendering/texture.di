// This file is part of the ZyeWare Game Engine, and subject to the terms
// and conditions defined in the file 'LICENSE.txt', which is part
// of this source code package.
//
// Copyright 2021 ZyeByte
module zyeware.rendering.texture;

import zyeware.common;
import zyeware.rendering;

interface Texture
{
public:
    void bind(uint unit = 0) const;

    const(TextureProperties) properties() pure const nothrow;
    uint id() pure const nothrow;
}

@asset(Yes.cache)
class Texture2D : Texture
{
    this(in Image image, in TextureProperties properties);

    void bind(uint unit = 0) const;
    void setPixels(const(ubyte)[] pixels);

    const(TextureProperties) properties() pure const nothrow;
    uint id() pure const nothrow;

    Vector2i size() pure const nothrow;
    ubyte channels() pure const nothrow;

    static Texture2D load(string path);
}

@asset(Yes.cache)
class TextureCubeMap : Texture
{
    this(in Image[6] images, in TextureProperties properties);
    
    void bind(uint unit = 0) const;

    const(TextureProperties) properties() pure const nothrow;
    uint id() pure const nothrow;

    static TextureCubeMap load(string path);
}