module zyeware.core.dispatcher;

import zyeware;

struct EventDispatcher
{
    @disable this(this);

public static:
    Signal!() onQuit;
    Signal!(const Display, vec2i) onDisplayResize;
    Signal!(const Display, vec2i) onDisplayMove;
    Signal!(KeyCode) onKeyPress;
    Signal!(KeyCode) onKeyRelease;
    Signal!(MouseCode, size_t) onMouseButtonPress;
    Signal!(MouseCode) onMouseButtonRelease;
    Signal!(vec2) onMouseScroll;
    Signal!(vec2, vec2) onMouseMove;
    Signal!(GamepadIndex) onGamepadConnect;
    Signal!(GamepadIndex) onGamepadDisconnect;
    Signal!(GamepadIndex, GamepadButton) onGamepadButtonPress;
    Signal!(GamepadIndex, GamepadButton) onGamepadButtonRelease;
    Signal!(GamepadIndex, GamepadAxis, float) onGamepadAxisMove;
}