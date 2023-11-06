// This file is part of the ZyeWare Game Engine, and subject to the terms
// and conditions defined in the file 'LICENSE.txt', which is part
// of this source code package.
//
// Copyright 2021 ZyeByte
module zyeware.core.events.input;

import std.string : format;
import std.typecons : Rebindable;

import zyeware.common;
import zyeware.core.events.event;
import zyeware.utils.codes;
import zyeware.rendering.display;

/// InputEvents are sent when the user makes some kind of input. They are also used
/// as templates to register actions within the `InputManager`.
/// See_Also: InputManager
abstract class InputEvent : Event
{
public:
    /// This method is used to check if the input "template" used for registering actions
    /// matches the given event `ev`.
    ///
    /// Returns: If `ev` matches this template.
    abstract bool matchInputTemplate(in InputEvent ev, float deadzone, out bool pressed, out float strength) const nothrow;
}

/// Like InputEvent, but sent from a Display.
/// See_Also: InputEvent
abstract class InputEventFromDisplay : InputEvent
{
protected:
    Rebindable!(const Display) mDisplay;

public:
    /// Params:
    ///     display = The display this event was sent from.
    this(in Display display) pure nothrow
    {
        mDisplay = display;
    }

    /// The display this event was sent from.
    final const(Display) display() pure const nothrow
    {
        return mDisplay;
    }
}

/// This event is sent when an action is triggered.
/// See_Also: InputManager
class InputEventAction : InputEvent
{
protected:
    string mAction;
    bool mIsPressed;
    float mStrength = 1f;

public:
    /// Params:
    ///     action = The name of the action that was triggered.
    ///     isPressed = Whether the action has been pressed or not.
    ///     strength = The strength of the action, is applicable.
    this(string action, bool isPressed, float strength) pure nothrow
        in (action, "Action cannot be null.")
        in (strength != float.nan, "Strength cannot be NaN.")
    {
        mAction = action;
        mIsPressed = isPressed;
        mStrength = strength;
    }

    /// The name of the action that was triggered.
    final string action() const pure nothrow
    {
        return mAction;
    }

    /// Whether the action has been pressed or not.
    final bool isPressed() const pure nothrow
    {
        return mIsPressed;
    }

    /// The strength of the action, is applicable.
    final float strength() const pure nothrow
    {
        return mStrength;
    }

    override bool matchInputTemplate(in InputEvent ev, float deadzone, out bool pressed, out float strength) const nothrow
    {
        return false;
    }

    override string toString() const
    {
        return format!"InputEventAction(action: %s, isPressed: %s, strength: %.2f)"(mAction, mIsPressed, mStrength);
    }
}

// =============================================

/// This event is sent when the user activates a key on a physical keyboard.
class InputEventKey : InputEventFromDisplay
{
protected:
    KeyCode mKeycode;
    bool mIsPressed;

public:
    /// Params:
    ///     display = The display this event was sent from.
    ///     keycode = The key code of the activated key.
    ///     isPressed = Whether the key is pressed or not.
    this(in Display display, KeyCode keycode, bool isPressed) pure nothrow
    {
        super(display);

        mKeycode = keycode;
        mIsPressed = isPressed;
    }

    /// This constructor is used for template instantiation.
    /// Params:
    ///     keycode = The key code of the key to match.
    this(KeyCode keycode) pure nothrow
    {
        this(null, keycode, false);
    }

    /// The key code of the activated key.
    final KeyCode keycode() const pure nothrow
    {
        return mKeycode;
    }

    /// Whether the key is pressed or not.
    final bool isPressed() const pure nothrow
    {
        return mIsPressed;
    }

    override bool matchInputTemplate(in InputEvent ev, float deadzone, out bool pressed, out float strength) const nothrow
    {
        auto key = cast(const InputEventKey) ev;
        if (!key)
            return false;

        if (mKeycode == key.mKeycode)
        {
            pressed = key.mIsPressed;
            strength = pressed ? 1f : 0f;

            return true;
        }
        else
            return false;
    }

    override string toString() const
    {
        return "InputEventKey(display: %s, keycode: %d, isPressed: %s)".format(mDisplay, mKeycode, mIsPressed);
    }
}

/// This event is sent when the user types some text. This handles unicode,
/// so use this instead of `InputEventKey` when reading text.
/// See_Also: InputEventKey
class InputEventText : InputEventFromDisplay
{
protected:
    dchar mCodepoint;

public:
    /// Params:
    ///     display = The display this event was sent from.
    ///     codepoint = The unicode code point of the sent character.
    this(in Display display, dchar codepoint) pure nothrow
    {
        super(display);

        mCodepoint = codepoint;
    }

    /// The unicode code point of the sent character.
    final dchar codepoint() pure const nothrow
    {
        return mCodepoint;
    }

    override bool matchInputTemplate(in InputEvent ev, float deadzone, out bool pressed, out float strength) const nothrow
    {
        return false;
    }

    override string toString() const
    {
        return "InputEventText(display: %s, codepoint: %d)".format(mDisplay, mCodepoint);
    }
}

// =============================================

/// This event is sent when the user activates a mouse button inside a display.
class InputEventMouseButton : InputEventFromDisplay
{
protected:
    MouseCode mButton;
    bool mIsPressed;
    size_t mClickCount;

public:
    /// Params:
    ///     display = The display this event was sent from.
    ///     button = The mouse code of the button that was activated.
    ///     isPressed = Whether the button was pressed or not.
    this(in Display display, MouseCode button, bool isPressed, size_t clickCount) pure nothrow
    {
        super(display);

        mButton = button;
        mIsPressed = isPressed;
        mClickCount = clickCount;
    }

    /// This constructor is used for template instantiation.
    /// Params:
    ///     button = The mouse code of the button to match.
    this(MouseCode button) pure nothrow
    {
        this(null, button, false, 0);
    }

    /// The mouse code of the button that was activated.
    final MouseCode button() const pure nothrow
    {
        return mButton;
    }

    /// Whether the button was pressed or not.
    final bool isPressed() const pure nothrow
    {
        return mIsPressed;
    }

    final size_t clickCount() const pure nothrow
    {
        return mClickCount;
    }

    override bool matchInputTemplate(in InputEvent ev, float deadzone, out bool pressed, out float strength) const nothrow
    {
        auto mouse = cast(const InputEventMouseButton) ev;
        if (!mouse)
            return false;

        if (mButton == mouse.mButton)
        {
            pressed = mouse.mIsPressed;
            strength = pressed ? 1f : 0f;

            return true;
        }
        else
            return false;
    }

    override string toString() const
    {
        return "InputEventMouseButton(display: %s, button: %d, isPressed: %s)".format(mDisplay, mButton, mIsPressed);
    }
}

/// This event is sent when the user scrolls the mouse wheel inside a display.
class InputEventMouseScroll : InputEventFromDisplay
{
protected:
    Vector2f mOffset;

public:
    /// Params:
    ///     display = The display this event was sent from.
    ///     offset = The amount the mouse wheel was scrolled.
    this(in Display display, Vector2f offset) pure nothrow
    {
        super(display);

        mOffset = offset;
    }

    /// This constructor is used for template instantiation.
    /// Params:
    ///     offset = The amount of wheel scrolling to match.
    this(Vector2f offset) pure nothrow
    {
        this(null, offset);
    }

    /// The amount the mouse wheel was scrolled.
    final Vector2f offset() const pure nothrow
    {
        return mOffset;
    }

    override bool matchInputTemplate(in InputEvent ev, float deadzone, out bool pressed, out float strength) const nothrow
    {
        auto scroll = cast(const InputEventMouseScroll) ev;
        if (!scroll)
            return false;

        immutable bool sameXDirection = (mOffset.x < 0 && scroll.mOffset.x < 0) || (mOffset.x > 0 && scroll.mOffset.x > 0);
        immutable bool sameYDirection = (mOffset.y < 0 && scroll.mOffset.y < 0) || (mOffset.y > 0 && scroll.mOffset.y > 0);

        pressed = sameXDirection ^ sameYDirection;
        strength = pressed ? 1f : 0f;

        return true;
    }

    override string toString() const
    {
        return "InputEventMouseScroll(display: %s, offset: %s)".format(mDisplay, mOffset);
    }
}

/// This event is sent when the user moves the cursor inside a display.
class InputEventMouseMotion : InputEventFromDisplay
{
protected:
    Vector2f mPosition;
    Vector2f mRelative;

public:
    /// Params:
    ///     display = The display this event was sent from.
    ///     position = The current cursor position.
    ///     relative = The relative motion of the cursor.
    this(in Display display, Vector2f position, Vector2f relative) pure nothrow
    {
        super(display);

        mPosition = position;
        mRelative = relative;
    }

    /// The current cursor position.
    final Vector2f position() const pure nothrow
    {
        return mPosition;
    }

    /// The relative motion of the cursor.
    final Vector2f relative() const pure nothrow
    {
        return mRelative;
    }

    override bool matchInputTemplate(in InputEvent ev, float deadzone, out bool pressed, out float strength) const nothrow
    {
        return false;
    }

    override string toString() const
    {
        return "InputEventMouseMotion(position: %s, relative: %s)".format(mPosition, mRelative);
    }
}

// =============================================

/// This event is used as a base class for events regarding a gamepad.
abstract class InputEventGamepad : InputEvent
{
protected:
    size_t mGamepadIndex;

    this(size_t gamepadIndex) pure nothrow
    {
        mGamepadIndex = gamepadIndex;
    }

public:
    /// The index of the gamepad that sent this event.
    final size_t gamepadIndex() const pure nothrow
    {
        return mGamepadIndex;
    }
}

/// This event is sent when the user activates a button on a gamepad.
class InputEventGamepadButton : InputEventGamepad
{
protected:
    bool mIsPressed;
    GamepadButton mButton;

public:
    /// Params:
    ///     gamepadIndex = The index of the gamepad.
    ///     button = The button that was activated.
    ///     isPressed = Whether the button was pressed or not.
    this(size_t gamepadIndex, GamepadButton button, bool isPressed) pure nothrow
    {
        super(gamepadIndex);
        mIsPressed = isPressed;
        mButton = button;
    }

    /// This constructor is used for template instantiation.
    /// Params:
    ///     gamepadIndex = The index of the gamepad.
    ///     button = The button to match on.
    this(size_t gamepadIndex, GamepadButton button) pure nothrow
    {
        this(gamepadIndex, button, false);
    }

    /// The gamepad button that was activated.
    final GamepadButton button() const pure nothrow
    {
        return mButton;
    }

    /// Whether the button was pressed or not.
    final bool isPressed() const pure nothrow
    {
        return mIsPressed;
    }

    override bool matchInputTemplate(in InputEvent ev, float deadzone, out bool pressed, out float strength) const nothrow
    {
        auto button = cast(const InputEventGamepadButton) ev;
        if (!button)
            return false;

        if (mGamepadIndex == button.mGamepadIndex && mButton == button.mButton)
        {
            pressed = button.mIsPressed;
            strength = pressed ? 1f : 0f;

            return true;
        }
        else
            return false;
    }

    override string toString() const
    {
        return "InputEventGamepadButton(gamepad: #%d, button: %s, isPressed: %s)".format(mGamepadIndex, mButton, mIsPressed);
    }
}

/// This event is sent when a gamepad axis is moved. Without a deadzone, this
/// event will be more or less sent constantly.
class InputEventGamepadAxisMotion : InputEventGamepad
{
protected:
    GamepadAxis mAxis;
    float mValue;

public:
    /// This constructor is also used for template instantiation.
    /// Params:
    ///     gamepadIndex = The index of the gamepad.
    ///     axis = The axis that was moved.
    ///     value = The current value of the given axis.
    this(size_t gamepadIndex, GamepadAxis axis, float value) pure nothrow
    {
        super(gamepadIndex);

        mAxis = axis;
        mValue = value;
    }

    /// The axis that was moved.
    final GamepadAxis axis() const pure nothrow
    {
        return mAxis;
    }

    /// The current value of the given axis.
    final float value() const pure nothrow
    {
        return mValue;
    }

    override bool matchInputTemplate(in InputEvent ev, float deadzone, out bool pressed, out float strength) const nothrow
    {
        auto axisEv = cast(const InputEventGamepadAxisMotion) ev;
        if (!axisEv)
            return false;

        immutable bool match = mGamepadIndex == axisEv.mGamepadIndex && mAxis == axisEv.mAxis;

        if (match)
        {
            immutable float absValue = abs(axisEv.mValue);
            immutable bool sameDirection = ((mValue < 0) == (axisEv.mValue < 0)) || axisEv.mValue == 0;
            
            pressed = sameDirection && absValue >= deadzone;

            if (pressed)
            {
                if (deadzone == 1f)
                    strength = 1f;
                else
                    strength = clamp(invLerp(deadzone, 1f, absValue), 0f, 1f);
            }
            else
                strength = 0f;
        }

        return match;
    }

    override string toString() const
    {
        return "InputEventGamepadAxisMotion(gamepad: #%d, axis: %s, value: %.4f)".format(mGamepadIndex, mAxis, mValue);
    }
}

class InputEventGamepadAdded : InputEventGamepad
{
public:
    /// Params:
    ///     gamepadIndex = The index of the gamepad.
    this(size_t gamepadIndex) pure nothrow
    {
        super(gamepadIndex);
    }

    override bool matchInputTemplate(in InputEvent ev, float deadzone, out bool pressed, out float strength) const nothrow
    {
        return false;
    }

    override string toString() const
    {
        return "InputEventGamepadAdded(gamepad: #%d)".format(mGamepadIndex);
    }
}

class InputEventGamepadRemoved : InputEventGamepad
{
public:
    /// Params:
    ///     gamepadIndex = The index of the gamepad.
    this(size_t gamepadIndex) pure nothrow
    {
        super(gamepadIndex);
    }

    override bool matchInputTemplate(in InputEvent ev, float deadzone, out bool pressed, out float strength) const nothrow
    {
        return false;
    }

    override string toString() const
    {
        return "InputEventGamepadRemoved(gamepad: #%d)".format(mGamepadIndex);
    }
}