// This file is part of the ZyeWare Game Engine, and subject to the terms
// and conditions defined in the file 'LICENSE.txt', which is part
// of this source code package.
//
// Copyright 2021 ZyeByte
module zyeware.rendering.texatlas;

import zyeware.common;
import zyeware.rendering;

struct TextureAtlas
{
private:
    Texture2D mTexture;
    Rect2f mRegion = Rect2f(0, 0, 1, 1);

    size_t mHFrames, mVFrames;
    size_t mFrame;

public:
    this(Texture2D texture) pure nothrow
    {
        mTexture = texture;
        mRegion = Rect2f(0, 0, 1, 1);
    }

    this(Texture2D texture, Rect2f region) pure nothrow
    {
        mTexture = texture;
        mRegion = region;
    }

    this(Texture2D texture, size_t hFrames, size_t vFrames, size_t frame) pure nothrow
    {
        mTexture = texture;
        mHFrames = hFrames;
        mVFrames = vFrames;

        this.frame = frame;
    }

    void region(in Rect2f value) pure nothrow
    {
        mRegion = value;
    }

    Rect2f region() pure const nothrow
    {
        return mRegion;
    }

    void frame(size_t value) pure nothrow
    {
        mFrame = value;

        immutable float x1 = cast(float) (mFrame % mHFrames) / mHFrames;
        immutable float y1 = cast(float) (mFrame / mHFrames) / mVFrames;

        mRegion = Rect2f(
            x1,
            y1,
            x1 + 1.0f / mHFrames,
            y1 + 1.0f / mVFrames
        );
    }

    size_t frame() pure const nothrow
    {
        return mFrame;
    }

    inout(Texture2D) texture() pure inout nothrow
    {
        return mTexture;
    }
}