// This file is part of the ZyeWare Game Engine, and subject to the terms
// and conditions defined in the file 'LICENSE.txt', which is part
// of this source code package.
//
// Copyright 2021 ZyeByte
module zyeware.rendering.texture;

import std.conv : to;

import zyeware.common;
import zyeware.rendering;
import zyeware.pal;

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
    Vector2i mSize;

package(zyeware):
    /// Careful: This will take ownership of the given handle.
    this(NativeHandle handle, in Vector2i size, in TextureProperties properties = TextureProperties.init) nothrow
    {
        mProperties = properties;
        mSize = size;
        mNativeHandle = handle;
    }

public:
    this(in Image image, in TextureProperties properties = TextureProperties.init)
    {
        mProperties = properties;
        mSize = image.size;
        mNativeHandle = Pal.graphics.api.createTexture2D(image, mProperties);
    }

    ~this()
    {
        Pal.graphics.api.freeTexture2D(mNativeHandle);
    }

    const(TextureProperties) properties() pure const nothrow
    {
        return mProperties;
    }

    const(NativeHandle) handle() pure const nothrow
    {
        return mNativeHandle;
    }

    const(Vector2i) size() pure const nothrow
    {
        return mSize;
    }

    // TODO: Implement ZDL loading of texture properties
    static Texture2D load(string path)
    {
        TextureProperties properties;
        Image img = AssetManager.load!Image(path);

        if (VFS.hasFile(path ~ ".props")) // Properties file exists
        {
            try
            {
                auto document = ZDLDocument.load(path ~ ".props");

                properties.minFilter = getNodeValue!ZDLString(document.root, "minFilter", "nearest").to!(TextureProperties.Filter);
                properties.magFilter = getNodeValue!ZDLString(document.root, "magFilter", "nearest").to!(TextureProperties.Filter);
                properties.wrapS = getNodeValue!ZDLString(document.root, "wrapS", "repeat").to!(TextureProperties.WrapMode);
                properties.wrapT = getNodeValue!ZDLString(document.root, "wrapT", "repeat").to!(TextureProperties.WrapMode);
            }
            catch (Exception ex)
            {
                Logger.core.log(LogLevel.warning, "Failed to parse properties file for '%s': %s", path, ex.message);
            }
        }

        return new Texture2D(img, properties);
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
        mNativeHandle = Pal.graphics.api.createTextureCubeMap(images, properties);
    }

    ~this()
    {
        Pal.graphics.api.freeTextureCubeMap(mNativeHandle);
    }

    const(TextureProperties) properties() pure const nothrow
    {
        return mProperties;
    }

    const(NativeHandle) handle() pure const nothrow
    {
        return mNativeHandle;
    }

    // TODO: Implement ZDL loading of images
    static TextureCubeMap load(string path)
    {
        TextureProperties properties;

        auto document = ZDLDocument.load(path);
        
        Image[6] images = [
            AssetManager.load!Image(document.root.x.positive.expectValue!ZDLString),
            AssetManager.load!Image(document.root.x.negative.expectValue!ZDLString),
            AssetManager.load!Image(document.root.y.positive.expectValue!ZDLString),
            AssetManager.load!Image(document.root.y.negative.expectValue!ZDLString),
            AssetManager.load!Image(document.root.z.positive.expectValue!ZDLString),
            AssetManager.load!Image(document.root.z.negative.expectValue!ZDLString),
        ];

        if (VFS.hasFile(path ~ ".props")) // Properties file exists
        {
            try
            {
                document = ZDLDocument.load(path ~ ".props");

                properties.minFilter = getNodeValue!ZDLString(document.root, "minFilter", "nearest").to!(TextureProperties.Filter);
                properties.magFilter = getNodeValue!ZDLString(document.root, "magFilter", "nearest").to!(TextureProperties.Filter);
                properties.wrapS = getNodeValue!ZDLString(document.root, "wrapS", "repeat").to!(TextureProperties.WrapMode);
                properties.wrapT = getNodeValue!ZDLString(document.root, "wrapT", "repeat").to!(TextureProperties.WrapMode);
            }
            catch (Exception ex)
            {
                Logger.core.log(LogLevel.warning, "Failed to parse properties file for '%s': %s", path, ex.message);
            }
        }

        return new TextureCubeMap(images, properties);
    }
}