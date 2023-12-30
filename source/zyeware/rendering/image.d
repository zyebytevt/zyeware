// This file is part of the ZyeWare Game Engine, and subject to the terms
// and conditions defined in the file 'LICENSE.txt', which is part
// of this source code package.
//
// Copyright 2021 ZyeByte
module zyeware.rendering.image;

import std.string : format;
import std.exception : enforce;

static import gamut;

import zyeware;


@asset(Yes.cache)
class Image
{
protected:
    const(ubyte[]) mPixels;
    ubyte mChannels;
    ubyte mBitsPerChannel;
    vec2i mSize;

public:
    this(in ubyte[] pixels, ubyte channels, ubyte bitsPerChannel, vec2i size) pure nothrow
        in (size.x > 0 && size.y > 0, "Image must be at least 1x1.")
        in (pixels && pixels.length == size.x * size.y * channels * (bitsPerChannel / 8), "Invalid amount of pixels.")
        in (channels > 0 && channels <= 4, "Invalid amount of channels.")
        in (bitsPerChannel >= 8 && bitsPerChannel <= 32, "Invalid amount of bits per channel.")
    {
        mPixels = pixels;
        mChannels = channels;
        mBitsPerChannel = bitsPerChannel;
        mSize = size;
    }

    color getPixel(vec2i coords) pure const nothrow
    {
        if (coords.x < 0 || coords.y < 0 || coords.x >= mSize.x || coords.y >= mSize.y)
            return color(1, 0, 1, 1);
        
        ubyte r = 0, g = 0, b = 0, a = 255;
        size_t channelStart = (coords.y * mSize.x + coords.x) * mChannels;

        // Careful, fallthrough.
        switch (mChannels)
        {
        case 4:
            a = pixels[channelStart + 3];
            goto case;

        case 3:
            b = pixels[channelStart + 2];
            goto case;

        case 2:
            g = pixels[channelStart + 1];
            goto case;

        case 1:
            r = pixels[channelStart];
            break;

        default:
        }

        return color(r / 255f, g / 255f, b / 255f, a / 255f);
    }

    const(ubyte[]) pixels() pure const nothrow
    {
        return mPixels;
    }

    ubyte channels() pure const nothrow
    {
        return mChannels;
    }

    ubyte bitsPerChannel() pure const nothrow
    {
        return mBitsPerChannel;
    }

    vec2i size() pure const nothrow
    {
        return mSize;
    }

    static Image load(string path)
        in (path, "Path cannot be null.")
    {
        VfsFile file = Vfs.open(path);
        scope(exit) file.close();

        return load(file.readAll!(ubyte[]));
    }

    static Image load(in ubyte[] data)
    {
        gamut.Image image;
        image.loadFromMemory(data);
        enforce!ResourceException(image.isValid, format!"Failed to load image: %s"(image.errorMessage));

        image.setLayout(gamut.LAYOUT_GAPLESS | gamut.LAYOUT_VERT_STRAIGHT);

        immutable int bitsPerChannel = (image.type % 3 + 1) * 8;
        immutable int channels = image.type / 3 + 1;

        return new Image(image.allPixelsAtOnce.dup, cast(ubyte) channels, cast(ubyte) bitsPerChannel,
            vec2i(image.width, image.height));
    }
}

@("Image")
unittest
{
    import unit_threaded.assertions;

    // Create an Image
    immutable ubyte[] pixels = [0, 0, 0, 255, 255, 255, 255, 255];
    ubyte channels = 4;
    ubyte bitsPerChannel = 8;
    vec2i size = vec2i(2, 1);

    Image image = new Image(pixels, channels, bitsPerChannel, size);
    image.pixels.length.should == 8;
    image.channels.should == 4;
    image.bitsPerChannel.should == 8;
    image.size.x.should == 2;
    image.size.y.should == 1;

    image.getPixel(vec2i(0, 0)).should == color(0, 0, 0, 1);
    image.getPixel(vec2i(1, 0)).should == color(1, 1, 1, 1);
    image.getPixel(vec2i(2, 0)).should == color(1, 0, 1, 1);
}