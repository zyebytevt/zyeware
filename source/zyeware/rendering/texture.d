// This file is part of the ZyeWare Game Engine, and subject to the terms
// and conditions defined in the file 'LICENSE.txt', which is part
// of this source code package.
//
// Copyright 2021 ZyeByte
module zyeware.rendering.texture;

import std.conv : to;
import std.string : format;
import std.algorithm : countUntil;

import zyeware;

import zyeware.pal;
import zyeware.utils.tokenizer;

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

        if (Vfs.hasFile(path ~ ".props")) // Properties file exists
            parseTextureProperties(path ~ ".props", properties);

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
        Image[6] images;

        immutable string[] sides = ["right", "left", "top", "bottom", "front", "back"];
        auto t = Tokenizer(sides);
        t.load(path);

        while (!t.isEof)
        {
            immutable string side = t.expect(Token.Type.keyword, null, "Expected side definition.").value;
            immutable string imagePath = t.expect(Token.Type.string, null, "Expected image path.").value;

            immutable size_t sideIndex = sides.countUntil(side);
            images[sideIndex] = AssetManager.load!Image(imagePath);
        }

        if (Vfs.hasFile(path ~ ".props")) // Properties file exists
            parseTextureProperties(path ~ ".props", properties);

        return new TextureCubeMap(images, properties);
    }
}

private void parseTextureProperties(string path, out TextureProperties properties)
{
    try
    {
        auto t = Tokenizer(["filter", "wrap"]);
        t.load(path);

        while (!t.isEof)
        {
            if (t.consume(Token.Type.keyword, "filter"))
            {
                t.expect(Token.Type.identifier, "min", "Expected min filter declaration.");
                properties.minFilter = t.expect(Token.Type.identifier, null).value.to!(TextureProperties.Filter);
                t.expect(Token.Type.delimiter, ",");
                t.expect(Token.Type.identifier, "mag", "Expected mag filter declaration.");
                properties.magFilter = t.expect(Token.Type.identifier, null).value.to!(TextureProperties.Filter);
            }
            else if (t.consume(Token.Type.keyword, "wrap"))
            {
                t.expect(Token.Type.identifier, "s", "Expected wrap s declaration.");
                properties.wrapS = t.expect(Token.Type.identifier, null).value.to!(TextureProperties.WrapMode);
                t.expect(Token.Type.delimiter, ",");
                t.expect(Token.Type.identifier, "t", "Expected wrap t declaration.");
                properties.wrapT = t.expect(Token.Type.identifier, null).value.to!(TextureProperties.WrapMode);
            }
            else
                throw new ResourceException(format!"Unexpected token '%s' in texture properties file."(t.get().value));
        }
    }
    catch (Exception ex)
    {
        Logger.core.log(LogLevel.warning, "Failed to parse properties file for '%s': %s", path, ex.message);
    }
}