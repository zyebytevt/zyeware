// This file is part of the ZyeWare Game Engine, and subject to the terms
// and conditions defined in the file 'LICENSE.txt', which is part
// of this source code package.
//
// Copyright 2021 ZyeByte
module zyeware.platform.opengl.framebuffer;

version (ZW_OpenGL):
package(zyeware.platform.opengl):

import std.exception : enforce;

import bindbc.opengl;

import zyeware.common;
import zyeware.rendering;
import zyeware.platform.opengl.texture;

class OGLFramebuffer : Framebuffer
{
protected:
    FramebufferProperties mProperties;
    uint mID;
    Texture2D mColorAttachment, mDepthAttachment;

package(zyeware.platform.opengl):
    this(in FramebufferProperties properties)
    {
        mProperties = properties;
        invalidate();
    }

    static Framebuffer create(in FramebufferProperties properties)
    {
        return new OGLFramebuffer(properties);
    }

public:
    ~this()
    {
        glDeleteFramebuffers(1, &mID);
    }

    void bind() const
    {
        glBindFramebuffer(GL_FRAMEBUFFER, mID);
    }

    void unbind() const
    {
        glBindFramebuffer(GL_FRAMEBUFFER, 0);
    }

    void invalidate()
    {
        glGenFramebuffers(1, &mID);
        glBindFramebuffer(GL_FRAMEBUFFER, mID);

        uint colorAttachmentID, depthAttachmentID;

        glGenTextures(1, &colorAttachmentID);
        glGenTextures(1, &depthAttachmentID);

        glBindTexture(GL_TEXTURE_2D, colorAttachmentID);
        glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA8, mProperties.size.x, mProperties.size.y, 0, GL_RGBA, GL_UNSIGNED_BYTE, null);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);

        glBindTexture(GL_TEXTURE_2D, depthAttachmentID);
        glTexImage2D(GL_TEXTURE_2D, 0, GL_DEPTH24_STENCIL8, mProperties.size.x, mProperties.size.y, 0, GL_DEPTH_STENCIL, GL_UNSIGNED_INT_24_8, null);
        
        glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, colorAttachmentID, 0);
        glFramebufferTexture2D(GL_FRAMEBUFFER, GL_DEPTH_STENCIL_ATTACHMENT, GL_TEXTURE_2D, depthAttachmentID, 0);

        enforce!GraphicsException(glCheckFramebufferStatus(GL_FRAMEBUFFER) == GL_FRAMEBUFFER_COMPLETE, "Framebuffer is incomplete.");

        mColorAttachment = new OGLTexture2D(colorAttachmentID);
        mDepthAttachment = new OGLTexture2D(depthAttachmentID);

        glBindFramebuffer(GL_FRAMEBUFFER, 0);
    }

    const(FramebufferProperties) properties() pure const nothrow
    {
        return mProperties;
    }

    void properties(FramebufferProperties value) nothrow
    {
        mProperties = value;
    }

    const(Texture2D) colorAttachment() const nothrow
    {
        return mColorAttachment;
    }

    const(Texture2D) depthAttachment() const nothrow
    {
        return mDepthAttachment;
    }
}