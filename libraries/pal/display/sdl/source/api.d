// This file is part of the ZyeWare Game Engine, and subject to the terms
// and conditions defined in the file 'LICENSE.txt', which is part
// of this source code package.
//
// Copyright 2021 ZyeByte
module zyeware.pal.display.sdl.api;

import core.stdc.string : memcpy;

import std.string : fromStringz, toStringz, format;
import std.exception : enforce;
import std.typecons : scoped, Rebindable;
import std.math : isClose;
import std.utf : decode;
import std.numeric;

import bindbc.sdl;
import bindbc.opengl;

import zyeware;

import zyeware.pal;
import zyeware.pal.display.sdl.types;
import zyeware.pal.display.sdl.utils;

package(zyeware.pal.display.sdl):

size_t pWindowCount = 0;

extern(C)
static void logFunctionCallback(void* userdata, int category, SDL_LogPriority priority, const char* message) nothrow
{
    switch (priority)
    {
    case SDL_LOG_PRIORITY_VERBOSE: verbose(message.fromStringz); break;
    case SDL_LOG_PRIORITY_DEBUG: debug_(message.fromStringz); break;
    case SDL_LOG_PRIORITY_INFO: info(message.fromStringz); break;
    case SDL_LOG_PRIORITY_WARN: warning(message.fromStringz); break;
    case SDL_LOG_PRIORITY_ERROR: error(message.fromStringz); break;
    case SDL_LOG_PRIORITY_CRITICAL: fatal(message.fromStringz); break;
    default:
    }
}

void addGamepad(WindowData* windowData, size_t joyIdx) nothrow
{
    SDL_GameController* pad = SDL_GameControllerOpen(cast(int) joyIdx);
    if (SDL_GameControllerGetAttached(pad) == 1)
    {
        const char* name = SDL_GameControllerName(pad);

        size_t gamepadIndex;
        for (; gamepadIndex < windowData.gamepads.length; ++gamepadIndex)
            if (!windowData.gamepads[gamepadIndex])
            {
                windowData.gamepads[gamepadIndex] = pad;
                break;
            }

        if (gamepadIndex == windowData.gamepads.length) // Too many controllers
        {
            SDL_GameControllerClose(pad);
            warning("Failed to add controller: Too many controllers attached.");
        }
        else
        {
            debug_("Added controller '%s' as gamepad #%d.",
                name ? name.fromStringz : "<No name>", gamepadIndex);

            ZyeWare.emit!InputEventGamepadAdded(gamepadIndex);
        }
    }
    else
        warning("Failed to add controller: %s.", SDL_GetError().fromStringz);
}

void removeGamepad(WindowData* windowData, size_t instanceId) nothrow
{
    SDL_GameController* pad = SDL_GameControllerFromInstanceID(cast(int) instanceId);
    if (!pad)
        return;

    const char* name = SDL_GameControllerName(pad);

    SDL_GameControllerClose(pad);

    size_t gamepadIndex;
    for (; gamepadIndex < windowData.gamepads.length; ++gamepadIndex)
        if (windowData.gamepads[gamepadIndex] == pad)
        {
            windowData.gamepads[gamepadIndex] = null;
            break;
        }

    debug_("Removed controller '%s' (was #%d).", name ? name.fromStringz : "<No name>",
        gamepadIndex);

    ZyeWare.emit!InputEventGamepadRemoved(gamepadIndex);
}

ptrdiff_t getGamepadIndex(in WindowData* windowData, SDL_GameController* pad) nothrow
{
    for (size_t i; i < windowData.gamepads.length; ++i)
        if (windowData.gamepads[i] == pad)
            return i;

    return -1;
}

ptrdiff_t getGamepadIndex(in WindowData* windowData, int instanceId) nothrow
{
    return getGamepadIndex(windowData, SDL_GameControllerFromInstanceID(instanceId));
}

// TODO: This is still very much dependent on OpenGL, look for a way to make it more generic
NativeHandle createDisplay(in DisplayProperties properties, in Display container)
{
    info("Creating SDL window '%s', requested size %s...", properties.title, properties.size);

    if (pWindowCount == 0)
    {
        loadLibraries();
        enforce!GraphicsException(SDL_Init(SDL_INIT_EVERYTHING) == 0,
            format!"Failed to initialize SDL: %s!"(SDL_GetError().fromStringz));

        SDL_LogSetOutputFunction(&logFunctionCallback, null);

        SDL_GL_SetAttribute(SDL_GL_CONTEXT_MAJOR_VERSION, 4);
        SDL_GL_SetAttribute(SDL_GL_CONTEXT_MINOR_VERSION, 1);
        SDL_GL_SetAttribute(SDL_GL_CONTEXT_PROFILE_MASK, SDL_GL_CONTEXT_PROFILE_CORE);

        debug_("SDL initialized.");
    }

    WindowData* data = new WindowData;
    data.container = container;
    data.title = properties.title;

    uint windowFlags = SDL_WINDOW_OPENGL;
    if (properties.resizable)
        windowFlags |= SDL_WINDOW_RESIZABLE;
    
    data.handle = SDL_CreateWindow(properties.title.toStringz, SDL_WINDOWPOS_UNDEFINED, SDL_WINDOWPOS_UNDEFINED,
        cast(int) properties.size.x, cast(int) properties.size.y, windowFlags);
    enforce!GraphicsException(data.handle, format!"Failed to create SDL Window: %s!"(SDL_GetError().fromStringz));

    if (properties.icon)
        setIcon(data, properties.icon);

    data.glContext = SDL_GL_CreateContext(data.handle);
    enforce!GraphicsException(data.glContext, format!"Failed to create GL context: %s!"(SDL_GetError().fromStringz));

    debug_("OpenGL context created.");

    data.isVSyncEnabled = SDL_GL_GetSwapInterval() != 0;

    {
        int length;
        ubyte* state = SDL_GetKeyboardState(&length);
        data.keyboardState = state[0 .. length];
    
        int x, y, width, height;
        SDL_GetWindowSize(data.handle, &width, &height);
        SDL_GetWindowPosition(data.handle, &x, &y);

        data.size = Vector2i(width, height);
        data.position = Vector2i(x, y);
    }

    ++pWindowCount;

    return data;
}

void loadLibraries()
{
    import loader = bindbc.loader.sharedlib;
    import std.string : fromStringz;

    if (isSDLLoaded())
        return;

    immutable sdlResult = loadSDL();
    if (sdlResult != sdlSupport)
    {
        foreach (info; loader.errors)
            warning("SDL loader: %s", info.message.fromStringz);

        if (sdlResult == SDLSupport.noLibrary)
            throw new GraphicsException("Could not find SDL shared library.");
        else if (sdlResult == SDLSupport.badLibrary)
            throw new GraphicsException("Provided SDL shared library is corrupted.");
        else
            warning("Got older SDL version than expected. This might lead to errors.");
    }
}

void destroyDisplay(NativeHandle handle)
{
    WindowData* data = cast(WindowData*) handle;

    SDL_DestroyWindow(data.handle);
    SDL_GL_DeleteContext(data.glContext);

    foreach (SDL_Cursor* cursor; data.sdlCursors.values)
        SDL_FreeCursor(cursor);

    if (--pWindowCount == 0)
        SDL_Quit();
}

void update(NativeHandle handle)
{
    WindowData* data = cast(WindowData*) handle;

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
                data.size = Vector2i(ev.window.data1, ev.window.data2);
                ZyeWare.emit!DisplayResizedEvent(data.container, data.size);
                break;

            case SDL_WINDOWEVENT_MOVED:
                data.position = Vector2i(ev.window.data1, ev.window.data2);
                ZyeWare.emit!DisplayMovedEvent(data.container, data.position);
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
                ZyeWare.emit!InputEventKey(data.container,
                    cast(KeyCode) ev.key.keysym.scancode, ev.key.state == SDL_PRESSED);
            break;

        case SDL_TEXTINPUT:
            size_t idx = 0;
            immutable dchar codepoint = decode(cast(string) ev.text.text.fromStringz, idx);
            ZyeWare.emit!InputEventText(data.container, codepoint);
            break;

        case SDL_MOUSEBUTTONUP:
        case SDL_MOUSEBUTTONDOWN:
            ZyeWare.emit!InputEventMouseButton(data.container,
                cast(MouseCode) ev.button.button, ev.button.state == SDL_PRESSED, cast(size_t) ev.button.clicks);
            break;

        case SDL_MOUSEWHEEL:
            auto amount = Vector2f(ev.wheel.x, ev.wheel.y);
            if (ev.wheel.direction == SDL_MOUSEWHEEL_FLIPPED)
                amount *= -1;
            
            ZyeWare.emit!InputEventMouseScroll(data.container, amount);
            break;

        case SDL_MOUSEMOTION:
            ZyeWare.emit!InputEventMouseMotion(data.container, Vector2f(ev.motion.x, ev.motion.y),
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

            ZyeWare.emit!InputEventGamepadButton(getGamepadIndex(data, ev.cbutton.which), button,
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

            ZyeWare.emit!InputEventGamepadAxisMotion(getGamepadIndex(data, ev.caxis.which), axis,
                ev.caxis.value / 32_768f);
            break;

        case SDL_CONTROLLERDEVICEADDED:
            addGamepad(data, ev.cdevice.which);
            break;

        case SDL_CONTROLLERDEVICEREMOVED:
            removeGamepad(data, ev.cdevice.which);
            break;

        default:
        }
    }
}

void swapBuffers(NativeHandle handle)
{
    WindowData* data = cast(WindowData*) handle;

    SDL_GL_SwapWindow(data.handle);
}

bool isKeyPressed(in NativeHandle handle, KeyCode code) nothrow
{
    WindowData* data = cast(WindowData*) handle;

    if (code >= data.keyboardState.length)
        return false;

    return data.keyboardState[code] == 1;
}

bool isMouseButtonPressed(in NativeHandle handle, MouseCode code) nothrow
{
    WindowData* data = cast(WindowData*) handle;

    int dummy;

    return (SDL_GetMouseState(&dummy, &dummy) & code) != 0;
}

bool isGamepadButtonPressed(in NativeHandle handle, size_t gamepadIdx, GamepadButton button) nothrow
{
    WindowData* data = cast(WindowData*) handle;

    SDL_GameController* pad = data.gamepads[gamepadIdx];
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

float getGamepadAxisValue(in NativeHandle handle, size_t gamepadIdx, GamepadAxis axis) nothrow
{
    WindowData* data = cast(WindowData*) handle;

    SDL_GameController* pad = data.gamepads[gamepadIdx];
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

Vector2i getCursorPosition(in NativeHandle handle) nothrow
{
    int x, y;
    SDL_GetMouseState(&x, &y);
    return Vector2i(x, y);
}

void setVSyncEnabled(NativeHandle handle, bool value) nothrow
{
    WindowData* data = cast(WindowData*) handle;

    if (value)
    {
        if (SDL_GL_SetSwapInterval(-1) == -1 && SDL_GL_SetSwapInterval(1) == -1)
        {
            warning("Failed to enable VSync: %s.", SDL_GetError().fromStringz);
            return;
        }

        data.isVSyncEnabled = true;
    }
    else
    {
        if (SDL_GL_SetSwapInterval(0) == -1)
        {
            warning("Failed to disable VSync: %s.", SDL_GetError().fromStringz);
            return;
        }

        data.isVSyncEnabled = false;
    }
}

bool isVSyncEnabled(in NativeHandle handle) nothrow
{
    WindowData* data = cast(WindowData*) handle;

    return data.isVSyncEnabled;
}

Vector2i getPosition(in NativeHandle handle) nothrow
{
    WindowData* data = cast(WindowData*) handle;

    return data.position;
}

void setPosition(NativeHandle handle, Vector2i value) nothrow
{
    WindowData* data = cast(WindowData*) handle;

    SDL_SetWindowPosition(data.handle, value.x, value.y);
}

Vector2i getSize(in NativeHandle handle) nothrow
{
    WindowData* data = cast(WindowData*) handle;

    return data.size;
}

void setSize(NativeHandle handle, Vector2i value) nothrow
    in (value.x > 0 && value.y > 0, "Window size cannot be negative.")
{
    WindowData* data = cast(WindowData*) handle;

    SDL_SetWindowSize(data.handle, value.x, value.y);
}

void setFullscreen(NativeHandle handle, bool value) nothrow
{
    WindowData* data = cast(WindowData*) handle;

    SDL_SetWindowFullscreen(data.handle, value ? SDL_WINDOW_FULLSCREEN_DESKTOP : 0);
    data.isFullscreen = value;
}

bool isFullscreen(in NativeHandle handle) nothrow
{
    WindowData* data = cast(WindowData*) handle;

    return data.isFullscreen;
}

void setResizable(NativeHandle handle, bool value) nothrow
{
    WindowData* data = cast(WindowData*) handle;

    SDL_SetWindowResizable(data.handle, value ? SDL_TRUE : SDL_FALSE);
}

bool isResizable(in NativeHandle handle) nothrow
{
    WindowData* data = cast(WindowData*) handle;

    return (SDL_GetWindowFlags(data.handle) & SDL_WINDOW_RESIZABLE) != 0;
}

void setDecorated(NativeHandle handle, bool value) nothrow
{
    WindowData* data = cast(WindowData*) handle;

    SDL_SetWindowBordered(data.handle, value ? SDL_TRUE : SDL_FALSE);
}

bool isDecorated(in NativeHandle handle) nothrow
{
    WindowData* data = cast(WindowData*) handle;

    return (SDL_GetWindowFlags(data.handle) & SDL_WINDOW_BORDERLESS) == 0;
}

void setFocused(NativeHandle handle, bool value) nothrow
{
    WindowData* data = cast(WindowData*) handle;

    if (value)
        SDL_RaiseWindow(data.handle);
}

bool isFocused(in NativeHandle handle) nothrow
{
    WindowData* data = cast(WindowData*) handle;

    return (SDL_GetWindowFlags(data.handle) & SDL_WINDOW_INPUT_FOCUS) != 0;
}

void setVisible(NativeHandle handle, bool value) nothrow
{
    WindowData* data = cast(WindowData*) handle;

    if (value)
        SDL_ShowWindow(data.handle);
    else
        SDL_HideWindow(data.handle);
}

bool isVisible(in NativeHandle handle) nothrow
{
    WindowData* data = cast(WindowData*) handle;

    return (SDL_GetWindowFlags(data.handle) & SDL_WINDOW_SHOWN) != 0;
}

void setMinimized(NativeHandle handle, bool value) nothrow
{
    WindowData* data = cast(WindowData*) handle;

    if (value)
        SDL_MinimizeWindow(data.handle);
    else
        SDL_RestoreWindow(data.handle);
}

bool isMinimized(in NativeHandle handle) nothrow
{
    WindowData* data = cast(WindowData*) handle;

    return (SDL_GetWindowFlags(data.handle) & SDL_WINDOW_MINIMIZED) != 0;
}

void setMaximized(NativeHandle handle, bool value) nothrow
{
    WindowData* data = cast(WindowData*) handle;

    if (value)
        SDL_MaximizeWindow(data.handle);
    else
        SDL_RestoreWindow(data.handle);
}

bool isMaximized(in NativeHandle handle) nothrow
{
    WindowData* data = cast(WindowData*) handle;

    return (SDL_GetWindowFlags(data.handle) & SDL_WINDOW_MAXIMIZED) != 0;
}

void setIcon(NativeHandle handle, in Image image)
{
    WindowData* data = cast(WindowData*) handle;

    data.icon = image;
    SDL_Surface* iconSurface = createSurfaceFromImage(image);

    SDL_SetWindowIcon(data.handle, iconSurface);
    SDL_FreeSurface(iconSurface);
}

const(Image) getIcon(in NativeHandle handle) nothrow
{
    WindowData* data = cast(WindowData*) handle;

    return data.icon;
}

void setCursor(NativeHandle handle, in Cursor cursor)
{
    WindowData* data = cast(WindowData*) handle;

    SDL_Cursor** sdlCursor = cursor in data.sdlCursors;
    if (!sdlCursor)
    {
        SDL_Surface* surface = createSurfaceFromImage(cursor.image);
        scope(exit) SDL_FreeSurface(surface);
        SDL_Cursor* newCursor = SDL_CreateColorCursor(surface, cursor.hotspot.x, cursor.hotspot.y);

        data.sdlCursors[cursor] = newCursor;
        sdlCursor = cursor in data.sdlCursors;
    }

    SDL_SetCursor(*sdlCursor);
}

const(Cursor) getCursor(in NativeHandle handle) nothrow
{
    WindowData* data = cast(WindowData*) handle;

    return data.cursor;
}

void setTitle(NativeHandle handle, in string value)
{
    WindowData* data = cast(WindowData*) handle;

    data.title = value;
    SDL_SetWindowTitle(data.handle, value.toStringz);
}

string getTitle(in NativeHandle handle) nothrow
{
    WindowData* data = cast(WindowData*) handle;

    return data.title;
}

void setMouseCursorVisible(NativeHandle handle, bool value) nothrow
{
    WindowData* data = cast(WindowData*) handle;

    SDL_ShowCursor(value ? SDL_ENABLE : SDL_DISABLE);
}

bool isMouseCursorVisible(in NativeHandle handle) nothrow
{
    WindowData* data = cast(WindowData*) handle;

    return SDL_ShowCursor(SDL_QUERY) == SDL_ENABLE;
}

bool isMouseCursorCaptured(in NativeHandle handle) nothrow
{
    WindowData* data = cast(WindowData*) handle;

    return data.isCursorCaptured;
}

void setMouseCursorCaptured(NativeHandle handle, bool value) nothrow
{
    WindowData* data = cast(WindowData*) handle;

    if (value)
    {
        if (SDL_SetRelativeMouseMode(SDL_TRUE) == 0)
        {
            data.isCursorCaptured = true;
            return;
        }

        warning("Failed to capture mouse: %s.", SDL_GetError().fromStringz);
    }
    else
    {
        if (SDL_SetRelativeMouseMode(SDL_FALSE) == 0)
        {
            data.isCursorCaptured = false;
            return;
        }

        warning("Failed to release mouse: %s.", SDL_GetError().fromStringz);
    }
}

void setClipboardString(NativeHandle handle, in string value) nothrow
{
    WindowData* data = cast(WindowData*) handle;

    SDL_SetClipboardText(value.toStringz);
}

string getClipboardString(in NativeHandle handle) nothrow
{
    WindowData* data = cast(WindowData*) handle;

    return SDL_GetClipboardText().fromStringz.idup;
}