module fntcompile.font;

import std.stdio;
import std.zlib;
import std.file : readText, read, write;
import std.exception : enforce;
import std.string : format;

import std.stdio;

import bmfont;
import gamut;

void writePString(LengthType = uint)(ref ubyte[] buffer, string text)
{
	buffer.writePrimitive(cast(LengthType) text.length);
    buffer ~= cast(ubyte[]) text;
}

void writePrimitive(T)(ref ubyte[] buffer, T value)
{
    import std.bitmanip : write, Endian;

	buffer.length += T.sizeof;
	write!(T, Endian.littleEndian)(buffer, value, buffer.length - T.sizeof);
}

enum magicString = cast(ubyte[]) "ZFNT1";

void convert(string sourceFile, string outputFile)
{
    Font bmFont = parseFnt(readText(sourceFile));
    
    ubyte[] output;

    Image[] pages;
    foreach (pagePath; bmFont.pages)
    {
        pages.length += 1;

        pages[$-1].loadFromFile(pagePath);
        enforce(pages[$-1].isValid, format!"Failed to load page '%s'."(pagePath));

        pages[$-1].setLayout(gamut.LAYOUT_GAPLESS | gamut.LAYOUT_VERT_STRAIGHT);
    }

    output.writePString(bmFont.info.fontName);
    output.writePrimitive(cast(ushort) bmFont.info.fontSize);
    output.writePrimitive(cast(bool) (bmFont.info.bitField & 0b1000));
    output.writePrimitive(cast(bool) (bmFont.info.bitField & 0b0100));
    output.writePrimitive(cast(short) (bmFont.common.lineHeight));
    output ~= bmFont.info.padding;
    output ~= bmFont.info.spacing;

    output.writePrimitive(cast(uint) bmFont.chars.length);
    foreach (Font.Char c; bmFont.chars)
    {
        output.writePrimitive(cast(uint) c.id);
        output.writePrimitive(cast(ubyte) c.page);

        enforce(c.page < pages.length, format!"Invalid page index %d for character %s."(c.page, c.id));
        Image* page = &pages[c.page];

        output.writePrimitive(cast(float) c.x / page.width);
        output.writePrimitive(cast(float) c.y / page.height);
        output.writePrimitive(cast(float) (c.x + c.width) / page.width);
        output.writePrimitive(cast(float) (c.y + c.height) / page.height);

        output.writePrimitive(cast(short) c.xoffset);
        output.writePrimitive(cast(short) c.yoffset);
        output.writePrimitive(cast(short) c.xadvance);
        output.writePrimitive(cast(short) 0);
    }

    output.writePrimitive(cast(uint) bmFont.kernings.length);
    foreach (Font.Kerning k; bmFont.kernings)
    {
        output.writePrimitive(cast(ulong) k.first << 32 | cast(ulong) k.second);
        output.writePrimitive(cast(short) k.amount);
    }

    output.writePrimitive(cast(short) pages.length);
    foreach (ref Image page; pages)
    {
        immutable int bitsPerChannel = (page.type % 3 + 1) * 8;
        immutable int channels = page.type / 3 + 1;

        output.writePrimitive(cast(ubyte) channels);
        output.writePrimitive(cast(ubyte) bitsPerChannel);
        output.writePrimitive(cast(int) page.width);
        output.writePrimitive(cast(int) page.height);
        output ~= page.allPixelsAtOnce;
    }

    write(outputFile, magicString ~ compress(output));
}