module zyeware.zyfont;

import std.zlib : uncompress, compress;
import std.bitmanip;

private:

void writePString(LengthType = uint)(ref ubyte[] buffer, string text) {
    buffer.writePrimitive(cast(LengthType) text.length);
    buffer ~= cast(ubyte[]) text;
}

char[] readPString(LengthType = uint)(ref ubyte[] buffer) {
    LengthType length = buffer.readPrimitive!LengthType;
    char[] str = new char[length];

    char[] result = cast(char[]) buffer[0 .. length];
    buffer = buffer[length .. $];

    return result;
}

void writePrimitive(T)(ref ubyte[] buffer, T value) {
    import std.bitmanip : write, Endian;

    buffer.length += T.sizeof;
    write!(T, Endian.littleEndian)(buffer, value, buffer.length - T.sizeof);
}

T readPrimitive(T)(ref ubyte[] buffer) {
    return read!(T, Endian.littleEndian)(buffer);
}

public:

struct ZyFont {
public:
    enum fileMagic = cast(ubyte[]) "ZFNT1";

    struct Glyph {
        dchar id;
        ubyte page;
        ushort xsize, ysize;
        float u1, v1, u2, v2;
        short xoffset, yoffset;
        short xadvance, yadvance;
    }

    struct Kerning {
        dchar first, second;
        short amount;
    }

    struct Page {
        ubyte channels;
        ubyte bitsPerChannel;
        int xsize, ysize;
        ubyte[] pixels;
    }

    string name;
    short size;
    bool isBold;
    bool isItalic;
    short lineHeight;
    ubyte[4] padding;
    ubyte[2] spacing;
    Glyph[] glyphs;
    Kerning[] kernings;
    Page[] pages;

    static ZyFont deserialize(in ubyte[] data) {
        auto range = cast(ubyte[]) data[];

        if (range.length < 5 || range[0 .. 5] != fileMagic)
            throw new Exception("Invalid file magic");

        range = cast(ubyte[]) uncompress(range[5 .. $]);

        ZyFont result;
        result.name = readPString(range);
        result.size = readPrimitive!short(range);
        result.isBold = readPrimitive!bool(range);
        result.isItalic = readPrimitive!bool(range);
        result.lineHeight = readPrimitive!short(range);

        result.padding = range[0 .. 4];
        result.spacing = range[4 .. 6];
        range = range[6 .. $];

        immutable uint glyphCount = readPrimitive!uint(range);
        result.glyphs = new Glyph[glyphCount];
        foreach (ref Glyph glyph; result.glyphs) {
            glyph.id = readPrimitive!dchar(range);
            glyph.page = readPrimitive!ubyte(range);
            glyph.xsize = readPrimitive!ushort(range);
            glyph.ysize = readPrimitive!ushort(range);
            glyph.u1 = readPrimitive!float(range);
            glyph.v1 = readPrimitive!float(range);
            glyph.u2 = readPrimitive!float(range);
            glyph.v2 = readPrimitive!float(range);
            glyph.xoffset = readPrimitive!short(range);
            glyph.yoffset = readPrimitive!short(range);
            glyph.xadvance = readPrimitive!short(range);
            glyph.yadvance = readPrimitive!short(range);
        }

        immutable uint kerningCount = readPrimitive!uint(range);
        result.kernings = new Kerning[kerningCount];
        foreach (ref Kerning kerning; result.kernings) {
            kerning.first = readPrimitive!dchar(range);
            kerning.second = readPrimitive!dchar(range);
            kerning.amount = readPrimitive!short(range);
        }

        immutable uint pageCount = readPrimitive!uint(range);
        result.pages = new Page[pageCount];
        foreach (ref Page page; result.pages) {
            page.channels = readPrimitive!ubyte(range);
            page.bitsPerChannel = readPrimitive!ubyte(range);
            page.xsize = readPrimitive!int(range);
            page.ysize = readPrimitive!int(range);

            immutable size_t pixelCount = page.channels * (
                page.bitsPerChannel / 8)
                * page.xsize * page.ysize;

            page.pixels = range[0 .. pixelCount];
            range = range[pixelCount .. $];
        }

        return result;
    }

    ubyte[] serialize() {
        ubyte[] result;

        writePString(result, name);
        writePrimitive(result, size);
        writePrimitive(result, isBold);
        writePrimitive(result, isItalic);
        writePrimitive(result, lineHeight);
        result ~= padding;
        result ~= spacing;

        writePrimitive(result, cast(uint) glyphs.length);
        foreach (ref Glyph glyph; glyphs) {
            writePrimitive(result, glyph.id);
            writePrimitive(result, glyph.page);
            writePrimitive(result, glyph.xsize);
            writePrimitive(result, glyph.ysize);
            writePrimitive(result, glyph.u1);
            writePrimitive(result, glyph.v1);
            writePrimitive(result, glyph.u2);
            writePrimitive(result, glyph.v2);
            writePrimitive(result, glyph.xoffset);
            writePrimitive(result, glyph.yoffset);
            writePrimitive(result, glyph.xadvance);
            writePrimitive(result, glyph.yadvance);
        }

        writePrimitive(result, cast(uint) kernings.length);
        foreach (ref Kerning kerning; kernings) {
            writePrimitive(result, kerning.first);
            writePrimitive(result, kerning.second);
            writePrimitive(result, kerning.amount);
        }

        writePrimitive(result, cast(uint) pages.length);
        foreach (ref Page page; pages) {
            writePrimitive(result, page.channels);
            writePrimitive(result, page.bitsPerChannel);
            writePrimitive(result, page.xsize);
            writePrimitive(result, page.ysize);
            result ~= page.pixels;
        }

        return fileMagic ~ compress(result);
    }
}
