// This file is part of the ZyeWare Game Engine, and subject to the terms
// and conditions defined in the file 'LICENSE.txt', which is part
// of this source code package.
//
// Copyright © 2021-2024 ZyeByte. All rights reserved.
module zyeware.graphics.sprite;

import std.datetime : Duration;

import zyeware;

class Sprite2d
{
protected:
    TextureAtlas mTextureAtlas;
    vec2i mSize;
    vec2 mOffset;

public:
    vec2 position = vec2.zero;
    float rotation = 0;
    vec2 scale = vec2.one;
    color modulate = color.white;
    Material material;
    bool hFlip = false;
    bool vFlip = false;
    int layer = 0;
    size_t frame = 0;

    this(Texture2d texture, vec2 offset = vec2.zero) @safe pure nothrow
    {
        mTextureAtlas = TextureAtlas(texture, 1, 1);
        mSize = texture.size;
        mOffset = offset;
    }

    this(TextureAtlas textureAtlas, vec2i size, vec2 offset = vec2.zero) @safe pure nothrow
    {
        mTextureAtlas = textureAtlas;
        mSize = size;
        mOffset = offset;
    }

    void draw() const
    {
        rect region = mTextureAtlas.getRegionForFrame(frame);

        if (hFlip)
        {
            region.x = 1.0 - region.x;
            region.width = -region.width;
        }

        if (vFlip)
        {
            region.y = 1.0 - region.y;
            region.height = -region.height;
        }

        immutable dimensions = rect(-mOffset.x, -mOffset.y, mSize.x, mSize.y);

        Renderer.drawRect2d(dimensions, position, scale, rotation, modulate,
            mTextureAtlas.texture, layer, material, region);
    }
}

class AnimatedSprite2d : Sprite2d
{
protected:
    alias Animation = FrameAnimations.Animation;

    FrameAnimations mFrameAnimations;
    Animation* mCurrentAnimation;
    size_t mAnimationFrame;
    Duration mRemainingFrameTime;
    string mCurrentAnimationName;
    bool mIsPlaying;

public:
    this(FrameAnimations animations, TextureAtlas textureAtlas, vec2i size, vec2 offset = vec2.zero)
    in (animations, "Animations must not be null.")
    {
        super(textureAtlas, size, offset);
        mFrameAnimations = animations;
    }

    void play(string animation) @safe pure nothrow
    {
        currentAnimation = animation;
        isPlaying = true;
    }

    void stop() @safe pure nothrow
    {
        mCurrentAnimation = null;
        mRemainingFrameTime = Duration.zero;
        isPlaying = false;
    }

    void tick()
    {
        if (!mIsPlaying || !mCurrentAnimation)
        {
            return;
        }

        mRemainingFrameTime -= ZyeWare.frameTime.deltaTime;

        while (mRemainingFrameTime <= Duration.zero)
        {
            ++mAnimationFrame;
            if (mAnimationFrame >= mCurrentAnimation.frames.length)
            {
                if (mCurrentAnimation.isLooping)
                {
                    mAnimationFrame = 0;
                }
                else
                {
                    stop();
                    return;
                }
            }

            mRemainingFrameTime += mCurrentAnimation.frames[mAnimationFrame].duration;
        }

        frame = mCurrentAnimation.frames[mAnimationFrame].index;
        hFlip = mCurrentAnimation.frames[mAnimationFrame].hFlip;
        vFlip = mCurrentAnimation.frames[mAnimationFrame].vFlip;
    }

    string currentAnimation() const @safe pure nothrow => mCurrentAnimationName;

    string currentAnimation(string value) @safe pure nothrow
    {
        Animation* animation = mFrameAnimations.getAnimation(value);

        if (animation)
        {
            mCurrentAnimation = animation;
            mCurrentAnimationName = value;
            mAnimationFrame = 0;

            frame = animation.frames[0].index;
            mRemainingFrameTime = animation.frames[0].duration;
        }

        return mCurrentAnimationName;
    }

    bool isPlaying() const @safe pure nothrow => mIsPlaying;

    bool isPlaying(bool value) @safe pure nothrow => mIsPlaying = value;
}
