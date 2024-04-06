// This file is part of the ZyeWare Game Engine, and subject to the terms
// and conditions defined in the file 'LICENSE.txt', which is part
// of this source code package.
//
// Copyright © 2021-2024 ZyeByte. All rights reserved.
module zyeware.core.exception;

private mixin template GenericExceptionCtor()
{
    this(string message, string file = __FILE__, size_t line = __LINE__, Throwable next = null) pure nothrow
    {
        super(message, file, line, next);
    }
}

class CoreException : Exception
{
    mixin GenericExceptionCtor;
}

class VfsException : Exception
{
    mixin GenericExceptionCtor;
}

class ResourceException : Exception
{
    mixin GenericExceptionCtor;
}

// ===== PAL Exceptions =====

class DisplayException : Exception
{
    mixin GenericExceptionCtor;
}

class AudioException : Exception
{
    mixin GenericExceptionCtor;
}

class GraphicsException : Exception
{
    mixin GenericExceptionCtor;
}

class RenderException : Exception
{
    mixin GenericExceptionCtor;
}
