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

@asset(Yes.cache)
class Texture2D : Renderable
{
protected:
    RID mRid;
    TextureProperties mProperties;

public:
    this(in Image image, in TextureProperties properties = TextureProperties.init)
    {
        mProperties = properties;
        mRid = ZyeWare.graphics.api.createTexture2D(image, mProperties);
    }

    ~this()
    {
        ZyeWare.graphics.api.release(mRid);
    }

    const(TextureProperties) properties() pure const nothrow
    {
        return mProperties;
    }

    RID rid() pure const nothrow
    {
        return mRid;
    }

    static Texture2D load(string path)
    {
        return new Texture2D(AssetManager.load!Image(path));
    }
}

@asset(Yes.cache)
class TextureCubeMap : Renderable
{
protected:
    RID mRid;
    TextureProperties mProperties;

public:
    this(in Image[6] images, in TextureProperties properties = TextureProperties.init)
    {
        mProperties = properties;
        mRid = ZyeWare.graphics.api.createTextureCubeMap(images, properties);
    }

    ~this()
    {
        ZyeWare.graphics.api.release(mRid);
    }

    const(TextureProperties) properties() pure const nothrow
    {
        return mProperties;
    }

    RID rid() pure const nothrow
    {
        return mRid;
    }

    static TextureCubeMap load(string path)
    {
        TextureProperties properties;

        VFSFile file = VFS.getFile(path);
        scope (exit) file.close();
        Tag root = parseSource(file.readAll!string);

        Image[6] images = [
            AssetManager.load!Image(root.expectTagValue!string("positive-x")),
            AssetManager.load!Image(root.expectTagValue!string("negative-x")),
            AssetManager.load!Image(root.expectTagValue!string("positive-y")),
            AssetManager.load!Image(root.expectTagValue!string("negative-y")),
            AssetManager.load!Image(root.expectTagValue!string("positive-z")),
            AssetManager.load!Image(root.expectTagValue!string("negative-z")),
        ];

        if (VFS.hasFile(path ~ ".props")) // Properties file exists
        {
            import std.conv : to;

            VFSFile propsFile = VFS.getFile(path ~ ".props");
            scope (exit) propsFile.close();
            root = parseSource(propsFile.readAll!string);

            try
            {
                properties.minFilter = root.getTagValue!string("min-filter", "nearest").to!(TextureProperties.Filter);
                properties.magFilter = root.getTagValue!string("mag-filter", "nearest").to!(TextureProperties.Filter);
                properties.wrapS = root.getTagValue!string("wrap-s", "repeat").to!(TextureProperties.WrapMode);
                properties.wrapT = root.getTagValue!string("wrap-t", "repeat").to!(TextureProperties.WrapMode);
            }
            catch (Exception ex)
            {
                Logger.core.log(LogLevel.warning, "Failed to parse properties file for '%s': %s", path, ex.msg);
            }
        }

        return new TextureCubeMap(images, properties);
    }
}

/+

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
        return GraphicsAPI.sCreateTexture2DImpl(image, properties);
    }

    static Texture2D load(string path)
    {
        return GraphicsAPI.sLoadTexture2DImpl(path);
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
        return GraphicsAPI.sCreateTextureCubeMapImpl(images, properties);
    }

    static TextureCubeMap load(string path)
    {
        return GraphicsAPI.sLoadTextureCubeMapImpl(path);
    }
}+/