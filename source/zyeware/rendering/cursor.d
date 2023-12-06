module zyeware.rendering.cursor;

import std.conv : to;

import zyeware;

import zyeware.utils.tokenizer;

@asset(Yes.cache)
final class Cursor
{
protected:
    const Image mImage;
    Vector2i mHotspot;

public:
    this(const Image image, Vector2i hotspot)
    {
        mImage = image;
        mHotspot = hotspot;
    }

    const(Image) image() pure const nothrow
    {
        return mImage;
    }

    Vector2i hotspot() pure const nothrow
    {
        return mHotspot;
    }

    static Cursor load(string path)
    { 
        auto t = Tokenizer(["image", "hotspot"]);
        t.load(path);

        t.expect(Token.Type.keyword, "image", "Expected image declaration.");
        immutable string imagePath = t.expect(Token.Type.string, null).value;

        t.expect(Token.Type.keyword, "hotspot", "Expected hotspot declaration.");
        immutable int x = t.expect(Token.Type.integer, null).value.to!int;
        t.expect(Token.Type.delimiter, ",");
        immutable int y = t.expect(Token.Type.integer, null).value.to!int;

        return new Cursor(
            AssetManager.load!Image(imagePath),
            Vector2i(x, y)
        );
    }
}