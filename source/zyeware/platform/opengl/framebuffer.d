// This file is part of the ZyeWare Game Engine, and subject to the terms
// and conditions defined in the file 'LICENSE.txt', which is part
// of this source code package.
//
// Copyright © 2021-2024 ZyeByte. All rights reserved.
module zyeware.platform.opengl.framebuffer;

import bindbc.opengl;

import zyeware;

package (zyeware.platform.opengl):

struct FramebufferData
{
    uint id;
    uint colorAttachmentId;
    uint depthAttachmentId;
}

NativeHandle createFramebuffer(in FramebufferProperties properties)
{
    auto framebuffer = new FramebufferData;

    glGenFramebuffers(1, &framebuffer.id);
    glBindFramebuffer(GL_FRAMEBUFFER, framebuffer.id);

    // Create the modulate attachment based on the properties.
    final switch (properties.usageType) with (FramebufferProperties.UsageType)
    {
    case swapChainTarget:
        glGenRenderbuffers(1, &framebuffer.colorAttachmentId);
        glBindRenderbuffer(GL_RENDERBUFFER, framebuffer.colorAttachmentId);

        glRenderbufferStorage(GL_RENDERBUFFER, GL_RGB8, properties.size.x, properties.size.y);
        glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0,
            GL_RENDERBUFFER, framebuffer.colorAttachmentId);
        break;

    case texture:
        glGenTextures(1, &framebuffer.colorAttachmentId);
        glBindTexture(GL_TEXTURE_2D, framebuffer.colorAttachmentId);

        glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB8, properties.size.x,
            properties.size.y, 0, GL_RGB, GL_UNSIGNED_BYTE, null);
        glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0,
            GL_TEXTURE_2D, framebuffer.colorAttachmentId, 0);
        break;
    }

    // Now generate the depth buffer, which will always be a renderbuffer.
    glGenRenderbuffers(1, &framebuffer.depthAttachmentId);
    glBindRenderbuffer(GL_RENDERBUFFER, framebuffer.depthAttachmentId);

    glRenderbufferStorage(GL_RENDERBUFFER, GL_DEPTH24_STENCIL8,
        properties.size.x, properties.size.y);
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_STENCIL_ATTACHMENT,
        GL_RENDERBUFFER, framebuffer.depthAttachmentId);

    glBindRenderbuffer(GL_RENDERBUFFER, 0);

    assert(glCheckFramebufferStatus(GL_FRAMEBUFFER) == GL_FRAMEBUFFER_COMPLETE,
        "Framebuffer is incomplete.");

    glBindFramebuffer(GL_FRAMEBUFFER, 0);

    return cast(NativeHandle) framebuffer;
}

void freeFramebuffer(NativeHandle framebuffer) nothrow
{
    auto data = cast(FramebufferData*) framebuffer;

    glDeleteFramebuffers(1, &data.id);

    // Order is important, as a renderbuffer is also a texture.
    if (glIsRenderbuffer(data.colorAttachmentId))
        glDeleteRenderbuffers(1, &data.colorAttachmentId);
    else if (glIsTexture(data.colorAttachmentId))
        glDeleteTextures(1, &data.colorAttachmentId);

    glDeleteRenderbuffers(1, &data.depthAttachmentId);

    destroy(data);
}

void setRenderTarget(in NativeHandle target) nothrow
{
    glBindFramebuffer(GL_FRAMEBUFFER, target ? *(cast(uint*) target) : 0);
}

void presentToScreen(in NativeHandle framebuffer, recti srcRegion, recti dstRegion) nothrow
{
    glBindFramebuffer(GL_READ_FRAMEBUFFER, *(cast(uint*) framebuffer));
    glBindFramebuffer(GL_DRAW_FRAMEBUFFER, 0);

    glClear(GL_COLOR_BUFFER_BIT);
    glBlitFramebuffer(srcRegion.x, srcRegion.y, srcRegion.width, srcRegion.height,
        dstRegion.x, dstRegion.y, dstRegion.width, dstRegion.height,
        GL_COLOR_BUFFER_BIT, GL_NEAREST);
}

NativeHandle getTextureFromFramebuffer(in NativeHandle framebuffer) nothrow
{
    FramebufferData* data = cast(FramebufferData*) framebuffer;

    assert(glIsTexture(data.colorAttachmentId), "Framebuffer modulate attachment is not a texture.");

    return cast(NativeHandle)&data.colorAttachmentId;
}