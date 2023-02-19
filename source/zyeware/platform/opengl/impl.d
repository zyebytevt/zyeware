// This file is part of the ZyeWare Game Engine, and subject to the terms
// and conditions defined in the file 'LICENSE.txt', which is part
// of this source code package.
//
// Copyright 2021 ZyeByte
module zyeware.platform.opengl.impl;

version (ZW_OpenGL):
package(zyeware):

import zyeware.platform.opengl.api;
import zyeware.platform.opengl.renderer2d;
import zyeware.platform.opengl.renderer3d;
import zyeware.platform.opengl.buffer;
import zyeware.platform.opengl.texture;
import zyeware.platform.opengl.framebuffer;
import zyeware.platform.opengl.shader;
import zyeware.platform.opengl.window;

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

    // ===== Renderer2D =====
    Renderer2D.sInitializeImpl = &r2dInitialize;
    Renderer2D.sCleanupImpl = &r2dCleanup;
    Renderer2D.sBeginImpl = &r2dBegin;
    Renderer2D.sDrawRectImpl = &r2dDrawRect;
    Renderer2D.sEndImpl = &r2dEnd;
    Renderer2D.sFlushImpl = &r2dFlush;

    Renderer2D.sDrawStringImpl = &r2dDrawString!string;
    Renderer2D.sDrawWStringImpl = &r2dDrawString!wstring;
    Renderer2D.sDrawDStringImpl = &r2dDrawString!dstring;
    
    // ===== Renderer3D =====
    Renderer3D.sCleanupImpl = &r3dCleanup;
    Renderer3D.sInitializeImpl = &r3dInitialize;
    Renderer3D.sUploadLightsImpl = &r3dUploadLights;
    Renderer3D.sBeginImpl = &r3dBegin;
    Renderer3D.sEndImpl = &r3dEnd;
    Renderer3D.sFlushImpl = &r3dFlush;
    Renderer3D.sSubmitImpl = &r3dSubmit;
}