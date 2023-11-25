module fntcompile.font;

import std.stdio;
import std.zlib;
import std.file : readText, read, write;
import std.exception : enforce;
import std.string : format;

import zyeware.zyfont;

import bmfont;
import gamut;

void convert(string sourceFile, string outputFile)
{
    Font bmFont = parseFnt(readText(sourceFile));
    
    Image[] pages;
    foreach (pagePath; bmFont.pages)
    {
        pages.length += 1;

        pages[$-1].loadFromFile(pagePath);
        enforce(pages[$-1].isValid, format!"Failed to load page '%s'."(pagePath));

        pages[$-1].setLayout(gamut.LAYOUT_GAPLESS | gamut.LAYOUT_VERT_STRAIGHT);
    }

    ZyFont font;

    font.name = bmFont.info.fontName;
    font.size = bmFont.info.fontSize;
    font.isBold = cast(bool) (bmFont.info.bitField & 0b1000);
    font.isItalic = cast(bool) (bmFont.info.bitField & 0b0100);
    font.lineHeight = bmFont.common.lineHeight;
    font.padding = bmFont.info.padding;
    font.spacing = bmFont.info.spacing;

    foreach (Font.Char c; bmFont.chars)
    {
        font.glyphs ~= ZyFont.Glyph(
            c.id,
            c.page,
            c.width,
            c.height,
            cast(float) c.x / pages[c.page].width,
            cast(float) c.y / pages[c.page].height,
            cast(float) c.width / pages[c.page].width,
            cast(float) c.height / pages[c.page].height,
            c.xoffset,
            c.yoffset,
            c.xadvance,
            0
        );
    }

    foreach (Font.Kerning k; bmFont.kernings)
    {
        font.kernings ~= ZyFont.Kerning(
            k.first,
            k.second,
            k.amount
        );
    }

    foreach (ref Image page; pages)
    {
        immutable int bitsPerChannel = (page.type % 3 + 1) * 8;
        immutable int channels = page.type / 3 + 1;

        font.pages ~= ZyFont.Page(
            cast(ubyte) channels,
            cast(ubyte) bitsPerChannel,
            page.width,
            page.height,
            page.allPixelsAtOnce
        );
    }

    write(outputFile, font.serialize());
}