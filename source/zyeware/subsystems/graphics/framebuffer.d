// This file is part of the ZyeWare Game Engine, and subject to the terms
// and conditions defined in the file 'LICENSE.txt', which is part
// of this source code package.
//
// Copyright © 2021-2024 ZyeByte. All rights reserved.
module zyeware.subsystems.graphics.framebuffer;

import std.exception : enforce;

import zyeware;
import zyeware.subsystems.graphics;

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

    vec2i size; /// The size of the framebuffer.
    UsageType usageType = UsageType.swapChainTarget; /// The usage type of the framebuffer.
}

final class Framebuffer : NativeObject
{
private:
    NativeHandle mNativeHandle;
    FramebufferProperties mProperties;

public:
    this(in FramebufferProperties properties)
    {
        mProperties = properties;
        mNativeHandle = GraphicsSubsystem.callbacks.createFramebuffer(mProperties);
    }

    ~this()
    {
        GraphicsSubsystem.callbacks.freeFramebuffer(mNativeHandle);
    }

    void recreate(in FramebufferProperties properties)
    {
        mProperties = properties;
        GraphicsSubsystem.callbacks.freeFramebuffer(mNativeHandle);
        mNativeHandle = GraphicsSubsystem.callbacks.createFramebuffer(mProperties);
    }

    Texture2d getTexture2d()
    {
        enforce!RenderException(mProperties.usageType == FramebufferProperties.UsageType.texture,
            "Framebuffer cannot be used as a texture.");

        NativeHandle handle = GraphicsSubsystem.callbacks.getTextureFromFramebuffer(mNativeHandle);
        return new Texture2d(handle, mProperties.size);
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
