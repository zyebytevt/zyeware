module zyeware.platform.opengl.impl;

import zyeware.platform.opengl.api;
import zyeware.platform.opengl.renderer2d;

import zyeware.rendering;

void loadOpenGLBackend()
{
    // ===== RenderAPI =====
    RenderAPI.initialize = &apiInitialize;
    RenderAPI.loadLibraries = &apiLoadLibraries;
    RenderAPI.cleanup = &apiCleanup;

    RenderAPI.setClearColor = &apiSetClearColor;
    RenderAPI.clear = &apiClear;
    RenderAPI.setViewport = &apiSetViewport;
    RenderAPI.drawIndexed = &apiDrawIndexed;
    RenderAPI.packLightConstantBuffer = &apiPackLightConstantBuffer;
    RenderAPI.getFlag = &apiGetFlag;
    RenderAPI.setFlag = &apiSetFlag;
    RenderAPI.getCapability = &apiGetCapability;

    // ===== Renderer2D =====
    
}