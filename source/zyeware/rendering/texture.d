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

interface Texture : NativeObject
{
    const(TextureProperties) properties() pure const nothrow;
}

@asset(Yes.cache)
class Texture2D : Texture
{
protected:
    NativeHandle mNativeHandle;
    TextureProperties mProperties;

public:
    this(in Image image, in TextureProperties properties = TextureProperties.init)
    {
        mProperties = properties;
        mNativeHandle = PAL.graphics.createTexture2D(image, mProperties);
    }

    ~this()
    {
        PAL.graphics.freeTexture2D(mNativeHandle);
    }

    const(TextureProperties) properties() pure const nothrow
    {
        return mProperties;
    }

    const(NativeHandle) handle() pure const nothrow
    {
        return mNativeHandle;
    }

    static Texture2D load(string path)
    {
        return new Texture2D(AssetManager.load!Image(path));
    }
}

@asset(Yes.cache)
class TextureCubeMap : Texture
{
protected:
    NativeHandle mNativeHandle;
    TextureProperties mProperties;

public:
    this(in Image[6] images, in TextureProperties properties = TextureProperties.init)
    {
        mProperties = properties;
        mNativeHandle = PAL.graphics.createTextureCubeMap(images, properties);
    }

    ~this()
    {
        PAL.graphics.freeTextureCubeMap(mNativeHandle);
    }

    const(TextureProperties) properties() pure const nothrow
    {
        return mProperties;
    }

    const(NativeHandle) handle() pure const nothrow
    {
        return mNativeHandle;
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
        return PAL.graphics.sCreateTexture2DImpl(image, properties);
    }

    static Texture2D load(string path)
    {
        return PAL.graphics.sLoadTexture2DImpl(path);
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
        return PAL.graphics.sCreateTextureCubeMapImpl(images, properties);
    }

    static TextureCubeMap load(string path)
    {
        return PAL.graphics.sLoadTextureCubeMapImpl(path);
    }
}+/