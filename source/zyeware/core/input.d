// This file is part of the ZyeWare Game Engine, and subject to the terms
// and conditions defined in the file 'LICENSE.txt', which is part
// of this source code package.
//
// Copyright 2021 ZyeByte
module zyeware.core.input;

import std.typecons : scoped, Rebindable, rebindable;
import std.exception : assumeWontThrow;

import zyeware.common;

/// The `InputManager` is responsible for mapping inputs to specific actions.
struct InputManager
{
    @disable this();
    @disable this(this);

private static:
    Action[string] sActions;

package(zyeware.core) static:
    void tick() nothrow
    {
        foreach (Action action; sActions.values)
            action.mOldIsPressed = action.mCurrentIsPressed;
    }

    void receive(in InputEvent ev)
        in (ev, "Received event cannot be null.")
    {
        if (cast(InputEventAction) ev)
            return;
        
        bool isPressed;
        float strength;

        foreach (string name, Action action; sActions)
            if (action.receiveInputEvent(ev, isPressed, strength))
                ZyeWare.emit!InputEventAction(name, isPressed, strength);
    }

public static:
    /// An action represents an abstract input, to which specific input
    /// events can be mapped as templates. Whenever inputs of these kind
    /// are made, the action fires.
    ///
    /// See_Also: InputEvent
    class Action
    {
    private:
        float mDeadzone;
        Rebindable!(const InputEvent)[] mInputs;

        bool mOldIsPressed, mCurrentIsPressed;
        float mCurrentStrength = 0f;

        this(float deadzone) pure nothrow
        {
            mDeadzone = deadzone;
            mInputs = [];
        }

        bool receiveInputEvent(in InputEvent ev, out bool isPressed, out float strength)
            in (ev, "Received event cannot be null.")
        {
            foreach (input; mInputs)
            {
                if (input.matchInputTemplate(ev, mDeadzone, isPressed, strength))
                {
                    mCurrentIsPressed = isPressed;
                    mCurrentStrength = strength;

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
        Action addInput(in InputEvent input) pure nothrow
            in (input, "Input event cannot be null.")
        {
            mInputs ~= rebindable(input);
            return this;
        }

        /// Removes an `InputEvent` from the action.
        ///
        /// Params:
        ///     input = The input template to remove.
        ///
        /// Returns: Itself for chaining.
        Action removeInput(in InputEvent input)
            in (input, "Input event cannot be null.")
        {
            for (size_t i; i < mInputs.length; ++i)
                if (input == mInputs[i])
                {
                    mInputs = mInputs[0 .. i] ~ mInputs[i + 1 .. $];
                    break;
                }

            return this;
        }
    }

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
            Logger.core.log(LogLevel.warning, "Cannot add action '%s' as it already exists.", name);
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
        return sActions.get(name, null).assumeWontThrow;
    }

    /// Returns if the specified action is currently in it's "pressed" state.
    ///
    /// Params:
    ///     name = The name of the action.
    bool isActionPressed(string name) nothrow
        in (name, "Name cannot be null.")
    {
        if (auto action = sActions.get(name, null).assumeWontThrow)
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
        if (auto action = sActions.get(name, null).assumeWontThrow)
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
        if (auto action = sActions.get(name, null).assumeWontThrow)
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
        if (auto action = sActions.get(name, null).assumeWontThrow)
            return action.mCurrentStrength;

        return 0f;
    }
}