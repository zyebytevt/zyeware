// This file is part of the ZyeWare Game Engine, and subject to the terms
// and conditions defined in the file 'LICENSE.txt', which is part
// of this source code package.
//
// Copyright 2021 ZyeByte
module zyeware.rendering.opengl.api;

version (ZW_OpenGL):
package(zyeware.rendering.opengl):

import bindbc.opengl;

import zyeware.common;
import zyeware.core.debugging.profiler;
import zyeware.rendering;

import zyeware.rendering.opengl.buffer;

bool[RenderFlag] pFlagValues;

version (Windows)
{
    extern(Windows) static void glErrorCallback(GLenum source, GLenum type, GLuint id, GLenum severity, GLsizei length,
        const(char)* message, void* userParam) nothrow
    {
        glErrorCallbackImpl(source, type, id, severity, length, message, userParam);
    }
}
else
{
    extern(C) static void glErrorCallback(GLenum source, GLenum type, GLuint id, GLenum severity, GLsizei length,
        const(char)* message, void* userParam) nothrow
    {
        glErrorCallbackImpl(source, type, id, severity, length, message, userParam);
    }
}

void glErrorCallbackImpl(GLenum source, GLenum type, GLuint id, GLenum severity, GLsizei length,
    const(char)* message, void* userParam) nothrow
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

    Logger.core.log(logLevel, "%s: %s", typeName, cast(string) message[0..length]);
}

void apiInitialize()
{
    glEnable(GL_BLEND);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

    glEnable(GL_CULL_FACE);
    glCullFace(GL_BACK);
    glFrontFace(GL_CCW);
    
    //glAlphaFunc(GL_GREATER, 0);

    glDepthFunc(GL_LEQUAL);
    
    glEnable(GL_DEBUG_OUTPUT_SYNCHRONOUS);
    glDebugMessageCallback(&glErrorCallback, null);

    glLineWidth(2);
    glPointSize(4);

    {
        GLboolean resultBool;
        GLint resultInt;

        glGetBooleanv(GL_DEPTH_TEST, &resultBool);
        pFlagValues[RenderFlag.depthTesting] = cast(bool) resultBool;
        glGetBooleanv(GL_DEPTH_WRITEMASK, &resultBool);
        pFlagValues[RenderFlag.depthBufferWriting] = cast(bool) resultBool;
        glGetBooleanv(GL_CULL_FACE, &resultBool);
        pFlagValues[RenderFlag.culling] = cast(bool) resultBool;
        glGetBooleanv(GL_STENCIL_TEST, &resultBool);
        pFlagValues[RenderFlag.stencilTesting] = cast(bool) resultBool;
        glGetIntegerv(GL_POLYGON_MODE, &resultInt);
        pFlagValues[RenderFlag.wireframe] = resultInt == GL_LINE;
    }
}

void apiLoadLibraries()
{
    import loader = bindbc.loader.sharedlib;
    import std.string : fromStringz;

    if (isOpenGLLoaded())
        return;

    immutable glResult = loadOpenGL();
    
    if (glResult != glSupport)
    {
        foreach (info; loader.errors)
            Logger.core.log(LogLevel.warning, "OpenGL loader: %s", info.message.fromStringz);

        switch (glResult)
        {
        case GLSupport.noLibrary:
            throw new GraphicsException("Could not find OpenGL shared library.");

        case GLSupport.badLibrary:
            throw new GraphicsException("Provided OpenGL shared is corrupted.");

        case GLSupport.noContext:
            throw new GraphicsException("No OpenGL context available.");

        default:
            Logger.core.log(LogLevel.warning, "Got older OpenGL version than expected. This might lead to errors.");
        }
    }
}

void apiCleanup()
{
}

void apiSetClearColor(in Color value) nothrow
{
    glClearColor(value.r, value.g, value.b, value.a);
}

void apiClear() nothrow
{
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
}

void apiSetViewport(int x, int y, uint width, uint height) nothrow
{
    glViewport(x, y, cast(GLsizei) width, cast(GLsizei) height);
}

void apiDrawIndexed(size_t count) nothrow
{
    glDrawElements(GL_TRIANGLES, cast(int) count, GL_UNSIGNED_INT, null);
    
    version (ZW_Profiling)
    {
        ++Profiler.currentWriteData.renderData.drawCalls;
        Profiler.currentWriteData.renderData.polygonCount += count / 3;
    }
}

void apiPackLightConstantBuffer(ref ConstantBuffer buffer, in Renderer3D.Light[] lights) nothrow
{
    Vector4f[10] positions;
    Vector4f[10] colors;
    Vector4f[10] attenuations;

    for (size_t i; i < lights.length; ++i)
    {
        positions[i] = Vector4f(lights[i].position, 0);
        colors[i] = lights[i].color;
        attenuations[i] = Vector4f(lights[i].attenuation, 0);
    }

    buffer.setData(buffer.getEntryOffset("position"), positions);
    buffer.setData(buffer.getEntryOffset("color"), colors);
    buffer.setData(buffer.getEntryOffset("attenuation"), attenuations);
}

bool apiGetFlag(RenderFlag flag) nothrow
{
    return pFlagValues[flag];
}

void apiSetFlag(RenderFlag flag, bool value) nothrow
{
    if (pFlagValues[flag] == value)
        return;

    final switch (flag) with (RenderFlag)
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

    pFlagValues[flag] = value;
}

size_t apiGetCapability(RenderCapability capability) nothrow
{
    final switch (capability) with (RenderCapability)
    {
    case maxTextureSlots:
        GLint result;
        glGetIntegerv(GL_MAX_TEXTURE_IMAGE_UNITS, &result);
        return result;
    }
}