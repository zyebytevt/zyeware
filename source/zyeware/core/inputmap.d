// This file is part of the ZyeWare Game Engine, and subject to the terms
// and conditions defined in the file 'LICENSE.txt', which is part
// of this source code package.
//
// Copyright © 2021-2024 ZyeByte. All rights reserved.
module zyeware.core.inputmap;

import std.typecons : scoped, Rebindable, rebindable, Tuple;
import std.sumtype : SumType, match;
import std.algorithm : remove;

import zyeware;
import core.stdcpp.new_;

alias InputKey = Tuple!(KeyCode, "key", bool, "isPressed");
alias InputMouse = Tuple!(MouseCode, "button", bool, "isPressed");
alias InputGamepadButton = Tuple!(GamepadIndex, "index", GamepadButton,
    "button", bool, "isPressed");
alias InputGamepadAxis = Tuple!(GamepadIndex, "index", GamepadAxis, "axis", float, "value");

struct Input
{
private:
    alias Value = SumType!(InputKey, InputMouse, InputGamepadButton, InputGamepadAxis);

public:
    Value value;
    alias value this;

    static Input key(KeyCode key, bool isPressed) pure nothrow => Input(
        Value(InputKey(key, isPressed)));
    static Input mouse(MouseCode button, bool isPressed) pure nothrow => Input(
        Value(InputMouse(button, isPressed)));
    static Input gamepadButton(GamepadIndex index, GamepadButton button, bool isPressed) pure nothrow => Input(
        Value(InputGamepadButton(index, button, isPressed)));
    static Input gamepadAxis(GamepadIndex index, GamepadAxis axis, float value) pure nothrow => Input(
        Value(InputGamepadAxis(index, axis, value)));
}

final class Action
{
protected:
    float mDeadzone;
    Input[] mTemplates;

    bool mOldIsPressed, mCurrentIsPressed;
    float mCurrentStrength = 0f;

    this(float deadzone) pure nothrow
    {
        mDeadzone = deadzone;
        mTemplates = [];
    }

    bool processInput(in Input input) pure nothrow
    {
        alias MatchResult = Tuple!(bool, "isMatch", float, "strength");

        alias matcher = match!((InputKey key, InputKey template_) {
            if (key.key != template_.key)
                return MatchResult(false, 0);

            return MatchResult(true, key.isPressed ? 1 : 0);
        }, (InputMouse mouse, InputMouse template_) {
            if (mouse.button != template_.button)
                return MatchResult(false, 0);

            return MatchResult(true, mouse.isPressed ? 1 : 0);
        }, (InputGamepadButton button, InputGamepadButton template_) {
            if (button.index != template_.index || button.button != template_.button)
                return MatchResult(false, 0);

            return MatchResult(true, button.isPressed ? 1 : 0);
        }, (InputGamepadAxis axis, InputGamepadAxis template_) {
            immutable float absValue = abs(axis.value);

            if (axis.index != template_.index || axis.axis != template_.axis || absValue < mDeadzone)
                return MatchResult(false, 0);

            if (template_.value < 0 && axis.value > 0 || template_.value > 0 && axis.value < 0)
                return MatchResult(false, 0);

            return MatchResult(true, absValue);
        }, (_1, _2) => MatchResult(false, 0));

        foreach (Input template_; mTemplates)
        {
            immutable MatchResult result = matcher(input, template_);

            if (result.isMatch)
            {
                mCurrentIsPressed = result.strength > 0;
                mCurrentStrength = result.strength;
                return true;
            }
        }

        return false;
    }

public:
    /// Adds an `InputEvent` to the action as a template.
    ///
    /// Params:
    ///     input = The input template to add.
    ///
    /// Returns: Itself for chaining.
    Action addInput(in Input input) pure nothrow
    {
        mTemplates ~= input;
        return this;
    }

    /// Removes an `InputEvent` from the action.
    ///
    /// Params:
    ///     input = The input template to remove.
    ///
    /// Returns: Itself for chaining.
    Action removeInput(in Input input)
    {
        for (size_t i; i < mTemplates.length; ++i)
            if (input == mTemplates[i])
            {
                mTemplates = mTemplates.remove(i);
                break;
            }

        return this;
    }
}

struct InputMap
{
    @disable this();
    @disable this(this);

private static:
    Action[string] sActions;

    void processInput(in Input input) nothrow
    {
        foreach (Action action; sActions.values)
            action.processInput(input);
    }

    void onKeyboardKeyPressed(KeyCode key) nothrow
    {
        processInput(Input.key(key, true));
    }

    void onKeyboardKeyReleased(KeyCode key) nothrow
    {
        processInput(Input.key(key, false));
    }

    void onMouseButtonPressed(MouseCode button, size_t clickCount) nothrow
    {
        processInput(Input.mouse(button, true));
    }

    void onMouseButtonReleased(MouseCode button) nothrow
    {
        processInput(Input.mouse(button, false));
    }

    void onGamepadButtonPressed(GamepadIndex index, GamepadButton button) nothrow
    {
        processInput(Input.gamepadButton(index, button, true));
    }

    void onGamepadButtonReleased(GamepadIndex index, GamepadButton button) nothrow
    {
        processInput(Input.gamepadButton(index, button, false));
    }

    void onGamepadAxisMoved(GamepadIndex index, GamepadAxis axis, float value) nothrow
    {
        processInput(Input.gamepadAxis(index, axis, value));
    }

package(zyeware.core) static:
    void initialize() @safe
    {
        ZyeWare.events.keyboardKeyPressed += &onKeyboardKeyPressed;
        ZyeWare.events.keyboardKeyReleased += &onKeyboardKeyReleased;
        ZyeWare.events.mouseButtonPressed += &onMouseButtonPressed;
        ZyeWare.events.mouseButtonReleased += &onMouseButtonReleased;
        ZyeWare.events.gamepadButtonPressed += &onGamepadButtonPressed;
        ZyeWare.events.gamepadButtonReleased += &onGamepadButtonReleased;
        ZyeWare.events.gamepadAxisMoved += &onGamepadAxisMoved;
    }

    void cleanup() @safe nothrow
    {
        ZyeWare.events.keyboardKeyPressed -= &onKeyboardKeyPressed;
        ZyeWare.events.keyboardKeyReleased -= &onKeyboardKeyReleased;
        ZyeWare.events.mouseButtonPressed -= &onMouseButtonPressed;
        ZyeWare.events.mouseButtonReleased -= &onMouseButtonReleased;
        ZyeWare.events.gamepadButtonPressed -= &onGamepadButtonPressed;
        ZyeWare.events.gamepadButtonReleased -= &onGamepadButtonReleased;
        ZyeWare.events.gamepadAxisMoved -= &onGamepadAxisMoved;
    }

    void tick() @safe nothrow
    {
        foreach (Action action; sActions.values)
            action.mOldIsPressed = action.mCurrentIsPressed;
    }

public static:
    /// Adds an action.
    ///
    /// Params:
    ///     name = The name of the new action.
    ///     deadzone = The amount of input force necessary for this action to fire.
    ///
    /// Returns: The newly created `Action`.
    /// See_Also: Action
    Action addAction(string name, float deadzone = 0.5f) nothrow
    in (name, "Name cannot be null.")
    in (deadzone != float.nan, "Deadzone cannot be NaN.")
    {
        if (auto action = getAction(name))
        {
            Logger.core.warning("Cannot add action '%s' as it already exists.", name);
            return action;
        }

        return sActions[name] = new Action(deadzone);
    }

    /// Removes the specified action.
    ///
    /// Params:
    ///     name = The name of the action to remove.
    void removeAction(string name) nothrow
    in (name, "Name cannot be null.")
    {
        sActions.remove(name);
    }

    /// Returns the specified action, or null if it doesn't exist.
    ///
    /// Params:
    ///     name = The name of the action to return.
    Action getAction(string name) nothrow
    in (name, "Name cannot be null.")
    {
        Action* action = name in sActions;
        if (!action)
            return null;

        return *action;
    }

    /// Returns if the specified action is currently in it's "pressed" state.
    ///
    /// Params:
    ///     name = The name of the action.
    bool isActionPressed(string name) nothrow
    in (name, "Name cannot be null.")
    {
        if (auto action = getAction(name))
            return action.mCurrentIsPressed;

        return false;
    }

    /// Returns if the specified action has changed it's state to "pressed" in this frame.
    ///
    /// Params:
    ///     name = The name of the action.
    bool isActionJustPressed(string name) nothrow
    in (name, "Name cannot be null.")
    {
        if (auto action = getAction(name))
            return !action.mOldIsPressed && action.mCurrentIsPressed;

        return false;
    }

    /// Returns if the specified action has changed it's state to "released" in this frame.
    ///
    /// Params:
    ///     name = The name of the action.
    bool isActionJustReleased(string name) nothrow
    in (name, "Name cannot be null.")
    {
        if (auto action = getAction(name))
            return action.mOldIsPressed && !action.mCurrentIsPressed;

        return false;
    }

    /// Returns the current input strength of the specified action, or 0 if it isn't pressed.
    ///
    /// Params:
    ///     name = The name of the action.
    float getActionStrength(string name) nothrow
    in (name, "Name cannot be null.")
    {
        if (auto action = getAction(name))
            return action.mCurrentStrength;

        return 0f;
    }
}
