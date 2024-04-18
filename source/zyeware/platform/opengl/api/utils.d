// This file is part of the ZyeWare Game Engine, and subject to the terms
// and conditions defined in the file 'LICENSE.txt', which is part
// of this source code package.
//
// Copyright © 2021-2024 ZyeByte. All rights reserved.
module zyeware.platform.opengl.api.utils;

import zyeware;

import bindbc.opengl;

package(zyeware.platform.opengl):

GLenum getGLFilter(TextureProperties.Filter filter)
{
    final switch (filter) with (TextureProperties.Filter)
    {
    case nearest:
        return GL_NEAREST;
    case linear:
        return GL_LINEAR;
    case bilinear:
        return GL_LINEAR;
    case trilinear:
        return GL_LINEAR_MIPMAP_LINEAR;
    }
}

GLenum getGLWrapMode(TextureProperties.WrapMode wrapMode)
{
    final switch (wrapMode) with (TextureProperties.WrapMode)
    {
    case repeat:
        return GL_REPEAT;
    case mirroredRepeat:
        return GL_MIRRORED_REPEAT;
    case clampToEdge:
        return GL_CLAMP_TO_EDGE;
    }
}
