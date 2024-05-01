// This file is part of the ZyeWare Game Engine, and subject to the terms
// and conditions defined in the file 'LICENSE.txt', which is part
// of this source code package.
//
// Copyright © 2021-2024 ZyeByte. All rights reserved.
module zyeware.subsystems.graphics.callbacks;

import zyeware;
import zyeware.subsystems.graphics;

package(zyeware):

struct GraphicsCallbacks
{
    void function() load;
    void function() unload;

    NativeHandle function(in Image image, in TextureProperties properties) createTexture2d;
    void function(NativeHandle texture) nothrow freeTexture2d;

    NativeHandle function(in Image[6] images, in TextureProperties properties) createTextureCubeMap;
    void function(NativeHandle texture) nothrow freeTextureCubeMap;

    NativeHandle function(in FramebufferProperties properties) createFramebuffer;
    void function(NativeHandle framebuffer) nothrow freeFramebuffer;
    void function(in NativeHandle target) nothrow setRenderTarget;
    void function(in NativeHandle framebuffer, recti srcRegion, recti dstRegion) nothrow presentToScreen;
    NativeHandle function(in NativeHandle framebuffer) nothrow getTextureFromFramebuffer;

    NativeHandle function(in ShaderProperties properties) createShader;
    void function(NativeHandle shader) nothrow freeShader;
    void function(in NativeHandle shader, in string name, in float value) nothrow setShaderUniform1f;
    void function(in NativeHandle shader, in string name, in vec2 value) nothrow setShaderUniform2f;
    void function(in NativeHandle shader, in string name, in vec3 value) nothrow setShaderUniform3f;
    void function(in NativeHandle shader, in string name, in vec4 value) nothrow setShaderUniform4f;
    void function(in NativeHandle shader, in string name, in int value) nothrow setShaderUniform1i;
    void function(in NativeHandle shader, in string name, in mat4 value) nothrow setShaderUniformMat4f;

    NativeHandle function(size_t size, bool dynamic) createIndexBuffer;
    void function(NativeHandle buffer) nothrow freeIndexBuffer;
    NativeHandle function(in uint[] indices, bool dynamic) createIndexBufferWithData;
    void function(NativeHandle buffer, in uint[] indices) updateIndexBufferData;

    NativeHandle function(size_t size, in BufferLayout layout, bool dynamic) createDataBuffer;
    void function(NativeHandle buffer) nothrow freeDataBuffer;
    NativeHandle function(in void[] data, in BufferLayout layout, bool dynamic) createDataBufferWithData;
    void function(NativeHandle buffer, in void[] data) updateDataBufferData;

    NativeHandle function() createBufferGroup;
    void function(NativeHandle group) nothrow freeBufferGroup;
    void function(NativeHandle group, in NativeHandle buffer) nothrow setBufferGroupDataBuffer;
    void function(NativeHandle group, in NativeHandle buffer) nothrow setBufferGroupIndexBuffer;
    void function(NativeHandle group) nothrow bindBufferGroup;

    void function(recti region) nothrow setViewport;
    void function(GraphicsFlag flag, bool value) nothrow setGraphicsFlag;
    bool function(GraphicsFlag flag) nothrow getGraphicsFlag;
    size_t function(GraphicsCapability capability) nothrow getCapability;
    void function(color clearColor) nothrow clearScreen;
}