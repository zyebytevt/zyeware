// This file is part of the ZyeWare Game Engine, and subject to the terms
// and conditions defined in the file 'LICENSE.txt', which is part
// of this source code package.
//
// Copyright 2021 ZyeByte
module zyeware.rendering.framebuffer;

import zyeware.common;
import zyeware.rendering;

struct FramebufferProperties
{
    Vector2i size;
    ubyte channels;
    bool swapChainTarget;
}

class Framebuffer
{
protected:
    RID mRid;
    FramebufferProperties mProperties;

public:
    this(in FramebufferProperties properties)
    {
        mProperties = properties;
        mRid = ZyeWare.graphics.api.createFramebuffer(mProperties);
    }

    ~this()
    {
        ZyeWare.graphics.api.free(mRid);
    }

    const(FramebufferProperties) properties() pure const nothrow
    {
        return mRid;
    }
}