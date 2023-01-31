module zyeware.platform.opengl.impl;

import zyeware.platform.opengl.api;

import zyeware.rendering;

void loadOpenGLBackend()
{
    // ===== RenderAPI =====
    RenderAPI.initialize = &initialize;
    RenderAPI.loadLibraries = &loadLibraries;
    RenderAPI.cleanup = &cleanup;

    RenderAPI.setClearColor = &setClearColor;
    RenderAPI.clear = &clear;
    RenderAPI.setViewport = &setViewport;
    RenderAPI.drawIndexed = &drawIndexed;
    RenderAPI.packLightConstantBuffer = &packLightConstantBuffer;
    RenderAPI.getFlag = &getFlag;
    RenderAPI.setFlag = &setFlag;
    RenderAPI.getCapability = &getCapability;
}