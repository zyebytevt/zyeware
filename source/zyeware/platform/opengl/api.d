// This file is part of the ZyeWare Game Engine, and subject to the terms
// and conditions defined in the file 'LICENSE.txt', which is part
// of this source code package.
//
// Copyright © 2021-2024 ZyeByte. All rights reserved.
module zyeware.platform.opengl.api;

import std.typecons : Tuple;
import std.exception : assumeWontThrow;
import std.string : format, toStringz, fromStringz;
import std.conv : dtext;
import std.algorithm : reduce;

import bindbc.opengl;

import zyeware;
import zyeware.subsystems.graphics;

package(zyeware.platform.opengl):

bool[cast(size_t) GraphicsFlag.max + 1] pFlagValues;

version (Windows)
{
    extern (Windows) static void errorCallback(GLenum source, GLenum type,
        GLuint id, GLenum severity, GLsizei length, stringz message, void* userParam) nothrow
    {
        errorCallbackImpl(source, type, id, severity, length, message, userParam);
    }
}
else
{
    extern (C) static void errorCallback(GLenum source, GLenum type, GLuint id,
        GLenum severity, GLsizei length, stringz message, void* userParam) nothrow
    {
        errorCallbackImpl(source, type, id, severity, length, message, userParam);
    }
}

pragma(inline, true) static void errorCallbackImpl(GLenum source, GLenum type,
    GLuint id, GLenum severity, GLsizei length, stringz message, void* userParam) nothrow
{
    glGetError();

    string typeName;
    LogLevel logLevel;

    switch (type)
    {
    case GL_DEBUG_TYPE_ERROR:
        typeName = "Error";
        break;

    case GL_DEBUG_TYPE_DEPRECATED_BEHAVIOR:
        typeName = "Deprecated Behavior";
        break;

    case GL_DEBUG_TYPE_UNDEFINED_BEHAVIOR:
        typeName = "Undefined Behavior";
        break;

    case GL_DEBUG_TYPE_PERFORMANCE:
        typeName = "Performance";
        break;

    case GL_DEBUG_TYPE_OTHER:
    default:
        return;
    }

    switch (severity)
    {
    case GL_DEBUG_SEVERITY_LOW:
        logLevel = LogLevel.info;
        break;

    case GL_DEBUG_SEVERITY_MEDIUM:
        logLevel = LogLevel.warning;
        break;

    case GL_DEBUG_SEVERITY_HIGH:
        logLevel = LogLevel.error;
        break;

    default:
        logLevel = LogLevel.debug_;
        break;
    }

    Logger.core.log(logLevel, format!"%s: %s"(typeName, message.fromStringz).assumeWontThrow);
}

void setViewport(recti region) nothrow
{
    glViewport(region.x, region.y, region.width, region.height);
}

void setGraphicsFlag(GraphicsFlag flag, bool value) nothrow
{
    if (pFlagValues[cast(size_t) flag] == value)
        return;

    final switch (flag) with (GraphicsFlag)
    {
    case depthTesting:
        if (value)
            glEnable(GL_DEPTH_TEST);
        else
            glDisable(GL_DEPTH_TEST);
        break;

    case depthBufferWriting:
        glDepthMask(value);
        break;

    case culling:
        if (value)
            glEnable(GL_CULL_FACE);
        else
            glDisable(GL_CULL_FACE);
        break;

    case stencilTesting:
        if (value)
            glEnable(GL_STENCIL_TEST);
        else
            glDisable(GL_STENCIL_TEST);
        break;

    case wireframe:
        glPolygonMode(GL_FRONT_AND_BACK, value ? GL_LINE : GL_FILL);
        break;
    }

    pFlagValues[cast(size_t) flag] = value;
}

bool getGraphicsFlag(GraphicsFlag flag) nothrow
{
    return pFlagValues[cast(size_t) flag];
}

size_t getCapability(GraphicsCapability capability) nothrow
{
    final switch (capability) with (GraphicsCapability)
    {
    case maxTextureSlots:
        GLint result;
        glGetIntegerv(GL_MAX_TEXTURE_IMAGE_UNITS, &result);
        return result;
    }
}

void clearScreen(color clearColor) nothrow
{
    glClearColor(clearColor.r, clearColor.g, clearColor.b, clearColor.a);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
}