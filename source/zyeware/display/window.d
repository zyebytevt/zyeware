// This file is part of the ZyeWare Game Engine, and subject to the terms
// and conditions defined in the file 'LICENSE.txt', which is part
// of this source code package.
//
// Copyright © 2021-2024 ZyeByte. All rights reserved.
module zyeware.display.window;

import std.exception : collectException;
import std.typecons : Rebindable;
import std.string : fromStringz, toStringz;

import bindbc.sdl;

import zyeware;

struct WindowProperties
{
    string title = "ZyeWare Engine";
    Flag!"resizable" resizable = Yes.resizable;
    vec2i size = vec2i(1280, 720);
    Image icon;
}

class Window
{
protected:
    const WindowProperties mProperties;

    string mTitle;
    vec2i mSize;
    vec2i mPosition;
    bool mIsFullscreen;
    bool mIsVSyncEnabled;
    bool mIsCursorCaptured;

    Rebindable!(const Image) mIcon;
    Rebindable!(const Cursor) mCursor;

    SDL_Window* mHandle;
    SDL_GLContext mGlContext;
    ubyte[] mKeyboardState;
    SDL_GameController*[32] mGamepads;

    ptrdiff_t getGamepadIndex(SDL_GameController* pad) nothrow
    {
        for (size_t i; i < mGamepads.length; ++i)
            if (mGamepads[i] == pad)
                return i;

        return -1;
    }

    pragma(inline, true)
    ptrdiff_t getGamepadIndex(int instanceId) nothrow
    {
        return getGamepadIndex(SDL_GameControllerFromInstanceID(instanceId));
    }

    void addGamepad(size_t joyIdx) nothrow
    {
        SDL_GameController* pad = SDL_GameControllerOpen(cast(int) joyIdx);
        if (SDL_GameControllerGetAttached(pad) == 1)
        {
            stringz name = SDL_GameControllerName(pad);

            size_t gamepadIndex;
            for (; gamepadIndex < mGamepads.length; ++gamepadIndex)
                if (!mGamepads[gamepadIndex])
                {
                    mGamepads[gamepadIndex] = pad;
                    break;
                }

            if (gamepadIndex == mGamepads.length) // Too many controllers
            {
                SDL_GameControllerClose(pad);
                Logger.core.warning("Failed to add controller: Too many controllers attached.");
            }
            else
            {
                Logger.core.debug_("Added controller '%s' as gamepad #%d.", name
                        ? name.fromStringz : "<No name>", gamepadIndex);

                ZyeWare.events.gamepadConnected(gamepadIndex).collectException;
            }
        }
        else
            Logger.core.warning("Failed to add controller: %s.", SDL_GetError().fromStringz);
    }

    void removeGamepad(size_t instanceId) nothrow
    {
        SDL_GameController* pad = SDL_GameControllerFromInstanceID(cast(int) instanceId);
        if (!pad)
            return;

        stringz name = SDL_GameControllerName(pad);

        SDL_GameControllerClose(pad);

        size_t gamepadIndex;
        for (; gamepadIndex < mGamepads.length; ++gamepadIndex)
            if (mGamepads[gamepadIndex] == pad)
            {
                mGamepads[gamepadIndex] = null;
                break;
            }

        Logger.core.debug_("Removed controller '%s' (was #%d).", name
                ? name.fromStringz : "<No name>", gamepadIndex);

        ZyeWare.events.gamepadDisconnected(gamepadIndex).collectException;
    }

public:
    this(in WindowProperties properties)
    {
        mProperties = properties;

        Logger.core.info("Creating SDL window '%s', requested size %s...",
            properties.title, properties.size);

        uint windowFlags = SDL_WINDOW_OPENGL;
        if (properties.resizable)
            windowFlags |= SDL_WINDOW_RESIZABLE;

        mHandle = SDL_CreateWindow(properties.title.toStringz, SDL_WINDOWPOS_UNDEFINED,
            SDL_WINDOWPOS_UNDEFINED, cast(int) properties.size.x,
            cast(int) properties.size.y, windowFlags);
        enforce!GraphicsException(mHandle,
            format!"Failed to create SDL Window: %s!"(SDL_GetError().fromStringz));

        if (properties.icon)
            icon = properties.icon;

        mGlContext = SDL_GL_CreateContext(mHandle);
        enforce!GraphicsException(mGlContext,
            format!"Failed to create GL context: %s!"(SDL_GetError().fromStringz));

        Logger.core.debug_("OpenGL context created.");

        mIsVSyncEnabled = SDL_GL_GetSwapInterval() != 0;

        {
            int length;
            ubyte* state = SDL_GetKeyboardState(&length);
            mKeyboardState = state[0 .. length];

            int x, y, width, height;
            SDL_GetWindowSize(mHandle, &width, &height);
            SDL_GetWindowPosition(mHandle, &x, &y);

            mSize = vec2i(width, height);
            mPosition = vec2i(x, y);
        }
    }

    ~this()
    {
        SDL_DestroyWindow(mHandle);
        SDL_GL_DeleteContext(mGlContext);
    }

    void update()
    {
        SDL_Event ev;
        while (SDL_PollEvent(&ev))
        {
        typeSwitch:
            switch (ev.type)
            {
            case SDL_WINDOWEVENT:
                switch (ev.window.event)
                {
                case SDL_WINDOWEVENT_SIZE_CHANGED:
                    mSize = vec2i(ev.window.data1, ev.window.data2);
                    ZyeWare.events.windowResized(this, mSize);
                    break;

                case SDL_WINDOWEVENT_MOVED:
                    mPosition = vec2i(ev.window.data1, ev.window.data2);
                    ZyeWare.events.windowMoved(this, mPosition);
                    break;

                default:
                }
                break;

            case SDL_QUIT:
                ZyeWare.events.quitRequested();
                break;

            case SDL_KEYUP:
                ZyeWare.events.keyboardKeyReleased(cast(KeyCode) ev.key.keysym.scancode);
                break;

            case SDL_KEYDOWN:
                if (!ev.key.repeat)
                    ZyeWare.events.keyboardKeyPressed(cast(KeyCode) ev.key.keysym.scancode);
                break;

            case SDL_TEXTINPUT:
                //size_t idx = 0;
                //immutable dchar codepoint = decode(cast(string) ev.text.text.fromStringz, idx);
                //ZyeWare.emit!InputEventText(data.container, codepoint);
                break;

            case SDL_MOUSEBUTTONUP:
                ZyeWare.events.mouseButtonReleased(cast(MouseCode) ev.button.button);
                break;

            case SDL_MOUSEBUTTONDOWN:
                ZyeWare.events.mouseButtonPressed(cast(MouseCode) ev.button.button,
                    cast(size_t) ev.button.clicks);
                break;

            case SDL_MOUSEWHEEL:
                auto amount = vec2(ev.wheel.x, ev.wheel.y);
                if (ev.wheel.direction == SDL_MOUSEWHEEL_FLIPPED)
                    amount *= -1;

                ZyeWare.events.mouseWheelScrolled(amount);
                break;

            case SDL_MOUSEMOTION:
                ZyeWare.events.mouseMoved(vec2(ev.motion.x, ev.motion.y),
                    vec2(ev.motion.xrel, ev.motion.yrel));
                break;

            case SDL_CONTROLLERBUTTONUP:
            case SDL_CONTROLLERBUTTONDOWN:
                GamepadButton button;

                switch (ev.cbutton.button)
                {
                case SDL_CONTROLLER_BUTTON_A:
                    button = GamepadButton.a;
                    break;
                case SDL_CONTROLLER_BUTTON_B:
                    button = GamepadButton.b;
                    break;
                case SDL_CONTROLLER_BUTTON_X:
                    button = GamepadButton.x;
                    break;
                case SDL_CONTROLLER_BUTTON_Y:
                    button = GamepadButton.y;
                    break;
                case SDL_CONTROLLER_BUTTON_LEFTSHOULDER:
                    button = GamepadButton.leftShoulder;
                    break;
                case SDL_CONTROLLER_BUTTON_RIGHTSHOULDER:
                    button = GamepadButton.rightShoulder;
                    break;
                case SDL_CONTROLLER_BUTTON_BACK:
                    button = GamepadButton.select;
                    break;
                case SDL_CONTROLLER_BUTTON_START:
                    button = GamepadButton.start;
                    break;
                case SDL_CONTROLLER_BUTTON_GUIDE:
                    button = GamepadButton.home;
                    break;
                case SDL_CONTROLLER_BUTTON_LEFTSTICK:
                    button = GamepadButton.leftStick;
                    break;
                case SDL_CONTROLLER_BUTTON_RIGHTSTICK:
                    button = GamepadButton.rightStick;
                    break;
                case SDL_CONTROLLER_BUTTON_DPAD_UP:
                    button = GamepadButton.dpadUp;
                    break;
                case SDL_CONTROLLER_BUTTON_DPAD_RIGHT:
                    button = GamepadButton.dpadRight;
                    break;
                case SDL_CONTROLLER_BUTTON_DPAD_DOWN:
                    button = GamepadButton.dpadDown;
                    break;
                case SDL_CONTROLLER_BUTTON_DPAD_LEFT:
                    button = GamepadButton.dpadLeft;
                    break;
                default:
                    break typeSwitch;
                }

                if (ev.cbutton.state == SDL_PRESSED)
                    ZyeWare.events.gamepadButtonPressed(getGamepadIndex(ev.cbutton.which), button);
                else
                    ZyeWare.events.gamepadButtonReleased(getGamepadIndex(ev.cbutton.which), button);
                break;

            case SDL_CONTROLLERAXISMOTION:
                GamepadAxis axis;

                switch (ev.caxis.axis)
                {
                case SDL_CONTROLLER_AXIS_LEFTX:
                    axis = GamepadAxis.leftX;
                    break;
                case SDL_CONTROLLER_AXIS_LEFTY:
                    axis = GamepadAxis.leftY;
                    break;
                case SDL_CONTROLLER_AXIS_RIGHTX:
                    axis = GamepadAxis.rightX;
                    break;
                case SDL_CONTROLLER_AXIS_RIGHTY:
                    axis = GamepadAxis.rightY;
                    break;
                case SDL_CONTROLLER_AXIS_TRIGGERLEFT:
                    axis = GamepadAxis.leftTrigger;
                    break;
                case SDL_CONTROLLER_AXIS_TRIGGERRIGHT:
                    axis = GamepadAxis.rightTrigger;
                    break;
                default:
                    break typeSwitch;
                }

                ZyeWare.events.gamepadAxisMoved(getGamepadIndex(ev.caxis.which), axis, ev.caxis.value / 32_768f);
                break;

            case SDL_CONTROLLERDEVICEADDED:
                addGamepad(ev.cdevice.which);
                break;

            case SDL_CONTROLLERDEVICEREMOVED:
                removeGamepad(ev.cdevice.which);
                break;

            default:
            }
        }
    }

    void swapBuffers()
    {
        SDL_GL_SwapWindow(mHandle);
    }

    bool isKeyPressed(KeyCode code) nothrow
    {
        if (code >= mKeyboardState.length)
            return false;

        return mKeyboardState[code] == 1;
    }

    bool isMouseButtonPressed(MouseCode code) nothrow
    {
        int dummy;

        return (SDL_GetMouseState(&dummy, &dummy) & code) != 0;
    }

    bool isGamepadButtonPressed(size_t gamepadIdx, GamepadButton button) nothrow
    {
        SDL_GameController* pad = mGamepads[gamepadIdx];
        if (!pad)
            return false;

        SDL_GameControllerButton sdlButton;
        final switch (button) with (GamepadButton)
        {
        case a:
            sdlButton = SDL_CONTROLLER_BUTTON_A;
            break;
        case b:
            sdlButton = SDL_CONTROLLER_BUTTON_B;
            break;
        case x:
            sdlButton = SDL_CONTROLLER_BUTTON_X;
            break;
        case y:
            sdlButton = SDL_CONTROLLER_BUTTON_Y;
            break;
        case leftShoulder:
            sdlButton = SDL_CONTROLLER_BUTTON_LEFTSHOULDER;
            break;
        case rightShoulder:
            sdlButton = SDL_CONTROLLER_BUTTON_RIGHTSHOULDER;
            break;
        case select:
            sdlButton = SDL_CONTROLLER_BUTTON_BACK;
            break;
        case start:
            sdlButton = SDL_CONTROLLER_BUTTON_START;
            break;
        case home:
            sdlButton = SDL_CONTROLLER_BUTTON_GUIDE;
            break;
        case leftStick:
            sdlButton = SDL_CONTROLLER_BUTTON_LEFTSTICK;
            break;
        case rightStick:
            sdlButton = SDL_CONTROLLER_BUTTON_RIGHTSTICK;
            break;
        case dpadUp:
            sdlButton = SDL_CONTROLLER_BUTTON_DPAD_UP;
            break;
        case dpadRight:
            sdlButton = SDL_CONTROLLER_BUTTON_DPAD_RIGHT;
            break;
        case dpadDown:
            sdlButton = SDL_CONTROLLER_BUTTON_DPAD_DOWN;
            break;
        case dpadLeft:
            sdlButton = SDL_CONTROLLER_BUTTON_DPAD_LEFT;
            break;
        }

        return SDL_GameControllerGetButton(pad, sdlButton) == 1;
    }

    float getGamepadAxisValue(size_t gamepadIdx, GamepadAxis axis) nothrow
    {
        SDL_GameController* pad = mGamepads[gamepadIdx];
        if (!pad)
            return 0f;

        SDL_GameControllerAxis sdlAxis;
        final switch (axis) with (GamepadAxis)
        {
        case leftX:
            sdlAxis = SDL_CONTROLLER_AXIS_LEFTX;
            break;
        case leftY:
            sdlAxis = SDL_CONTROLLER_AXIS_LEFTY;
            break;
        case rightX:
            sdlAxis = SDL_CONTROLLER_AXIS_RIGHTX;
            break;
        case rightY:
            sdlAxis = SDL_CONTROLLER_AXIS_RIGHTY;
            break;
        case leftTrigger:
            sdlAxis = SDL_CONTROLLER_AXIS_TRIGGERLEFT;
            break;
        case rightTrigger:
            sdlAxis = SDL_CONTROLLER_AXIS_TRIGGERRIGHT;
            break;
        }

        return SDL_GameControllerGetAxis(pad, sdlAxis) / 32_768f;
    }

    void focus() nothrow
    {
        SDL_RaiseWindow(mHandle);
    }

    vec2i cursorPosition() const nothrow
    {
        int x, y;
        SDL_GetMouseState(&x, &y);
        return vec2i(x, y);
    }

    bool isVSyncEnabled(bool value)
    {
        if (value)
        {
            if (SDL_GL_SetSwapInterval(-1) == -1 && SDL_GL_SetSwapInterval(1) == -1)
            {
                Logger.core.warning("Failed to enable VSync: %s.", SDL_GetError().fromStringz);
                return value;
            }

            mIsVSyncEnabled = true;
        }
        else
        {
            if (SDL_GL_SetSwapInterval(0) == -1)
            {
                Logger.core.warning("Failed to disable VSync: %s.", SDL_GetError().fromStringz);
                return value;
            }

            mIsVSyncEnabled = false;
        }

        return value;
    }

    bool isVSyncEnabled() const nothrow => mIsVSyncEnabled;

    vec2i position() const nothrow => mPosition;

    vec2i position(vec2i value)
    {
        SDL_SetWindowPosition(mHandle, value.x, value.y);
        return value;
    }

    vec2i size() const nothrow => mSize;

    vec2i size(vec2i value)
    {
        SDL_SetWindowSize(mHandle, value.x, value.y);
        return value;
    }

    bool isFullscreen() const nothrow => mIsFullscreen;

    bool isFullscreen(bool value)
    {
        SDL_SetWindowFullscreen(mHandle, value ? SDL_WINDOW_FULLSCREEN_DESKTOP : 0);
        return mIsFullscreen = value;
    }

    bool isResizable() nothrow => (SDL_GetWindowFlags(mHandle) & SDL_WINDOW_RESIZABLE) != 0;

    bool isResizable(bool value)
    {
        SDL_SetWindowResizable(mHandle, value ? SDL_TRUE : SDL_FALSE);
        return value;
    }

    bool isDecorated() nothrow => (SDL_GetWindowFlags(mHandle) & SDL_WINDOW_BORDERLESS) == 0;

    bool isDecorated(bool value)
    {
        SDL_SetWindowBordered(mHandle, value ? SDL_TRUE : SDL_FALSE);
        return value;
    }

    bool isFocused() nothrow => (SDL_GetWindowFlags(mHandle) & SDL_WINDOW_INPUT_FOCUS) != 0;

    bool isVisible() nothrow => (SDL_GetWindowFlags(mHandle) & SDL_WINDOW_SHOWN) != 0;

    bool isVisible(bool value) nothrow
    {
        if (value)
            SDL_ShowWindow(mHandle);
        else
            SDL_HideWindow(mHandle);

        return value;
    }

    bool isMinimized() nothrow => (SDL_GetWindowFlags(mHandle) & SDL_WINDOW_MINIMIZED) != 0;

    bool isMinimized(bool value)
    {
        if (value)
            SDL_MinimizeWindow(mHandle);
        else
            SDL_RestoreWindow(mHandle);
        
        return value;
    }

    bool isMaximized() nothrow => (SDL_GetWindowFlags(mHandle) & SDL_WINDOW_MAXIMIZED) != 0;

    bool isMaximized(bool value)
    {
        if (value)
            SDL_MaximizeWindow(mHandle);
        else
            SDL_RestoreWindow(mHandle);

        return value;
    }

    bool isMouseCursorVisible() const nothrow => SDL_ShowCursor(SDL_QUERY) == SDL_ENABLE;

    bool isMouseCursorVisible(bool value)
    {
        SDL_ShowCursor(value ? SDL_ENABLE : SDL_DISABLE);
        return value;
    }

    string title() const nothrow => mTitle;

    string title(string value)
    {
        SDL_SetWindowTitle(mHandle, value.toStringz);
        return value;
    }

    bool isMouseCursorCaptured() const nothrow => mIsCursorCaptured;

    bool isMouseCursorCaptured(bool value)
    {
        if (value)
        {
            if (SDL_SetRelativeMouseMode(SDL_TRUE) == 0)
            {
                mIsCursorCaptured = true;
                return value;
            }

            Logger.core.warning("Failed to capture mouse: %s.", SDL_GetError().fromStringz);
        }
        else
        {
            if (SDL_SetRelativeMouseMode(SDL_FALSE) == 0)
            {
                mIsCursorCaptured = false;
                return value;
            }

            Logger.core.warning("Failed to release mouse: %s.", SDL_GetError().fromStringz);
        }

        return value;
    }

    const(Image) icon() const nothrow => mIcon;

    void icon(in Image value) nothrow
    {
        mIcon = value;
        SDL_Surface* iconSurface = DisplayApi.createSurfaceFromImage(value);
        scope (exit) SDL_FreeSurface(iconSurface);

        SDL_SetWindowIcon(mHandle, iconSurface);
    }

    string clipboardString() nothrow => SDL_GetClipboardText().fromStringz.idup;

    string clipboardString(string value) nothrow
    {
        SDL_SetClipboardText(value.toStringz);
        return value;
    }

    const(Cursor) cursor(in Cursor value) nothrow
    {
        mCursor = value;
        SDL_SetCursor(DisplayApi.convertCursor(value));
        return value;
    }

    const(Cursor) cursor() const nothrow => mCursor;
}