// This file is part of the ZyeWare Game Engine, and subject to the terms
// and conditions defined in the file 'LICENSE.txt', which is part
// of this source code package.
//
// Copyright © 2021-2024 ZyeByte. All rights reserved.
module zyeware.platform.opengl.loader;

import std.string : fromStringz;

import bindbc.opengl;

import zyeware.subsystems.graphics;
import zyeware;

import zyeware.platform.opengl.api;
import zyeware.platform.opengl.buffer;
import zyeware.platform.opengl.framebuffer;
import zyeware.platform.opengl.shader;
import zyeware.platform.opengl.texture;

void loadOpenGl(ref GraphicsCallbacks callbacks) nothrow
{
    callbacks.load = &load;
    callbacks.unload = &unload;

    callbacks.createTexture2d = &createTexture2d;
    callbacks.freeTexture2d = &freeTexture2d;

    callbacks.createTextureCubeMap = &createTextureCubeMap;
    callbacks.freeTextureCubeMap = &freeTextureCubeMap;

    callbacks.createFramebuffer = &createFramebuffer;
    callbacks.freeFramebuffer = &freeFramebuffer;
    callbacks.setRenderTarget = &setRenderTarget;
    callbacks.presentToScreen = &presentToScreen;
    callbacks.getTextureFromFramebuffer = &getTextureFromFramebuffer;

    callbacks.createShader = &createShader;
    callbacks.freeShader = &freeShader;
    callbacks.setShaderUniform1f = &setShaderUniform1f;
    callbacks.setShaderUniform2f = &setShaderUniform2f;
    callbacks.setShaderUniform3f = &setShaderUniform3f;
    callbacks.setShaderUniform4f = &setShaderUniform4f;
    callbacks.setShaderUniform1i = &setShaderUniform1i;
    callbacks.setShaderUniformMat4f = &setShaderUniformMat4f;

    callbacks.createIndexBuffer = &createIndexBuffer;
    callbacks.freeIndexBuffer = &freeIndexBuffer;
    callbacks.createIndexBufferWithData = &createIndexBufferWithData;
    callbacks.updateIndexBufferData = &updateIndexBufferData;

    callbacks.createDataBuffer = &createDataBuffer;
    callbacks.freeDataBuffer = &freeDataBuffer;
    callbacks.createDataBufferWithData = &createDataBufferWithData;
    callbacks.updateDataBufferData = &updateDataBufferData;

    callbacks.createBufferGroup = &createBufferGroup;
    callbacks.freeBufferGroup = &freeBufferGroup;
    callbacks.setBufferGroupDataBuffer = &setBufferGroupDataBuffer;
    callbacks.setBufferGroupIndexBuffer = &setBufferGroupIndexBuffer;
    callbacks.bindBufferGroup = &bindBufferGroup;

    callbacks.setViewport = &setViewport;
    callbacks.setGraphicsFlag = &setGraphicsFlag;
    callbacks.getGraphicsFlag = &getGraphicsFlag;
    callbacks.getCapability = &getCapability;
    callbacks.clearScreen = &clearScreen;
}

private:

void load()
{
    import loader = bindbc.loader.sharedlib;

    if (isOpenGLLoaded())
        return;

    immutable glResult = loadOpenGL();

    if (glResult != glSupport)
    {
        foreach (info; loader.errors)
            Logger.core.warning("OpenGL loader: %s", info.message.fromStringz);

        switch (glResult)
        {
        case GLSupport.noLibrary:
            throw new GraphicsException("Could not find OpenGL shared library.");

        case GLSupport.badLibrary:
            throw new GraphicsException("Provided OpenGL shared library is corrupted.");

        case GLSupport.noContext:
            throw new GraphicsException("No OpenGL context available.");

        default:
            Logger.core.warning(
                "Got older OpenGL version than expected. This might lead to errors.");
        }
    }

    Logger.core.debug_("OpenGL dynamic library loaded.");

    glEnable(GL_BLEND);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

    glEnable(GL_CULL_FACE);
    glCullFace(GL_BACK);
    glFrontFace(GL_CCW);

    glDepthFunc(GL_LEQUAL);

    glEnable(GL_DEBUG_OUTPUT_SYNCHRONOUS);
    glDebugMessageCallback(&errorCallback, null);

    glLineWidth(2);
    glPointSize(4);

    {
        GLboolean resultBool;
        GLint resultInt;

        glGetBooleanv(GL_DEPTH_TEST, &resultBool);
        pFlagValues[cast(size_t) GraphicsFlag.depthTesting] = cast(bool) resultBool;
        glGetBooleanv(GL_DEPTH_WRITEMASK, &resultBool);
        pFlagValues[cast(size_t) GraphicsFlag.depthBufferWriting] = cast(bool) resultBool;
        glGetBooleanv(GL_CULL_FACE, &resultBool);
        pFlagValues[cast(size_t) GraphicsFlag.culling] = cast(bool) resultBool;
        glGetBooleanv(GL_STENCIL_TEST, &resultBool);
        pFlagValues[cast(size_t) GraphicsFlag.stencilTesting] = cast(bool) resultBool;
        glGetIntegerv(GL_POLYGON_MODE, &resultInt);
        pFlagValues[cast(size_t) GraphicsFlag.wireframe] = resultInt == GL_LINE;
    }

    Logger.core.info("Initialized OpenGL:");
    Logger.core.info("    Vendor: %s", glGetString(GL_VENDOR).fromStringz);
    Logger.core.info("    Renderer: %s", glGetString(GL_RENDERER).fromStringz);
    Logger.core.info("    Version: %s", glGetString(GL_VERSION).fromStringz);
    Logger.core.info("    GLSL Version: %s", glGetString(GL_SHADING_LANGUAGE_VERSION).fromStringz);
    Logger.core.info("    Extensions: %s", glGetString(GL_EXTENSIONS).fromStringz);
}

void unload()
{
}