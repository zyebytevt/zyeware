// This file is part of the ZyeWare Game Engine, and subject to the terms
// and conditions defined in the file 'LICENSE.txt', which is part
// of this source code package.
//
// Copyright 2021 ZyeByte
module zyeware.graphics.texatlas;

import zyeware;

struct TextureAtlas {
private:
    Texture2d mTexture;
    size_t mHFrames, mVFrames;

public:
    this(string path, size_t hFrames, size_t vFrames) {
        this(AssetManager.load!Texture2d(path), hFrames, vFrames);
    }

    this(Texture2d texture, size_t hFrames, size_t vFrames) pure nothrow {
        mTexture = texture;
        mHFrames = hFrames;
        mVFrames = vFrames;
    }

    rect getRegionForFrame(size_t frame) pure const nothrow {
        immutable float x1 = cast(float)(frame % mHFrames) / mHFrames;
        immutable float y1 = cast(float)(frame / mHFrames) / mVFrames;

        return rect(
            x1,
            y1,
            1.0f / mHFrames,
            1.0f / mVFrames
        );
    }

    vec2 spriteSize() pure const nothrow {
        return vec2(
            mTexture.size.x / mHFrames,
            mTexture.size.y / mVFrames
        );
    }

    inout(Texture2d) texture() pure inout nothrow {
        return mTexture;
    }
}
