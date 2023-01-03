// This file is part of the ZyeWare Game Engine, and subject to the terms
// and conditions defined in the file 'LICENSE.txt', which is part
// of this source code package.
//
// Copyright 2021 ZyeByte
module zyeware.rendering.window;

import zyeware.common;
import zyeware.rendering;

class Window
{
    this(in WindowProperties properties = WindowProperties.init);

    void update();
    void swapBuffers();

    bool isKeyPressed(KeyCode code) nothrow;
    bool isMouseButtonPressed(MouseCode code) nothrow;
    bool isGamepadButtonPressed(size_t gamepadIdx, GamepadButton button) nothrow;
    float getGamepadAxisValue(size_t gamepadIdx, GamepadAxis axis) nothrow;

    Vector2f cursorPosition() const nothrow;

    void vSync(bool value) nothrow;
    bool vSync() const nothrow;

    inout(void*) nativeWindow() inout nothrow;

    Vector2i position() const nothrow;
    void position(Vector2i value) nothrow;

    Vector2i size() const nothrow;
    void size(Vector2i value) nothrow;

    bool isCursorCaptured() const nothrow;
    void isCursorCaptured(bool value) nothrow;

    bool isMaximized() nothrow;
    void isMaximized(bool value) nothrow;

    bool isMinimized() nothrow;
    void isMinimized(bool value) nothrow;

    const(Image) icon() const nothrow;
    void icon(const Image value);

    string clipboard() nothrow;
    void clipboard(string value) nothrow;
}