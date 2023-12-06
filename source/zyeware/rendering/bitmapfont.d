// This file is part of the ZyeWare Game Engine, and subject to the terms
// and conditions defined in the file 'LICENSE.txt', which is part
// of this source code package.
//
// Copyright 2021 ZyeByte
module zyeware.rendering.bitmapfont;

import std.traits : isSomeString;
import std.array : array;
import std.algorithm : map;
import std.string : format;

import zyeware.zyfont;
import zyeware;


struct BitmapFontProperties
{
    string fontName;
    short fontSize;
    bool isBold;
    bool isItalic;
    short lineHeight;
    ubyte[4] padding;
    ubyte[2] spacing;
    Image[] pages;
    BitmapFont.Glyph[dchar] characters;
    short[ulong] kernings;
    TextureProperties pageTextureProperties;
}

@asset(Yes.cache)
class BitmapFont
{
protected:
    const(BitmapFontProperties) mProperties;
    Texture2D[] mPageTextures;

public:
    /// Information about a single character.
    struct Glyph
    {
        dchar id;
        ubyte pageIndex;
        Vector2f uv1, uv2;
        Vector2i size, offset, advance;
    }

    /// How a text should be aligned.
    enum Alignment : uint
    {
        top = 1,
        middle = 1 << 1,
        bottom = 1 << 2,

        left = 1 << 3,
        center = 1 << 4,
        right = 1 << 5
    }

    this(in BitmapFontProperties properties)
    {
        mProperties = properties;

        Logger.core.log(LogLevel.debug_, "Creating bitmap font '%s, %d'...",
            mProperties.fontName, mProperties.fontSize);

        for (size_t i; i < mProperties.pages.length; ++i)
            mPageTextures ~= new Texture2D(mProperties.pages[i], mProperties.pageTextureProperties);
    }

    
    /// Gets the width of the given string in this font, in pixels.
    /// 
    /// Params:
    ///     text = The text to get the width of.
    /// 
    /// Returns: The width of the text in this font, in pixels.
    int getTextWidth(T)(in T text) const pure nothrow
        if (isSomeString!T)
        in (text, "Text cannot be null.")
    {
        int maxLength, lineLength;

        for (size_t i; i < text.length; ++i)
        {
            immutable dchar c = cast(dchar) text[i];

            if (c == '\n')
            {
                lineLength = 0;
                continue;
            }

            immutable short kerning = i > 0 ? getKerning(cast(dchar) text[i - 1], c) : 0;

            immutable Glyph info = getGlyph(c);
            if (info != Glyph.init)
                lineLength += info.advance.x + kerning;

            if (lineLength > maxLength)
                maxLength = lineLength;
        }

        return maxLength;
    }

    /// Gets the height of the given string in this font, in pixels.
    /// 
    /// Params:
    ///     text = The text to get the height of.
    /// 
    /// Returns: The height of the text in this font, in pixels.
    int getTextHeight(T)(in T text) const pure nothrow
        if (isSomeString!T)
        in (text, "Text cannot be null.")
    {
        int lines = 1;

        foreach (c; text)
        {
            if (c == '\n')
                ++lines;
        }

        return mProperties.lineHeight * lines;
    }

    const(Texture2D) getPageTexture(size_t index) const nothrow
    {
        return mPageTextures[index];
    }

    Glyph getGlyph(dchar c) const pure nothrow
    {
        auto info = c in mProperties.characters;
        return info ? *info : Glyph.init;
    }

    short getKerning(dchar first, dchar second) const pure nothrow
    {
        immutable ulong key = (cast(ulong) first << 32) | cast(ulong) second;
        auto value = key in mProperties.kernings;
        return value ? *value : 0;
    }

    short lineHeight() const pure nothrow
    {
        return mProperties.lineHeight;
    }

    static BitmapFont load(string path)
        in (path, "Path cannot be null.")
    {
        import std.zlib : uncompress;
        import std.bitmanip : read;

        VFSFile sourceFile = VFS.open(path);
        scope (exit) sourceFile.close();
        ubyte[] source = sourceFile.readAll!(ubyte[]);

        ZyFont font = ZyFont.deserialize(source);
        
        BitmapFontProperties properties;

        properties.fontName = font.name;
        properties.fontSize = font.size;
        properties.isBold = font.isBold;
        properties.isItalic = font.isItalic;
        properties.lineHeight = font.lineHeight;
        properties.padding = font.padding;
        properties.spacing = font.spacing;
        properties.pages = font.pages.map!(p => new Image(p.pixels, p.channels,
            p.bitsPerChannel, Vector2i(p.xsize, p.ysize))).array;

        foreach (ref ZyFont.Glyph c; font.glyphs)
        {
            properties.characters[c.id] = Glyph(c.id, c.page,
                Vector2f(c.u1, c.v1), Vector2f(c.u2, c.v2), Vector2i(c.xsize, c.ysize),
                Vector2i(c.xoffset, c.yoffset), Vector2i(c.xadvance, c.yadvance));
        }

        foreach (ref ZyFont.Kerning k; font.kernings)
        {
            immutable ulong key = (cast(ulong) k.first << 32) | cast(ulong) k.second;
            properties.kernings[key] = k.amount;
        }

        return new BitmapFont(properties);
    }
}