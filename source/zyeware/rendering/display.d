// This file is part of the ZyeWare Game Engine, and subject to the terms
// and conditions defined in the file 'LICENSE.txt', which is part
// of this source code package.
//
// Copyright 2021 ZyeByte
module zyeware.rendering.display;

import zyeware.common;
import zyeware.rendering;
import zyeware.pal;

struct DisplayProperties
{
    string title = "ZyeWare Engine";
    Vector2i size = Vector2i(1280, 720);
    Image icon;
}

class Display : NativeObject
{
protected:
    NativeHandle mNativeHandle;
    DisplayProperties mProperties;

public:
    this(in DisplayProperties properties)
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

    Vector2f cursorPosition() const nothrow
    {
        return PAL.display.getCursorPosition(mNativeHandle);
    }

    void isVSyncEnabled(bool value) nothrow
    {
        PAL.display.setVSync(mNativeHandle, value);
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

    void position(Vector2i value) nothrow
    {
        PAL.display.setPosition(mNativeHandle, value);
    }

    Vector2i size() const nothrow
    {
        return PAL.display.getSize(mNativeHandle);
    }

    void size(Vector2i value) nothrow
    {
        PAL.display.setSize(mNativeHandle, value);
    }

    bool isCursorCaptured() const nothrow
    {
        return PAL.display.isCursorCaptured(mNativeHandle);
    }

    void isCursorCaptured(bool value) nothrow
    {
        PAL.display.setCursorCapture(mNativeHandle, value);
    }

    bool isMaximized() nothrow
    {
        return PAL.display.isMaximized(mNativeHandle);
    }

    void isMaximized(bool value) nothrow
    {
        PAL.display.setMaximized(mNativeHandle, value);
    }

    bool isMinimized() nothrow
    {
        return PAL.display.isMinimized(mNativeHandle);
    }

    void isMinimized(bool value) nothrow
    {
        PAL.display.setMinimized(mNativeHandle, value);
    }

    bool isFullscreen() nothrow
    {
        return PAL.display.isFullscreen(mNativeHandle);
    }

    void isFullscreen(bool value) nothrow
    {
        PAL.display.setFullscreen(mNativeHandle, value);
    }

    const(Image) icon() const nothrow
    {
        return PAL.display.getIcon(mNativeHandle);
    }

    void icon(in Image value)
    {
        PAL.display.setIcon(mNativeHandle, value);
    }

    string clipboardString() nothrow
    {
        return PAL.display.getClipboardString(mNativeHandle);
    }

    void clipboardString(string value) nothrow
    {
        PAL.display.setClipboardString(mNativeHandle, value);
    }

    void cursor(in Cursor value) nothrow
    {
        PAL.display.setCursor(mNativeHandle, value);
    }

    const(Cursor) cursor() const nothrow
    {
        return PAL.display.getCursor(mNativeHandle);
    }
}