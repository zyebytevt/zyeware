// This file is part of the ZyeWare Game Engine, and subject to the terms
// and conditions defined in the file 'LICENSE.txt', which is part
// of this source code package.
//
// Copyright © 2021-2024 ZyeByte. All rights reserved.
module zyeware.platform.opengl.loader;

import zyeware.subsystems.graphics;

import api = zyeware.platform.opengl.api.api;
import r2d = zyeware.platform.opengl.renderer2d.api;

void loadOpenGl(ref GraphicsCallbacks callbacks) nothrow
{
    callbacks.load = &load;
    callbacks.unload = &unload;

    callbacks.createMesh = &api.createMesh;
    callbacks.createTexture2d = &api.createTexture2d;
    callbacks.createTextureCubeMap = &api.createTextureCubeMap;
    callbacks.createFramebuffer = &api.createFramebuffer;
    callbacks.createShader = &api.createShader;
    callbacks.freeMesh = &api.freeMesh;
    callbacks.freeTexture2d = &api.freeTexture2d;
    callbacks.freeTextureCubeMap = &api.freeTextureCubeMap;
    callbacks.freeFramebuffer = &api.freeFramebuffer;
    callbacks.freeShader = &api.freeShader;
    callbacks.setShaderUniform1f = &api.setShaderUniform1f;
    callbacks.setShaderUniform2f = &api.setShaderUniform2f;
    callbacks.setShaderUniform3f = &api.setShaderUniform3f;
    callbacks.setShaderUniform4f = &api.setShaderUniform4f;
    callbacks.setShaderUniform1i = &api.setShaderUniform1i;
    callbacks.setShaderUniformMat4f = &api.setShaderUniformMat4f;
    callbacks.setViewport = &api.setViewport;
    callbacks.setGraphicsFlag = &api.setGraphicsFlag;
    callbacks.getGraphicsFlag = &api.getGraphicsFlag;
    callbacks.getCapability = &api.getCapability;
    callbacks.clearScreen = &api.clearScreen;
    callbacks.setRenderTarget = &api.setRenderTarget;
    callbacks.presentToScreen = &api.presentToScreen;
    callbacks.getTextureFromFramebuffer = &api.getTextureFromFramebuffer;

    callbacks.r2dBegin = &r2d.begin;
    callbacks.r2dEnd = &r2d.end;
    callbacks.r2dDrawVertices = &r2d.drawVertices;
}

private:

void load()
{
    api.load();
    r2d.load();
}

void unload()
{
    r2d.unload();
    api.unload();
}