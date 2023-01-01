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

    Vector2ui position() const nothrow;
    void position(Vector2ui value) nothrow;

    Vector2i size() const nothrow;
    void size(Vector2i value) nothrow;

    bool isCursorCaptured() const nothrow;
    void isCursorCaptured(bool value) nothrow;
}