// This file is part of the ZyeWare Game Engine, and subject to the terms
// and conditions defined in the file 'LICENSE.txt', which is part
// of this source code package.
//
// Copyright © 2021-2024 ZyeByte. All rights reserved.
module zyeware.platform.opengl.texture;

import bindbc.opengl;

import zyeware;

package (zyeware.platform.opengl):

NativeHandle createTexture2d(in Image image, in TextureProperties properties)
{
    const(ubyte)[] pixels = image.pixels;

    assert(pixels.length <= image.size.x * image.size.y * image.channels,
        "Too much pixel data for texture size.");

    GLenum internalFormat, srcFormat;

    final switch (image.channels)
    {
    case 1:
    case 2:
        internalFormat = GL_ALPHA;
        srcFormat = GL_ALPHA;
        break;

    case 3:
        internalFormat = GL_RGB8;
        srcFormat = GL_RGB;
        break;

    case 4:
        internalFormat = GL_RGBA8;
        srcFormat = GL_RGBA;
        break;
    }

    auto id = new uint;

    glGenTextures(1, id);
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, *id);

    glTexImage2D(GL_TEXTURE_2D, 0, internalFormat, image.size.x, image.size.y,
        0, srcFormat, GL_UNSIGNED_BYTE, pixels.ptr);

    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, getGLFilter(properties.minFilter));
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, getGLFilter(properties.magFilter));

    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, getGLWrapMode(properties.wrapS));
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, getGLWrapMode(properties.wrapT));

    if (properties.generateMipmaps)
        glGenerateMipmap(GL_TEXTURE_2D);

    return cast(NativeHandle) id;
}

NativeHandle createTextureCubeMap(in Image[6] images, in TextureProperties properties)
{
    auto id = new uint;

    glGenTextures(1, id);
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_CUBE_MAP, *id);

    for (size_t i; i < 6; ++i)
    {
        GLenum internalFormat, srcFormat;

        final switch (images[i].channels)
        {
        case 1:
        case 2:
            internalFormat = GL_ALPHA;
            srcFormat = GL_ALPHA;
            break;

        case 3:
            internalFormat = GL_RGB8;
            srcFormat = GL_RGB;
            break;

        case 4:
            internalFormat = GL_RGBA8;
            srcFormat = GL_RGBA;
            break;
        }

        glTexImage2D(GL_TEXTURE_CUBE_MAP_POSITIVE_X + cast(int) i, 0,
            internalFormat, images[i].size.x, images[i].size.y, 0, srcFormat,
            GL_UNSIGNED_BYTE, images[i].pixels.ptr);
    }

    glTexParameteri(GL_TEXTURE_CUBE_MAP, GL_TEXTURE_MIN_FILTER, getGLFilter(properties.minFilter));
    glTexParameteri(GL_TEXTURE_CUBE_MAP, GL_TEXTURE_MAG_FILTER, getGLFilter(properties.magFilter));

    glTexParameteri(GL_TEXTURE_CUBE_MAP, GL_TEXTURE_WRAP_S, getGLWrapMode(properties.wrapS));
    glTexParameteri(GL_TEXTURE_CUBE_MAP, GL_TEXTURE_WRAP_T, getGLWrapMode(properties.wrapT));

    if (properties.generateMipmaps)
        glGenerateMipmap(GL_TEXTURE_CUBE_MAP);

    return cast(NativeHandle) id;
}

void freeTexture2d(NativeHandle texture) nothrow
{
    auto id = cast(uint*) texture;

    glDeleteTextures(1, id);

    destroy(id);
}

void freeTextureCubeMap(NativeHandle texture) nothrow
{
    freeTexture2d(texture);
}

void bindTexture2d(in NativeHandle texture, size_t slot) nothrow
{
    glActiveTexture(GL_TEXTURE0 + cast(uint) slot);
    glBindTexture(GL_TEXTURE_2D, *cast(uint*) texture);
}

void bindTextureCubeMap(in NativeHandle texture, size_t slot) nothrow
{
    glActiveTexture(GL_TEXTURE0 + cast(uint) slot);
    glBindTexture(GL_TEXTURE_CUBE_MAP, *cast(uint*) texture);
}

private:

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