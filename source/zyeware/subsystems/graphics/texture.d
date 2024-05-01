// This file is part of the ZyeWare Game Engine, and subject to the terms
// and conditions defined in the file 'LICENSE.txt', which is part
// of this source code package.
//
// Copyright © 2021-2024 ZyeByte. All rights reserved.
module zyeware.subsystems.graphics.texture;

import std.conv : to;
import std.string : format;
import std.algorithm : countUntil;

import zyeware;
import zyeware.subsystems.graphics;

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
final class Texture2d : Texture
{
private:
    NativeHandle mNativeHandle;
    TextureProperties mProperties;
    vec2i mSize;

package(zyeware):
    /// Careful: This will take ownership of the given handle.
    this(NativeHandle handle, in vec2i size, in TextureProperties properties = TextureProperties
            .init) nothrow
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
        mNativeHandle = GraphicsSubsystem.callbacks.createTexture2d(image, mProperties);
    }

    ~this()
    {
        GraphicsSubsystem.callbacks.freeTexture2d(mNativeHandle);
    }

    const(TextureProperties) properties() @safe pure const nothrow
    {
        return mProperties;
    }

    const(NativeHandle) handle() @safe pure const nothrow
    {
        return mNativeHandle;
    }

    const(vec2i) size() @safe pure const nothrow
    {
        return mSize;
    }

    static Texture2d load(string path)
    {
        TextureProperties properties;
        Image img = AssetManager.load!Image(path);

        immutable string propsPath = path ~ ".props";
        if (Files.hasFile(propsPath)) // Properties file exists
            parseTextureProperties(propsPath, properties);

        return new Texture2d(img, properties);
    }
}

@asset(Yes.cache)
final class TextureCubeMap : Texture
{
private:
    NativeHandle mNativeHandle;
    TextureProperties mProperties;

public:
    this(in Image[6] images, in TextureProperties properties = TextureProperties.init)
    {
        mProperties = properties;
        mNativeHandle = GraphicsSubsystem.callbacks.createTextureCubeMap(images, properties);
    }

    ~this()
    {
        GraphicsSubsystem.callbacks.freeTextureCubeMap(mNativeHandle);
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
        Image[6] images;

        SDLNode* root = loadSdlDocument(path);

        static foreach (size_t i, string side; [
            "right", "left", "top", "bottom", "front", "back"
        ])
            images[i] = AssetManager.load!Image(root.expectChildValue!string(side));

        immutable string propsPath = path ~ ".props";
        if (Files.hasFile(propsPath)) // Properties file exists
            parseTextureProperties(propsPath, properties);

        return new TextureCubeMap(images, properties);
    }
}

private void parseTextureProperties(string path, out TextureProperties properties)
{
    try
    {
        SDLNode* root = loadSdlDocument(path);

        if (SDLNode* filter = root.getChild("filter"))
        {
            properties.minFilter = filter.expectAttributeValue!string("min")
                .to!(TextureProperties.Filter);
            properties.magFilter = filter.expectAttributeValue!string("mag")
                .to!(TextureProperties.Filter);
        }

        if (SDLNode* wrap = root.getChild("wrap"))
        {
            properties.wrapS = wrap.expectAttributeValue!string("s")
                .to!(TextureProperties.WrapMode);
            properties.wrapT = wrap.expectAttributeValue!string("t")
                .to!(TextureProperties.WrapMode);
        }
    }
    catch (Exception ex)
    {
        Logger.core.warning("Failed to parse properties file for '%s': %s", path, ex.message);
    }
}
