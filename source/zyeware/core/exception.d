// This file is part of the ZyeWare Game Engine, and subject to the terms
// and conditions defined in the file 'LICENSE.txt', which is part
// of this source code package.
//
// Copyright 2021 ZyeByte
module zyeware.core.exception;

private template CreateGenericExceptionType(string name)
{
    enum CreateGenericExceptionType = `class ` ~ name ~ ` : Exception
    {
        this(string message, string file = __FILE__,
            size_t line = __LINE__, Throwable next = null) pure nothrow
        {
            super(message, file, line, next);
        }
    }`;
}

mixin(CreateGenericExceptionType!"CoreException");
mixin(CreateGenericExceptionType!"VFSException");
mixin(CreateGenericExceptionType!"AudioException");
mixin(CreateGenericExceptionType!"GraphicsException");
mixin(CreateGenericExceptionType!"RenderException");
mixin(CreateGenericExceptionType!"EntityException");
mixin(CreateGenericExceptionType!"ComponentException");
mixin(CreateGenericExceptionType!"SystemException");
mixin(CreateGenericExceptionType!"GUIException");
