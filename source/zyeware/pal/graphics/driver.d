// This file is part of the ZyeWare Game Engine, and subject to the terms
// and conditions defined in the file 'LICENSE.txt', which is part
// of this source code package.
//
// Copyright 2021 ZyeByte
module zyeware.pal.graphics.driver;

import zyeware;

import zyeware.pal.graphics.types;

struct GraphicsDriver
{
public:
    struct Api
    {
        void function() initialize;
        void function() cleanup;

        NativeHandle function(in Vertex3D[] vertices, in uint[] indices) createMesh;
        NativeHandle function(in Image image, in TextureProperties properties) createTexture2D;
        NativeHandle function(in Image[6] images, in TextureProperties properties) createTextureCubeMap;
        NativeHandle function(in FramebufferProperties properties) createFramebuffer;
        NativeHandle function(in ShaderProperties properties) createShader;

        void function(NativeHandle mesh) nothrow freeMesh;
        void function(NativeHandle texture) nothrow freeTexture2D;
        void function(NativeHandle texture) nothrow freeTextureCubeMap;
        void function(NativeHandle framebuffer) nothrow freeFramebuffer;
        void function(NativeHandle shader) nothrow freeShader;

        void function(in NativeHandle shader, in string name, in float value) nothrow setShaderUniform1f;
        void function(in NativeHandle shader, in string name, in vec2 value) nothrow setShaderUniform2f;
        void function(in NativeHandle shader, in string name, in vec3 value) nothrow setShaderUniform3f;
        void function(in NativeHandle shader, in string name, in vec4 value) nothrow setShaderUniform4f;
        void function(in NativeHandle shader, in string name, in int value) nothrow setShaderUniform1i;
        void function(in NativeHandle shader, in string name, in mat4 value) nothrow setShaderUniformMat4f;

        void function(recti region) nothrow setViewport;
        void function(RenderFlag flag, bool value) nothrow setRenderFlag;
        bool function(RenderFlag flag) nothrow getRenderFlag;
        size_t function(RenderCapability capability) nothrow getCapability;
        void function(color clearColor) nothrow clearScreen;

        void function(in NativeHandle target) nothrow setRenderTarget;
        void function(in NativeHandle framebuffer, recti srcRegion, recti dstRegion) nothrow presentToScreen;
        NativeHandle function(in NativeHandle framebuffer) nothrow getTextureFromFramebuffer;
    }

    struct Renderer2d
    {
        void function() initialize;
        void function() cleanup;
        void function(in mat4 projectionMatrix, in mat4 viewMatrix) beginScene;
        void function() endScene;
        void function() flush;
        void function(in Vertex2D[] vertices, in uint[] indices, in mat4 transform, in Texture2d texture, in Material material) drawVertices;
        void function(in rect dimensions, in mat4 transform, in color modulate, in Texture2d texture, in Material material, in rect region) drawRectangle;
        void function(in string text, in BitmapFont font, in vec2 position, in color modulate, ubyte alignment, in Material material) drawString;
        void function(in wstring text, in BitmapFont font, in vec2 position, in color modulate, ubyte alignment, in Material material) drawWString;
        void function(in dstring text, in BitmapFont font, in vec2 position, in color modulate, ubyte alignment, in Material material) drawDString;
    }

    struct Renderer3d
    {
        void function(in mat4 projectionMatrix, in mat4 viewMatrix, Environment3D environment) beginScene;
        void function() end;
        void function(in mat4 transform) submit;
    }

    Api api;
    Renderer2d renderer2d;
    Renderer3d renderer3d;
}