// This file is part of the ZyeWare Game Engine, and subject to the terms
// and conditions defined in the file 'LICENSE.txt', which is part
// of this source code package.
//
// Copyright 2021 ZyeByte
module zyeware.pal.generic.drivers;

import zyeware;

package(zyeware):

struct AudioDriver {
package(zyeware):
    void function() initialize;
    void function() loadLibraries;
    void function() cleanup;

    NativeHandle function(in NativeHandle busHandle) createSource;
    NativeHandle function(in ubyte[] encodedMemory, in AudioProperties properties) createBuffer;
    NativeHandle function(string name) createBus;

    void function(NativeHandle handle) freeSource;
    void function(NativeHandle handle) freeBuffer;
    void function(NativeHandle handle) freeBus;

    void function(NativeHandle handle, in LoopPoint loopPoint) setBufferLoopPoint;
    LoopPoint function(in NativeHandle handle) nothrow getBufferLoopPoint;

    void function(NativeHandle sourceHandle, in NativeHandle bufferHandle) setSourceBuffer;
    void function(NativeHandle sourceHandle, in NativeHandle busHandle) setSourceBus;
    void function(NativeHandle handle, float volume) setSourceVolume;
    void function(NativeHandle handle, float pitch) setSourcePitch;
    void function(NativeHandle handle, bool isLooping) setSourceLooping;
    float function(in NativeHandle handle) nothrow getSourceVolume;
    float function(in NativeHandle handle) nothrow getSourcePitch;
    bool function(in NativeHandle handle) nothrow isSourceLooping;
    SourceState function(in NativeHandle handle) nothrow getSourceState;

    void function(NativeHandle handle) playSource;
    void function(NativeHandle handle) pauseSource;
    void function(NativeHandle handle) stopSource;

    void function(NativeHandle handle, float volume) setBusVolume;
    float function(in NativeHandle handle) nothrow getBusVolume;

    void function(NativeHandle handle) updateSourceBuffers;
}

struct DisplayDriver {
package(zyeware):
    NativeHandle function(in DisplayProperties properties, in Display container) createDisplay;
    void function(NativeHandle handle) destroyDisplay;

    void function(NativeHandle handle) update;
    void function(NativeHandle handle) swapBuffers;

    bool function(in NativeHandle handle, KeyCode code) nothrow isKeyPressed;
    bool function(in NativeHandle handle, MouseCode code) nothrow isMouseButtonPressed;
    bool function(in NativeHandle handle, size_t gamepadIndex, GamepadButton button) nothrow isGamepadButtonPressed;
    float function(in NativeHandle handle, size_t gamepadIndex, GamepadAxis axis) nothrow getGamepadAxisValue;
    vec2i function(in NativeHandle handle) nothrow getCursorPosition;

    void function(NativeHandle handle, bool value) setVSyncEnabled;
    bool function(in NativeHandle handle) nothrow isVSyncEnabled;

    void function(NativeHandle handle, vec2i value) setPosition;
    vec2i function(in NativeHandle handle) nothrow getPosition;

    void function(NativeHandle handle, vec2i value) setSize;
    vec2i function(in NativeHandle handle) nothrow getSize;

    void function(NativeHandle handle, bool value) setFullscreen;
    bool function(in NativeHandle handle) nothrow isFullscreen;

    void function(NativeHandle handle, bool value) setResizable;
    bool function(in NativeHandle handle) nothrow isResizable;

    void function(NativeHandle handle, bool value) setDecorated;
    bool function(in NativeHandle handle) nothrow isDecorated;

    void function(NativeHandle handle, bool value) setFocused;
    bool function(in NativeHandle handle) nothrow isFocused;

    void function(NativeHandle handle, bool value) setVisible;
    bool function(in NativeHandle handle) nothrow isVisible;

    void function(NativeHandle handle, bool value) setMinimized;
    bool function(in NativeHandle handle) nothrow isMinimized;

    void function(NativeHandle handle, bool value) setMaximized;
    bool function(in NativeHandle handle) nothrow isMaximized;

    void function(NativeHandle handle, in Image image) setIcon;
    const(Image) function(in NativeHandle handle) nothrow getIcon;

    void function(NativeHandle handle, in Cursor cursor) setCursor;
    const(Cursor) function(in NativeHandle handle) nothrow getCursor;

    void function(NativeHandle handle, string title) setTitle;
    string function(in NativeHandle handle) nothrow getTitle;

    void function(NativeHandle handle, bool value) setMouseCursorVisible;
    bool function(in NativeHandle handle) nothrow isMouseCursorVisible;

    void function(NativeHandle handle, bool value) setMouseCursorCaptured;
    bool function(in NativeHandle handle) nothrow isMouseCursorCaptured;

    void function(NativeHandle handle, string value) setClipboardString;
    string function(in NativeHandle handle) getClipboardString;
}

struct GraphicsDriver {
package(zyeware):
    struct Api {
        void function() initialize;
        void function() cleanup;

        NativeHandle function(in Vertex3d[] vertices, in uint[] indices) createMesh;
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

    struct Renderer2d {
        void function() initialize;
        void function() cleanup;
        void function(in mat4 projectionMatrix, in mat4 viewMatrix) begin;
        void function() end;
        void function(in Vertex2d[] vertices, in uint[] indices, in mat4 transform, in Texture2d texture, in Material material) drawVertices;
        void function(in rect dimensions, in mat4 transform, in color modulate, in Texture2d texture, in Material material, in rect region) drawRectangle;
        void function(in string text, in BitmapFont font, in vec2 position, in color modulate, ubyte alignment, in Material material) drawString;
        void function(in wstring text, in BitmapFont font, in vec2 position, in color modulate, ubyte alignment, in Material material) drawWString;
        void function(in dstring text, in BitmapFont font, in vec2 position, in color modulate, ubyte alignment, in Material material) drawDString;
    }

    Api api;
    Renderer2d r2d;
}
