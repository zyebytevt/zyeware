// This file is part of the ZyeWare Game Engine, and subject to the terms
// and conditions defined in the file 'LICENSE.txt', which is part
// of this source code package.
//
// Copyright 2021 ZyeByte
module zyeware.platform.opengl.window;

version (ZWBackendOpenGL):
package(zyeware.platform.opengl):

import core.stdc.string : memcpy;

import std.string : fromStringz, toStringz, format;
import std.exception : enforce;
import std.typecons : scoped, Rebindable;
import std.math : isClose;
import std.utf : decode;

import bindbc.sdl;
import bindbc.opengl;

import zyeware.common;
import zyeware.rendering;
import zyeware.platform.opengl.utils;

class OGLWindow : Window
{
private:
    static size_t sWindowCount = 0;

protected:
    string mTitle;
    Vector2i mSize;
    Vector2i mPosition;
    Rebindable!(const Image) mIcon;
    Rebindable!(const Cursor) mCursor;
    SDL_Surface* mIconSurface;
    bool mVSync;
    bool mIsCursorCaptured;
    bool mFullscreen;

    SDL_Cursor*[const Cursor] mSDLCursors;

    SDL_Window* mHandle;
    SDL_GLContext mGLContext;
    ubyte[] mKeyboardState;
    SDL_GameController*[32] mGamepads;

    extern(C) static void sdlLogFunctionCallback(void* userdata, int category, SDL_LogPriority priority, const char* message) nothrow
    {
        LogLevel level;
        switch (priority)
        {
        case SDL_LOG_PRIORITY_VERBOSE: level = LogLevel.verbose; break;
        case SDL_LOG_PRIORITY_DEBUG: level = LogLevel.debug_; break;
        case SDL_LOG_PRIORITY_INFO: level = LogLevel.info; break;
        case SDL_LOG_PRIORITY_WARN: level = LogLevel.warning; break;
        case SDL_LOG_PRIORITY_ERROR: level = LogLevel.error; break;
        case SDL_LOG_PRIORITY_CRITICAL: level = LogLevel.fatal; break;
        default:
        }

        Logger.core.log(level, message.fromStringz);
    }

    final void addGamepad(size_t joyIdx) nothrow
    {
        SDL_GameController* pad = SDL_GameControllerOpen(cast(int) joyIdx);
        if (SDL_GameControllerGetAttached(pad) == 1)
        {
            const char* name = SDL_GameControllerName(pad);

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
                Logger.core.log(LogLevel.warning, "Failed to add controller: Too many controllers attached.");
            }
            else
            {
                Logger.core.log(LogLevel.debug_, "Added controller '%s' as gamepad #%d.",
                    name ? name.fromStringz : "<No name>", gamepadIndex);

                ZyeWare.emit!InputEventGamepadAdded(gamepadIndex);
            }
        }
        else
            Logger.core.log(LogLevel.warning, "Failed to add controller: %s.", SDL_GetError().fromStringz);
    }

    final void removeGamepad(size_t instanceId) nothrow
    {
        SDL_GameController* pad = SDL_GameControllerFromInstanceID(cast(int) instanceId);
        if (!pad)
            return;

        const char* name = SDL_GameControllerName(pad);

        SDL_GameControllerClose(pad);

        size_t gamepadIndex;
        for (; gamepadIndex < mGamepads.length; ++gamepadIndex)
            if (mGamepads[gamepadIndex] == pad)
            {
                mGamepads[gamepadIndex] = null;
                break;
            }

        Logger.core.log(LogLevel.debug_, "Removed controller '%s' (was #%d).", name ? name.fromStringz : "<No name>",
            gamepadIndex);

        ZyeWare.emit!InputEventGamepadRemoved(gamepadIndex);
    }

    final ptrdiff_t getGamepadIndex(SDL_GameController* pad) nothrow
    {
        for (size_t i; i < mGamepads.length; ++i)
            if (mGamepads[i] == pad)
                return i;

        return -1;
    }

    final ptrdiff_t getGamepadIndex(int instanceId) nothrow
    {
        return getGamepadIndex(SDL_GameControllerFromInstanceID(instanceId));
    }

package(zyeware.platform.opengl):
    this(in WindowProperties properties)
    {
        mTitle = properties.title;
        
        Logger.core.log(LogLevel.info, "Creating SDL window '%s', requested size %s...", mTitle, properties.size);

        if (sWindowCount == 0)
        {
            enforce!GraphicsException(loadSDL() == sdlSupport, "Failed to load SDL!");
            enforce!GraphicsException(SDL_Init(SDL_INIT_EVERYTHING) == 0,
                format!"Failed to initialize SDL: %s!"(SDL_GetError().fromStringz));

            SDL_LogSetOutputFunction(&sdlLogFunctionCallback, null);

            SDL_GL_SetAttribute(SDL_GL_CONTEXT_MAJOR_VERSION, 4);
            SDL_GL_SetAttribute(SDL_GL_CONTEXT_MINOR_VERSION, 1);
            SDL_GL_SetAttribute(SDL_GL_CONTEXT_PROFILE_MASK, SDL_GL_CONTEXT_PROFILE_CORE);

            Logger.core.log(LogLevel.debug_, "SDL initialized.");
        }

        mHandle = SDL_CreateWindow(mTitle.toStringz, SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED,
            cast(int) properties.size.x, cast(int) properties.size.y, SDL_WINDOW_OPENGL | SDL_WINDOW_RESIZABLE);
        enforce!GraphicsException(mHandle, format!"Failed to create SDL Window: %s!"(SDL_GetError().fromStringz));

        if (properties.icon)
            icon = properties.icon;

        // TODO: Possibly split context up into separate file.
        mGLContext = SDL_GL_CreateContext(mHandle);
        enforce!GraphicsException(mGLContext, format!"Failed to create GL context: %s!"(SDL_GetError().fromStringz));

        mVSync = SDL_GL_GetSwapInterval() != 0;

        {
            int length;
            ubyte* state = SDL_GetKeyboardState(&length);
            mKeyboardState = state[0 .. length];
        }
        
        if (sWindowCount == 0)
        {
            RenderAPI.loadLibraries();

            Logger.core.log(LogLevel.info, "Initialized OpenGL Context:");
            Logger.core.log(LogLevel.info, "    Vendor: %s", glGetString(GL_VENDOR).fromStringz);
            Logger.core.log(LogLevel.info, "    Renderer: %s", glGetString(GL_RENDERER).fromStringz);
            Logger.core.log(LogLevel.info, "    Version: %s", glGetString(GL_VERSION).fromStringz);
        }

        {
            int x, y, width, height;
            SDL_GetWindowSize(mHandle, &width, &height);
            SDL_GetWindowPosition(mHandle, &x, &y);

            mSize = Vector2i(width, height);
            mPosition = Vector2i(x, y);
        }

        ++sWindowCount;
    }

public:
    ~this()
    {
        SDL_DestroyWindow(mHandle);
        SDL_GL_DeleteContext(mGLContext);

        if (mIconSurface)
            SDL_FreeSurface(mIconSurface);

        foreach (SDL_Cursor* cursor; mSDLCursors.values)
            SDL_FreeCursor(cursor);

        if (--sWindowCount == 0)
            SDL_Quit();
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
                    mSize = Vector2i(ev.window.data1, ev.window.data2);
                    ZyeWare.emit!WindowResizedEvent(this, mSize);
                    break;

                case SDL_WINDOWEVENT_MOVED:
                    mPosition = Vector2i(ev.window.data1, ev.window.data2);
                    ZyeWare.emit!WindowMovedEvent(this, mPosition);
                    break;

                default:
                }
                break;

            case SDL_QUIT:
                ZyeWare.emit!QuitEvent();
                break;

            case SDL_KEYUP:
            case SDL_KEYDOWN:
                if (!ev.key.repeat)
                    ZyeWare.emit!InputEventKey(this,
                        cast(KeyCode) ev.key.keysym.scancode, ev.key.state == SDL_PRESSED);
                break;

            case SDL_TEXTINPUT:
                size_t idx = 0;
                immutable dchar codepoint = decode(cast(string) ev.text.text.fromStringz, idx);
                ZyeWare.emit!InputEventText(this, codepoint);
                break;

            case SDL_MOUSEBUTTONUP:
            case SDL_MOUSEBUTTONDOWN:
                ZyeWare.emit!InputEventMouseButton(this,
                    cast(MouseCode) ev.button.button, ev.button.state == SDL_PRESSED, cast(size_t) ev.button.clicks);
                break;

            case SDL_MOUSEWHEEL:
                auto amount = Vector2f(ev.wheel.x, ev.wheel.y);
                if (ev.wheel.direction == SDL_MOUSEWHEEL_FLIPPED)
                    amount *= -1;
                
                ZyeWare.emit!InputEventMouseScroll(this, amount);
                break;

            case SDL_MOUSEMOTION:
                ZyeWare.emit!InputEventMouseMotion(this, Vector2f(ev.motion.x, ev.motion.y),
                    Vector2f(ev.motion.xrel, ev.motion.yrel));
                break;

            case SDL_CONTROLLERBUTTONUP:
            case SDL_CONTROLLERBUTTONDOWN:
                GamepadButton button;

                switch (ev.cbutton.button)
                {
                case SDL_CONTROLLER_BUTTON_A: button = GamepadButton.a; break;
                case SDL_CONTROLLER_BUTTON_B: button = GamepadButton.b; break;
                case SDL_CONTROLLER_BUTTON_X: button = GamepadButton.x; break;
                case SDL_CONTROLLER_BUTTON_Y: button = GamepadButton.y; break;
                case SDL_CONTROLLER_BUTTON_LEFTSHOULDER: button = GamepadButton.leftShoulder; break;
                case SDL_CONTROLLER_BUTTON_RIGHTSHOULDER: button = GamepadButton.rightShoulder; break;
                case SDL_CONTROLLER_BUTTON_BACK: button = GamepadButton.select; break;
                case SDL_CONTROLLER_BUTTON_START: button = GamepadButton.start; break;
                case SDL_CONTROLLER_BUTTON_GUIDE: button = GamepadButton.home; break;
                case SDL_CONTROLLER_BUTTON_LEFTSTICK: button = GamepadButton.leftStick; break;
                case SDL_CONTROLLER_BUTTON_RIGHTSTICK: button = GamepadButton.rightStick; break;
                case SDL_CONTROLLER_BUTTON_DPAD_UP: button = GamepadButton.dpadUp; break;
                case SDL_CONTROLLER_BUTTON_DPAD_RIGHT: button = GamepadButton.dpadRight; break;
                case SDL_CONTROLLER_BUTTON_DPAD_DOWN: button = GamepadButton.dpadDown; break;
                case SDL_CONTROLLER_BUTTON_DPAD_LEFT: button = GamepadButton.dpadLeft; break;
                default:
                    break typeSwitch;
                }

                ZyeWare.emit!InputEventGamepadButton(getGamepadIndex(ev.cbutton.which), button,
                    ev.cbutton.state == SDL_PRESSED);
                break;

            case SDL_CONTROLLERAXISMOTION:
                GamepadAxis axis;

                switch (ev.caxis.axis)
                {
                case SDL_CONTROLLER_AXIS_LEFTX: axis = GamepadAxis.leftX; break;
                case SDL_CONTROLLER_AXIS_LEFTY: axis = GamepadAxis.leftY; break;
                case SDL_CONTROLLER_AXIS_RIGHTX: axis = GamepadAxis.rightX; break;
                case SDL_CONTROLLER_AXIS_RIGHTY: axis = GamepadAxis.rightY; break;
                case SDL_CONTROLLER_AXIS_TRIGGERLEFT: axis = GamepadAxis.leftTrigger; break;
                case SDL_CONTROLLER_AXIS_TRIGGERRIGHT: axis = GamepadAxis.rightTrigger; break;
                default:
                    break typeSwitch;
                }

                ZyeWare.emit!InputEventGamepadAxisMotion(getGamepadIndex(ev.caxis.which), axis,
                    ev.caxis.value / 32_768f);
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
        case a: sdlButton = SDL_CONTROLLER_BUTTON_A; break;
        case b: sdlButton = SDL_CONTROLLER_BUTTON_B; break;
        case x: sdlButton = SDL_CONTROLLER_BUTTON_X; break;
        case y: sdlButton = SDL_CONTROLLER_BUTTON_Y; break;
        case leftShoulder: sdlButton = SDL_CONTROLLER_BUTTON_LEFTSHOULDER; break;
        case rightShoulder: sdlButton = SDL_CONTROLLER_BUTTON_RIGHTSHOULDER; break;
        case select: sdlButton = SDL_CONTROLLER_BUTTON_BACK; break;
        case start: sdlButton = SDL_CONTROLLER_BUTTON_START; break;
        case home: sdlButton = SDL_CONTROLLER_BUTTON_GUIDE; break;
        case leftStick: sdlButton = SDL_CONTROLLER_BUTTON_LEFTSTICK; break;
        case rightStick: sdlButton = SDL_CONTROLLER_BUTTON_RIGHTSTICK; break;
        case dpadUp: sdlButton = SDL_CONTROLLER_BUTTON_DPAD_UP; break;
        case dpadRight: sdlButton = SDL_CONTROLLER_BUTTON_DPAD_RIGHT; break;
        case dpadDown: sdlButton = SDL_CONTROLLER_BUTTON_DPAD_DOWN; break;
        case dpadLeft: sdlButton = SDL_CONTROLLER_BUTTON_DPAD_LEFT; break;
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
        case leftX: sdlAxis = SDL_CONTROLLER_AXIS_LEFTX; break;
        case leftY: sdlAxis = SDL_CONTROLLER_AXIS_LEFTY; break;
        case rightX: sdlAxis = SDL_CONTROLLER_AXIS_RIGHTX; break;
        case rightY: sdlAxis = SDL_CONTROLLER_AXIS_RIGHTY; break;
        case leftTrigger: sdlAxis = SDL_CONTROLLER_AXIS_TRIGGERLEFT; break;
        case rightTrigger: sdlAxis = SDL_CONTROLLER_AXIS_TRIGGERRIGHT; break;
        }

        return SDL_GameControllerGetAxis(pad, sdlAxis) / 32_768f;
    }

    Vector2f cursorPosition() const nothrow
    {
        int x, y;
        SDL_GetMouseState(&x, &y);
        return Vector2f(x, y);
    }

    void vSync(bool value) nothrow
    {
        if (value)
        {
            if (SDL_GL_SetSwapInterval(-1) == -1 && SDL_GL_SetSwapInterval(1) == -1)
            {
                Logger.core.log(LogLevel.warning, "Failed to enable VSync: %s.", SDL_GetError().fromStringz);
                return;
            }

            mVSync = true;
        }
        else
        {
            if (SDL_GL_SetSwapInterval(0) == -1)
            {
                Logger.core.log(LogLevel.warning, "Failed to disable VSync: %s.", SDL_GetError().fromStringz);
                return;
            }

            mVSync = false;
        }
    }

    bool vSync() const nothrow
    {
        return mVSync;
    }

    inout(void*) nativeWindow() inout nothrow
    {
        return cast(inout(void*)) mHandle;
    }

    Vector2i position() const nothrow
    {
        return mPosition;
    }

    void position(Vector2i value) nothrow
    {
        SDL_SetWindowPosition(mHandle, value.x, value.y);
    }

    Vector2i size() const nothrow
    {
        return mSize;
    }

    void size(Vector2i value) nothrow
        in (value.x > 0 && value.y > 0, "Window size cannot be negative.")
    {
        SDL_SetWindowSize(mHandle, value.x, value.y);
    }

    bool isCursorCaptured() const nothrow
    {
        return mIsCursorCaptured;
    }

    void isCursorCaptured(bool value) nothrow
    {
        if (value)
        {
            if (SDL_SetRelativeMouseMode(SDL_TRUE) == 0)
            {
                SDL_ShowCursor(SDL_DISABLE);
                mIsCursorCaptured = true;
                return;
            }

            Logger.core.log(LogLevel.warning, "Failed to capture mouse: %s.", SDL_GetError().fromStringz);
        }
        else
        {
            if (SDL_SetRelativeMouseMode(SDL_FALSE) == 0)
            {
                SDL_ShowCursor(SDL_ENABLE);
                mIsCursorCaptured = false;
                return;
            }

            Logger.core.log(LogLevel.warning, "Failed to release mouse: %s.", SDL_GetError().fromStringz);
        }
    }

    bool isMaximized() nothrow
    {
        return (SDL_GetWindowFlags(mHandle) & SDL_WINDOW_MAXIMIZED) != 0;
    }

    void isMaximized(bool value) nothrow
    {
        if (value)
            SDL_MaximizeWindow(mHandle);
        else if (isMaximized)
            SDL_RestoreWindow(mHandle);
    }

    bool isMinimized() nothrow
    {
        return (SDL_GetWindowFlags(mHandle) & SDL_WINDOW_MINIMIZED) != 0;
    }

    void isMinimized(bool value) nothrow
    {
        if (value)
            SDL_MinimizeWindow(mHandle);
        else if (isMinimized)
            SDL_RestoreWindow(mHandle);
    }

    bool isFullscreen() nothrow
    {
        return mFullscreen;
    }

    void isFullscreen(bool value) nothrow
    {
        SDL_SetWindowFullscreen(mHandle, value ? SDL_WINDOW_FULLSCREEN_DESKTOP : 0);
        mFullscreen = value;
    }

    const(Image) icon() const nothrow
    {
        return mIcon;
    }

    void icon(const Image value)
    {
        if (mIconSurface)
            SDL_FreeSurface(mIconSurface);

        mIconSurface = createSurfaceFromImage(value);
        mIcon = value;

        SDL_SetWindowIcon(mHandle, mIconSurface);
    }

    string clipboard() nothrow
    {
        return SDL_GetClipboardText().fromStringz.idup;
    }

    void clipboard(string value) nothrow
    {
        SDL_SetClipboardText(value.toStringz);
    }

    void cursor(Cursor value) nothrow
    {
        mCursor = value;

        SDL_Cursor** sdlCursor = value in mSDLCursors;
        if (!sdlCursor)
        {
            SDL_Surface* surface = createSurfaceFromImage(value.image);
            SDL_Cursor* cursor = SDL_CreateColorCursor(surface, value.hotspot.x, value.hotspot.y);
            SDL_FreeSurface(surface);

            mSDLCursors[value] = cursor;
            sdlCursor = value in mSDLCursors;
        }

        SDL_SetCursor(*sdlCursor);
    }
    
    const(Cursor) cursor() const nothrow
    {
        return mCursor;
    }
}
