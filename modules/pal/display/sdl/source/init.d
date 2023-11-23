// This file is part of the ZyeWare Game Engine, and subject to the terms
// and conditions defined in the file 'LICENSE.txt', which is part
// of this source code package.
//
// Copyright 2021 ZyeByte
module zyeware.pal.display.sdl.init;

import zyeware.pal.display.driver;

import zyeware.pal.display.sdl.api;
import zyeware.pal;

public:

shared static this()
{
    Pal.registerDisplayDriver("sdl", () => DisplayDriver(
        &createDisplay,
        &destroyDisplay,
        &update,
        &swapBuffers,
        &isKeyPressed,
        &isMouseButtonPressed,
        &isGamepadButtonPressed,
        &getGamepadAxisValue,
        &getCursorPosition,
        &setVSyncEnabled,
        &isVSyncEnabled,
        &setPosition,
        &getPosition,
        &setSize,
        &getSize,
        &setFullscreen,
        &isFullscreen,
        &setResizable,
        &isResizable,
        &setDecorated,
        &isDecorated,
        &setFocused,
        &isFocused,
        &setVisible,
        &isVisible,
        &setMinimized,
        &isMinimized,
        &setMaximized,
        &isMaximized,
        &setIcon,
        &getIcon,
        &setCursor,
        &getCursor,
        &setTitle,
        &getTitle,
        &setMouseCursorVisible,
        &isMouseCursorVisible,
        &setMouseCursorCaptured,
        &isMouseCursorCaptured,
        &setClipboardString,
        &getClipboardString
    ));
}