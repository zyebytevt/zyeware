// This file is part of the ZyeWare Game Engine, and subject to the terms
// and conditions defined in the file 'LICENSE.txt', which is part
// of this source code package.
//
// Copyright 2021 ZyeByte
module zyeware.rendering.framebuffer;

import zyeware.common;
import zyeware.rendering;
import zyeware.pal;

struct FramebufferProperties
{
    Vector2i size;
    ubyte channels;
    bool swapChainTarget;
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

    const(NativeHandle) handle() pure const nothrow
    {
        return mNativeHandle;
    }

    const(FramebufferProperties) properties() pure const nothrow
    {
        return mProperties;
    }
}