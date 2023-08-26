// This file is part of the ZyeWare Game Engine, and subject to the terms
// and conditions defined in the file 'LICENSE.txt', which is part
// of this source code package.
//
// Copyright 2021 ZyeByte
module zyeware.rendering.opengl.impl;

version (ZW_OpenGL):
package(zyeware):

import zyeware.rendering.opengl.api;
import zyeware.rendering.opengl.buffer;
import zyeware.rendering.opengl.texture;
import zyeware.rendering.opengl.framebuffer;
import zyeware.rendering.opengl.shader;
import zyeware.rendering.opengl.window;

import zyeware.rendering;

void loadOpenGLBackend()
{
    // ===== GraphicsAPI =====
    GraphicsAPI.sInitializeImpl = &apiInitialize;
    GraphicsAPI.sLoadLibrariesImpl = &apiLoadLibraries;
    GraphicsAPI.sCleanupImpl = &apiCleanup;

    GraphicsAPI.sSetClearColorImpl = &apiSetClearColor;
    GraphicsAPI.sClearImpl = &apiClear;
    GraphicsAPI.sSetViewportImpl = &apiSetViewport;
    GraphicsAPI.sDrawIndexedImpl = &apiDrawIndexed;
    GraphicsAPI.sPackLightConstantBufferImpl = &apiPackLightConstantBuffer;
    GraphicsAPI.sGetFlagImpl = &apiGetFlag;
    GraphicsAPI.sSetFlagImpl = &apiSetFlag;
    GraphicsAPI.sGetCapabilityImpl = &apiGetCapability;

    GraphicsAPI.sCreateBufferGroupImpl = () => new OGLBufferGroup();
    GraphicsAPI.sCreateDataBufferImpl = (size, layout, dynamic) => new OGLDataBuffer(size, layout, dynamic);
    GraphicsAPI.sCreateDataBufferWithDataImpl = (data, layout, dynamic) => new OGLDataBuffer(data, layout, dynamic);
    GraphicsAPI.sCreateIndexBufferImpl = (size, dynamic) => new OGLIndexBuffer(size, dynamic);
    GraphicsAPI.sCreateIndexBufferWithDataImpl = (indices, dynamic) => new OGLIndexBuffer(indices, dynamic);
    GraphicsAPI.sCreateConstantBufferImpl = (layout) => new OGLConstantBuffer(layout);

    GraphicsAPI.sCreateFramebufferImpl = (props) => new OGLFramebuffer(props);
    GraphicsAPI.sCreateTexture2DImpl = (image, props) => new OGLTexture2D(image, props);
    GraphicsAPI.sCreateTextureCubeMapImpl = (images, props) => new OGLTextureCubeMap(images, props);
    GraphicsAPI.sCreateWindowImpl = (props) => new OGLWindow(props);
    GraphicsAPI.sCreateShaderImpl = () => new OGLShader();

    GraphicsAPI.sLoadTexture2DImpl = (path) => OGLTexture2D.load(path);
    GraphicsAPI.sLoadTextureCubeMapImpl = (path) => OGLTextureCubeMap.load(path);
    GraphicsAPI.sLoadShaderImpl = (path) => OGLShader.load(path);
}