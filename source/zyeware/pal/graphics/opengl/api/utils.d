module zyeware.pal.graphics.opengl.api.utils; version(ZW_PAL_OPENGL):

import zyeware;

import bindbc.opengl;

package(zyeware.pal.graphics.opengl):

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