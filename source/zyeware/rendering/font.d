// This file is part of the ZyeWare Game Engine, and subject to the terms
// and conditions defined in the file 'LICENSE.txt', which is part
// of this source code package.
//
// Copyright 2021 ZyeByte
module zyeware.rendering.font;

import std.traits : isSomeString;
import std.range : ElementEncodingType;

import bmfont : BMFont = Font, parseFnt;

import zyeware.common;
import zyeware.rendering;

@asset(Yes.cache)
class Font
{
protected:
    const BMFont mBMFont;
    Texture2D[] mPageTextures;

public:
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

    this(in BMFont bmFont)
    {
        mBMFont = bmFont;

        Logger.core.log(LogLevel.debug_, "Creating font '%s, %d' from BMFont struct...",
                bmFont.info.fontName, bmFont.info.fontSize);

        foreach (string pagePath; bmFont.pages)
            mPageTextures ~= cast(Texture2D) Texture2D.load(pagePath);//AssetManager.load!Texture2D(pagePath);
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
            immutable ElementEncodingType!T c = text[i];

            if (c == '\n')
            {
                lineLength = 0;
                continue;
            }

            immutable short kerning = i > 0 ? mBMFont.getKerning(text[i - 1], text[i]) : 1;

            immutable bmc = mBMFont.getChar(c);
            if (bmc != BMFont.Char.init)
                lineLength += bmc.xadvance + kerning;

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

        return mBMFont.common.lineHeight * lines;
    }

    const(BMFont) bmFont() const nothrow
    {
        return mBMFont;
    }

    const(Texture2D) getPageTexture(size_t index) const nothrow
    {
        return mPageTextures[index];
    }

    static Font load(string path)
        in (path, "Path cannot be null.")
    {
        Logger.core.log(LogLevel.verbose, "Loading Font from '%s'...", path);
        
        VFSFile source = VFS.getFile(path);
        scope (exit) source.close();
        
        auto bmFont = parseFnt(source.readAll!(ubyte[]));

        return new Font(bmFont);
    }
}