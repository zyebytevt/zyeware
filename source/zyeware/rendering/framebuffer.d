// This file is part of the ZyeWare Game Engine, and subject to the terms
// and conditions defined in the file 'LICENSE.txt', which is part
// of this source code package.
//
// Copyright 2021 ZyeByte
module zyeware.rendering.framebuffer;

import std.exception : enforce;

import zyeware.common;
import zyeware.rendering;
import zyeware.pal;

struct FramebufferProperties
{
    /// Determines how the framebuffer is used later on.
    enum UsageType
    {
        /// The framebuffer is used as a swapchain target.
        /// This means that the framebuffer will be presented to the screen.
        /// This is the default usage type.
        swapChainTarget,

        /// The framebuffer is used as a texture.
        /// This means that the framebuffer will be used as a texture in a shader.
        /// This is useful for post-processing effects.
        texture,
    }

    Vector2i size; /// The size of the framebuffer.
    UsageType usageType = UsageType.swapChainTarget; /// The usage type of the framebuffer.
}

class Framebuffer : NativeObject
{
protected:
    NativeHandle mNativeHandle;
    FramebufferProperties mProperties;

public:
    this(in FramebufferProperties properties)
    {
        mProperties = properties;
        mNativeHandle = PAL.graphics.createFramebuffer(mProperties);
    }

    ~this()
    {
        PAL.graphics.freeFramebuffer(mNativeHandle);
    }

    void recreate(in FramebufferProperties properties)
    {
        mProperties = properties;
        PAL.graphics.freeFramebuffer(mNativeHandle);
        mNativeHandle = PAL.graphics.createFramebuffer(mProperties);
    }

    Texture2D getTexture2D()
    {
        enforce!RenderException(mProperties.usageType == FramebufferProperties.UsageType.texture,
            "Framebuffer cannot be used as a texture.");

        NativeHandle handle = PAL.graphics.getTextureFromFramebuffer(mNativeHandle);
        return new Texture2D(handle, mProperties.size);
    }

    const(NativeHandle) handle() pure const nothrow
    {
        return mNativeHandle;
    }

    const(FramebufferProperties) properties() pure const nothrow
    {
        return mProperties;
    }
}