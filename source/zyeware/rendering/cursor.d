module zyeware.rendering.cursor;

import zyeware.common;
import zyeware.rendering;

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
        import std.conv : to;
        import sdlang;

        scope VFSFile propsFile = VFS.getFile(path);
        Tag root = parseSource(propsFile.readAll!string);
        propsFile.close();

        Tag hotspot = root.expectTag("hotspot");
        if (hotspot.values.length != 2)
            throw new GraphicsException("Hotspot needs x and y values.");

        return new Cursor(
            AssetManager.load!Image(root.getTagValue!string("image")),
            Vector2i(hotspot.values[0].coerce!int, hotspot.values[1].coerce!int)
        );
    }
}