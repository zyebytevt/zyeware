// This file is part of the ZyeWare Game Engine, and subject to the terms
// and conditions defined in the file 'LICENSE.txt', which is part
// of this source code package.
//
// Copyright © 2021-2024 ZyeByte. All rights reserved.
module zyeware.platform.opengl.loader;

import zyeware.subsystems.graphics;

import api = zyeware.platform.opengl.api.api;
import r2d = zyeware.platform.opengl.renderer2d.api;

void loadOpenGl(ref GraphicsCallbacks callbacks, ref Renderer2dCallbacks r2dCallbacks) nothrow
{
    callbacks.load = &api.load;
    callbacks.unload = &api.unload;
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
    callbacks.setRenderFlag = &api.setRenderFlag;
    callbacks.getRenderFlag = &api.getRenderFlag;
    callbacks.getCapability = &api.getCapability;
    callbacks.clearScreen = &api.clearScreen;
    callbacks.setRenderTarget = &api.setRenderTarget;
    callbacks.presentToScreen = &api.presentToScreen;
    callbacks.getTextureFromFramebuffer = &api.getTextureFromFramebuffer;

    r2dCallbacks.load = &r2d.load;
    r2dCallbacks.unload = &r2d.unload;
    r2dCallbacks.begin = &r2d.begin;
    r2dCallbacks.end = &r2d.end;
    r2dCallbacks.drawVertices = &r2d.drawVertices;
    r2dCallbacks.drawRectangle = &r2d.drawRectangle;
    r2dCallbacks.drawString = &r2d.drawString;
    r2dCallbacks.drawWString = &r2d.drawWString;
    r2dCallbacks.drawDString = &r2d.drawDString;
}