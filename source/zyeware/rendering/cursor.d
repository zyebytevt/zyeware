module zyeware.rendering.cursor;

import std.conv : to;

import zyeware;

@asset(Yes.cache)
final class Cursor
{
protected:
    const Image mImage;
    vec2i mHotspot;

public:
    this(const Image image, vec2i hotspot)
    {
        mImage = image;
        mHotspot = hotspot;
    }

    const(Image) image() pure const nothrow
    {
        return mImage;
    }

    vec2i hotspot() pure const nothrow
    {
        return mHotspot;
    }

    static Cursor load(string path)
    { 
        SDLNode* root = loadSdlDocument(path);

        return new Cursor(
            AssetManager.load!Image(root.expectChildValue!string("image")),
            root.expectChildValue!vec2i("hotspot")
        );
    }
}