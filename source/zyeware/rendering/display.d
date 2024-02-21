// This file is part of the ZyeWare Game Engine, and subject to the terms
// and conditions defined in the file 'LICENSE.txt', which is part
// of this source code package.
//
// Copyright 2021 ZyeByte
module zyeware.rendering.display;

import zyeware;
import zyeware.pal.pal;

struct DisplayProperties
{
    string title = "ZyeWare Engine";
    Flag!"resizable" resizable = Yes.resizable;
    vec2i size = vec2i(1280, 720);
    Image icon;
}

class Display : NativeObject
{
protected:
    NativeHandle mNativeHandle;
    const DisplayProperties mProperties;

public:
    this(in DisplayProperties properties)
    {
        mProperties = properties;
        mNativeHandle = Pal.display.createDisplay(properties, this);
    }

    ~this()
    {
        Pal.display.destroyDisplay(mNativeHandle);
    }

    void update()
    {
        Pal.display.update(mNativeHandle);
    }

    void swapBuffers()
    {
        Pal.display.swapBuffers(mNativeHandle);
    }

    bool isKeyPressed(KeyCode code) nothrow
    {
        return Pal.display.isKeyPressed(mNativeHandle, code);
    }

    bool isMouseButtonPressed(MouseCode code) nothrow
    {
        return Pal.display.isMouseButtonPressed(mNativeHandle, code);
    }

    bool isGamepadButtonPressed(size_t gamepadIdx, GamepadButton button) nothrow
    {
        return Pal.display.isGamepadButtonPressed(mNativeHandle, gamepadIdx, button);
    }

    float getGamepadAxisValue(size_t gamepadIdx, GamepadAxis axis) nothrow
    {
        return Pal.display.getGamepadAxisValue(mNativeHandle, gamepadIdx, axis);
    }

    vec2i cursorPosition() const nothrow
    {
        return Pal.display.getCursorPosition(mNativeHandle);
    }

    void isVSyncEnabled(bool value)
    {
        Pal.display.setVSyncEnabled(mNativeHandle, value);
    }

    bool isVSyncEnabled() const nothrow
    {
        return Pal.display.isVSyncEnabled(mNativeHandle);
    }

    const(NativeHandle) handle() pure const nothrow
    {
        return mNativeHandle;
    }

    vec2i position() const nothrow
    {
        return Pal.display.getPosition(mNativeHandle);
    }

    void position(vec2i value)
    {
        Pal.display.setPosition(mNativeHandle, value);
    }

    vec2i size() const nothrow
    {
        return Pal.display.getSize(mNativeHandle);
    }

    void size(vec2i value)
    {
        Pal.display.setSize(mNativeHandle, value);
    }

    bool isFullscreen() const nothrow
    {
        return Pal.display.isFullscreen(mNativeHandle);
    }

    void isFullscreen(bool value)
    {
        Pal.display.setFullscreen(mNativeHandle, value);
    }

    bool isResizable() const nothrow
    {
        return Pal.display.isResizable(mNativeHandle);
    }

    void isResizable(bool value)
    {
        Pal.display.setResizable(mNativeHandle, value);
    }

    bool isDecorated() const nothrow
    {
        return Pal.display.isDecorated(mNativeHandle);
    }

    void isDecorated(bool value)
    {
        Pal.display.setDecorated(mNativeHandle, value);
    }

    bool isFocused() const nothrow
    {
        return Pal.display.isFocused(mNativeHandle);
    }

    void isFocused(bool value)
    {
        Pal.display.setFocused(mNativeHandle, value);
    }

    bool isVisible() const nothrow
    {
        return Pal.display.isVisible(mNativeHandle);
    }

    void isVisible(bool value)
    {
        Pal.display.setVisible(mNativeHandle, value);
    }

    bool isMinimized() const nothrow
    {
        return Pal.display.isMinimized(mNativeHandle);
    }

    void isMinimized(bool value)
    {
        Pal.display.setMinimized(mNativeHandle, value);
    }

    bool isMaximized() const nothrow
    {
        return Pal.display.isMaximized(mNativeHandle);
    }

    void isMaximized(bool value)
    {
        Pal.display.setMaximized(mNativeHandle, value);
    }

    bool isMouseCursorVisible() const nothrow
    {
        return Pal.display.isMouseCursorVisible(mNativeHandle);
    }

    void isMouseCursorVisible(bool value)
    {
        Pal.display.setMouseCursorVisible(mNativeHandle, value);
    }

    string title() const nothrow
    {
        return Pal.display.getTitle(mNativeHandle);
    }

    void title(string value)
    {
        Pal.display.setTitle(mNativeHandle, value);
    }

    bool isMouseCursorCaptured() const nothrow
    {
        return Pal.display.isMouseCursorCaptured(mNativeHandle);
    }

    void isMouseCursorCaptured(bool value)
    {
        Pal.display.setMouseCursorCaptured(mNativeHandle, value);
    }

    const(Image) icon() const nothrow
    {
        return Pal.display.getIcon(mNativeHandle);
    }

    void icon(in Image value)
    {
        Pal.display.setIcon(mNativeHandle, value);
    }

    string clipboardString()
    {
        return Pal.display.getClipboardString(mNativeHandle);
    }

    void clipboardString(string value)
    {
        Pal.display.setClipboardString(mNativeHandle, value);
    }

    void cursor(in Cursor value)
    {
        Pal.display.setCursor(mNativeHandle, value);
    }

    const(Cursor) cursor() const
    {
        return Pal.display.getCursor(mNativeHandle);
    }
}