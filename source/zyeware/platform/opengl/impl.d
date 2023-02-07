module zyeware.platform.opengl.impl;

import zyeware.platform.opengl.api;
import zyeware.platform.opengl.renderer2d;
import zyeware.platform.opengl.renderer3d;

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