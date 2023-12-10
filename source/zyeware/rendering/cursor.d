module zyeware.rendering.cursor;

import std.conv : to;

import zyeware;

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
        SDLNode* root = loadSdlDocument(path);

        immutable string imagePath = root.expectChildValue!string("image");
        SDLNode* hotspotNode = root.expectChild("hotspot");
        immutable int x = hotspotNode.expectAttributeValue!int("x");
        immutable int y = hotspotNode.expectAttributeValue!int("y");

        return new Cursor(
            AssetManager.load!Image(imagePath),
            Vector2i(x, y)
        );
    }
}