// This file is part of the ZyeWare Game Engine, and subject to the terms
// and conditions defined in the file 'LICENSE.txt', which is part
// of this source code package.
//
// Copyright 2021 ZyeByte
module zyeware.rendering.display;

import zyeware.common;
import zyeware.rendering;
import zyeware.pal;
import zyeware.pal.display.opengl.display;

struct DisplayProperties
{
    string title = "ZyeWare Engine";
    Flag!"resizable" resizable = Yes.resizable;
    Vector2i size = Vector2i(1280, 720);
    Image icon;
}

class Display : NativeObject
{
protected:
    NativeHandle mNativeHandle;
    DisplayProperties mProperties;

public:
    this(DisplayProperties properties)
    {
        mProperties = properties;
        mNativeHandle = PAL.display.createDisplay(properties);
    }

    ~this()
    {
        PAL.display.destroyDisplay(mNativeHandle);
    }

    void update()
    {
        PAL.display.update(mNativeHandle);
    }

    void swapBuffers()
    {
        PAL.display.swapBuffers(mNativeHandle);
    }

    bool isKeyPressed(KeyCode code) nothrow
    {
        return PAL.display.isKeyPressed(mNativeHandle, code);
    }

    bool isMouseButtonPressed(MouseCode code) nothrow
    {
        return PAL.display.isMouseButtonPressed(mNativeHandle, code);
    }

    bool isGamepadButtonPressed(size_t gamepadIdx, GamepadButton button) nothrow
    {
        return PAL.display.isGamepadButtonPressed(mNativeHandle, gamepadIdx, button);
    }

    float getGamepadAxisValue(size_t gamepadIdx, GamepadAxis axis) nothrow
    {
        return PAL.display.getGamepadAxisValue(mNativeHandle, gamepadIdx, axis);
    }

    Vector2i cursorPosition() const nothrow
    {
        return PAL.display.getCursorPosition(mNativeHandle);
    }

    void isVSyncEnabled(bool value)
    {
        PAL.display.setVSyncEnabled(mNativeHandle, value);
    }

    bool isVSyncEnabled() const nothrow
    {
        return PAL.display.isVSyncEnabled(mNativeHandle);
    }

    const(NativeHandle) handle() pure const nothrow
    {
        return mNativeHandle;
    }

    Vector2i position() const nothrow
    {
        return PAL.display.getPosition(mNativeHandle);
    }

    void position(Vector2i value)
    {
        PAL.display.setPosition(mNativeHandle, value);
    }

    Vector2i size() const nothrow
    {
        return PAL.display.getSize(mNativeHandle);
    }

    void size(Vector2i value)
    {
        PAL.display.setSize(mNativeHandle, value);
    }

    bool isFullscreen() const nothrow
    {
        return PAL.display.isFullscreen(mNativeHandle);
    }

    void isFullscreen(bool value)
    {
        PAL.display.setFullscreen(mNativeHandle, value);
    }

    bool isResizable() const nothrow
    {
        return PAL.display.isResizable(mNativeHandle);
    }

    void isResizable(bool value)
    {
        PAL.display.setResizable(mNativeHandle, value);
    }

    bool isDecorated() const nothrow
    {
        return PAL.display.isDecorated(mNativeHandle);
    }

    void isDecorated(bool value)
    {
        PAL.display.setDecorated(mNativeHandle, value);
    }

    bool isFocused() const nothrow
    {
        return PAL.display.isFocused(mNativeHandle);
    }

    void isFocused(bool value)
    {
        PAL.display.setFocused(mNativeHandle, value);
    }

    bool isVisible() const nothrow
    {
        return PAL.display.isVisible(mNativeHandle);
    }

    void isVisible(bool value)
    {
        PAL.display.setVisible(mNativeHandle, value);
    }

    bool isMinimized() const nothrow
    {
        return PAL.display.isMinimized(mNativeHandle);
    }

    void isMinimized(bool value)
    {
        PAL.display.setMinimized(mNativeHandle, value);
    }

    bool isMaximized() const nothrow
    {
        return PAL.display.isMaximized(mNativeHandle);
    }

    void isMaximized(bool value)
    {
        PAL.display.setMaximized(mNativeHandle, value);
    }

    bool isMouseCursorVisible() const nothrow
    {
        return PAL.display.isMouseCursorVisible(mNativeHandle);
    }

    void isMouseCursorVisible(bool value)
    {
        PAL.display.setMouseCursorVisible(mNativeHandle, value);
    }

    string title() const nothrow
    {
        return PAL.display.getTitle(mNativeHandle);
    }

    void title(string value)
    {
        PAL.display.setTitle(mNativeHandle, value);
    }

    bool isMouseCursorCaptured() const nothrow
    {
        return PAL.display.isMouseCursorCaptured(mNativeHandle);
    }

    void isMouseCursorCaptured(bool value)
    {
        PAL.display.setMouseCursorCaptured(mNativeHandle, value);
    }

    const(Image) icon() const nothrow
    {
        return PAL.display.getIcon(mNativeHandle);
    }

    void icon(in Image value)
    {
        PAL.display.setIcon(mNativeHandle, value);
    }

    string clipboardString()
    {
        return PAL.display.getClipboardString(mNativeHandle);
    }

    void clipboardString(string value)
    {
        PAL.display.setClipboardString(mNativeHandle, value);
    }

    void cursor(in Cursor value)
    {
        PAL.display.setCursor(mNativeHandle, value);
    }

    const(Cursor) cursor() const
    {
        return PAL.display.getCursor(mNativeHandle);
    }
}