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
    // ===== RenderAPI =====
    RenderAPI.sInitializeImpl = &apiInitialize;
    RenderAPI.sLoadLibrariesImpl = &apiLoadLibraries;
    RenderAPI.sCleanupImpl = &apiCleanup;

    RenderAPI.sSetClearColorImpl = &apiSetClearColor;
    RenderAPI.sClearImpl = &apiClear;
    RenderAPI.sSetViewportImpl = &apiSetViewport;
    RenderAPI.sDrawIndexedImpl = &apiDrawIndexed;
    RenderAPI.sPackLightConstantBufferImpl = &apiPackLightConstantBuffer;
    RenderAPI.sGetFlagImpl = &apiGetFlag;
    RenderAPI.sSetFlagImpl = &apiSetFlag;
    RenderAPI.sGetCapabilityImpl = &apiGetCapability;

    RenderAPI.sCreateBufferGroupImpl = () => new OGLBufferGroup();
    RenderAPI.sCreateDataBufferImpl = (size, layout, dynamic) => new OGLDataBuffer(size, layout, dynamic);
    RenderAPI.sCreateDataBufferWithDataImpl = (data, layout, dynamic) => new OGLDataBuffer(data, layout, dynamic);
    RenderAPI.sCreateIndexBufferImpl = (size, dynamic) => new OGLIndexBuffer(size, dynamic);
    RenderAPI.sCreateIndexBufferWithDataImpl = (indices, dynamic) => new OGLIndexBuffer(indices, dynamic);
    RenderAPI.sCreateConstantBufferImpl = (layout) => new OGLConstantBuffer(layout);

    RenderAPI.sCreateFramebufferImpl = (props) => new OGLFramebuffer(props);
    RenderAPI.sCreateTexture2DImpl = (image, props) => new OGLTexture2D(image, props);
    RenderAPI.sCreateTextureCubeMapImpl = (images, props) => new OGLTextureCubeMap(images, props);
    RenderAPI.sCreateWindowImpl = (props) => new OGLWindow(props);
    RenderAPI.sCreateShaderImpl = () => new OGLShader();

    RenderAPI.sLoadTexture2DImpl = (path) => OGLTexture2D.load(path);
    RenderAPI.sLoadTextureCubeMapImpl = (path) => OGLTextureCubeMap.load(path);
    RenderAPI.sLoadShaderImpl = (path) => OGLShader.load(path);
}