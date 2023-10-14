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
        auto document = ZDLDocument.load(path);

        return new Cursor(
            AssetManager.load!Image(document.root.image.expectValue!ZDLString),
            document.root.hotspot.expectValue!Vector2i
        );
    }
}