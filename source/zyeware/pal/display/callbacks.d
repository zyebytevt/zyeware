module zyeware.pal.display.callbacks;

import zyeware.common;
import zyeware.rendering;

struct DisplayPALCallbacks
{
public:
    NativeHandle function(in DisplayProperties properties) createDisplay;
    void function(in NativeHandle handle) destroyDisplay;

    void function(in NativeHandle handle) update;
    void function(in NativeHandle handle) swapBuffers;

    bool function(in NativeHandle handle, KeyCode code) nothrow isKeyPressed;
    bool function(in NativeHandle handle, MouseCode code) nothrow isMouseButtonPressed;
    bool function(in NativeHandle handle, size_t gamepadIndex, GamepadButton button) nothrow isGamepadButtonPressed;
    float function(in NativeHandle handle, size_t gamepadIndex, GamepadAxis axis) nothrow getGamepadAxisValue;
    Vector2i function(in NativeHandle handle) nothrow getCursorPosition;

    void function(in NativeHandle handle, bool value) setVSyncEnabled;
    bool function(in NativeHandle handle) nothrow isVSyncEnabled;

    void function(in NativeHandle handle, Vector2i value) setPosition;
    Vector2i function(in NativeHandle handle) nothrow getPosition;

    void function(in NativeHandle handle, Vector2i value) setSize;
    Vector2i function(in NativeHandle handle) nothrow getSize;

    void function(in NativeHandle handle, bool value) setFullscreen;
    bool function(in NativeHandle handle) nothrow isFullscreen;

    void function(in NativeHandle handle, bool value) setResizable;
    bool function(in NativeHandle handle) nothrow isResizable;

    void function(in NativeHandle handle, bool value) setDecorated;
    bool function(in NativeHandle handle) nothrow isDecorated;

    void function(in NativeHandle handle, bool value) setFocused;
    bool function(in NativeHandle handle) nothrow isFocused;

    void function(in NativeHandle handle, bool value) setVisible;
    bool function(in NativeHandle handle) nothrow isVisible;

    void function(in NativeHandle handle, in Image image) setIcon;
    const(Image) function(in NativeHandle handle) nothrow getIcon;

    void function(in NativeHandle handle, in Cursor cursor) setCursor;
    const(Cursor) function(in NativeHandle handle) nothrow getCursor;

    void function(in NativeHandle handle, string title) setTitle;
    string function(in NativeHandle handle) nothrow getTitle;

    void function(in NativeHandle handle, bool value) setMouseCursorVisible;
    bool function(in NativeHandle handle) nothrow isMouseCursorVisible;

    void function(in NativeHandle handle, bool value) setMouseCursorCaptured;
    bool function(in NativeHandle handle) nothrow isMouseCursorCaptured;

    void function(in NativeHandle handle, string value) setClipboardString;
    string function(in NativeHandle handle) getClipboardString;
}