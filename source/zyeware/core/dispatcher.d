module zyeware.core.dispatcher;

import zyeware;

struct EventDispatcher
{
    @disable this(this);

public static:
    Signal!() quitRequested;
    Signal!(const Display, vec2i) displayResized;
    Signal!(const Display, vec2i) displayMoved;
    Signal!(KeyCode) keyboardKeyPressed;
    Signal!(KeyCode) keyboardKeyReleased;
    Signal!(MouseCode, size_t) mouseButtonPressed;
    Signal!(MouseCode) mouseButtonReleased;
    Signal!(vec2) mouseWheelScrolled;
    Signal!(vec2, vec2) mouseMoved;
    Signal!(GamepadIndex) gamepadConnected;
    Signal!(GamepadIndex) gamepadDisconnected;
    Signal!(GamepadIndex, GamepadButton) gamepadButtonPressed;
    Signal!(GamepadIndex, GamepadButton) gamepadButtonReleased;
    Signal!(GamepadIndex, GamepadAxis, float) gamepadAxisMoved;
}