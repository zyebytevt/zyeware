// This file is part of the ZyeWare Game Engine, and subject to the terms
// and conditions defined in the file 'LICENSE.txt', which is part
// of this source code package.
//
// Copyright 2021 ZyeByte
module zyeware.pal.display.sdl.init; version(ZW_PAL_SDL):

import zyeware.pal.generic.drivers;
import zyeware.pal.display.sdl.api;

package(zyeware.pal):

void load(ref DisplayDriver driver) nothrow
{
    driver.createDisplay = &createDisplay;
    driver.destroyDisplay = &destroyDisplay;
    driver.update = &update;
    driver.swapBuffers = &swapBuffers;
    driver.isKeyPressed = &isKeyPressed;
    driver.isMouseButtonPressed = &isMouseButtonPressed;
    driver.isGamepadButtonPressed = &isGamepadButtonPressed;
    driver.getGamepadAxisValue = &getGamepadAxisValue;
    driver.getCursorPosition = &getCursorPosition;
    driver.setVSyncEnabled = &setVSyncEnabled;
    driver.isVSyncEnabled = &isVSyncEnabled;
    driver.setPosition = &setPosition;
    driver.getPosition = &getPosition;
    driver.setSize = &setSize;
    driver.getSize = &getSize;
    driver.setFullscreen = &setFullscreen;
    driver.isFullscreen = &isFullscreen;
    driver.setResizable = &setResizable;
    driver.isResizable = &isResizable;
    driver.setDecorated = &setDecorated;
    driver.isDecorated = &isDecorated;
    driver.setFocused = &setFocused;
    driver.isFocused = &isFocused;
    driver.setVisible = &setVisible;
    driver.isVisible = &isVisible;
    driver.setMinimized = &setMinimized;
    driver.isMinimized = &isMinimized;
    driver.setMaximized = &setMaximized;
    driver.isMaximized = &isMaximized;
    driver.setIcon = &setIcon;
    driver.getIcon = &getIcon;
    driver.setCursor = &setCursor;
    driver.getCursor = &getCursor;
    driver.setTitle = &setTitle;
    driver.getTitle = &getTitle;
    driver.setMouseCursorVisible = &setMouseCursorVisible;
    driver.isMouseCursorVisible = &isMouseCursorVisible;
    driver.setMouseCursorCaptured = &setMouseCursorCaptured;
    driver.isMouseCursorCaptured = &isMouseCursorCaptured;
    driver.setClipboardString = &setClipboardString;
    driver.getClipboardString = &getClipboardString;
}