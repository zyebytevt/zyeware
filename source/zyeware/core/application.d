// This file is part of the ZyeWare Game Engine, and subject to the terms
// and conditions defined in the file 'LICENSE.txt', which is part
// of this source code package.
//
// Copyright © 2021-2024 ZyeByte. All rights reserved.
module zyeware.core.application;

import core.memory : GC;

import std.algorithm : min;
import std.typecons : Nullable;
import std.string : format;

import zyeware;
import zyeware.utils.collection;

abstract class Application
{
public:
    /// Override this method for application initialization.
    abstract void load();

    /// Override this method to perform logic on every frame.
    abstract void tick(in FrameTime frameTime);

    /// Override this method to perform rendering.
    abstract void draw();

    /// Destroys the application.
    void unload()
    {
    }
}

/// A ZyeWare application that takes care of the game state logic.
/// Game states can be set, pushed and popped.
class StateApplication : Application
{
protected:
    AppState[string] mStates;
    GrowableStack!string mStateStack;
    AppState mCurrentState;

public:
    Signal!(string) stateChanged;

    override void tick(in FrameTime frameTime)
    {
        if (mCurrentState)
            mCurrentState.tick(frameTime);
    }

    override void draw()
    {
        if (mCurrentState)
            mCurrentState.draw();
    }

    AppState getState(string name) pure
    {
        AppState state = mStates.get(name, null);
        enforce!CoreException(state, format!"State '%s' is not registered."(name));
        return state;
    }

    void registerState(string name, AppState state)
    in (name, "Name cannot be null.")
    in (state, "State cannot be null.")
    {
        enforce!CoreException(name !in mStates, format!"State '%s' is already registered."(name));
        mStates[name] = state;
    }

    void unregisterState(string name)
    in (name, "Name cannot be null.")
    {
        mStates.remove(name);
    }

    /// Change the current state to the given one.
    /// This method should not be called during event emission. Use a deferred call
    /// for this purpose.
    ///
    /// Params:
    ///     state = The game state to switch to.
    /// See_Also: ZyeWare.callDeferred
    void changeState(string name)
    in (name, "Name cannot be null.")
    {
        AppState state = getState(name);

        if (mCurrentState)
        {
            mCurrentState.onDetach(AppState.StateChangeMethod.change);
            mStateStack.pop();
        }

        mCurrentState = state;
        mStateStack.push(name);
        state.onAttach(AppState.StateChangeMethod.change);
        
        stateChanged(name);

        ZyeWare.collect();
    }

    /// Pushes the given state onto the stack, and switches to it.
    /// This method should not be called during event emission. Use a deferred call
    /// for this purpose.
    ///
    /// Params:
    ///     state = The state to push and switch to.
    /// See_Also: ZyeWare.callDeferred
    void pushState(string name)
    in (name, "Name cannot be null.")
    {
        AppState state = getState(name);

        if (mCurrentState)
            mCurrentState.onDetach(AppState.StateChangeMethod.push);

        mCurrentState = state;
        mStateStack.push(name);
        state.onAttach(AppState.StateChangeMethod.push);
        
        stateChanged(name);
        
        ZyeWare.collect();
    }

    /// Pops the current state from the stack, restoring the previous state.
    /// This method should not be called during event emission. Use a deferred call
    /// for this purpose.
    /// See_Also: ZyeWare.callDeferred
    void popState()
    {
        if (mCurrentState)
        {
            mCurrentState.onDetach(AppState.StateChangeMethod.pop);
            mStateStack.pop();
        }

        string stateName;

        if (!mStateStack.empty)
        {
            stateName = mStateStack.peek;
            mCurrentState = getState(stateName);
            mCurrentState.onAttach(AppState.StateChangeMethod.pop);
        }

        stateChanged(stateName);

        ZyeWare.collect();
    }

    /// The current game state.
    pragma(inline, true)
    AppState currentState() => mCurrentState;

    /// If this application currently has a game state loaded.
    pragma(inline, true)
    bool hasState() const nothrow => mCurrentState !is null;
}

/// An application state is used in conjunction with a `StateApplication` instance
/// to make managing an application with different states easier.
abstract class AppState
{
private:
    StateApplication mApplication;

protected:
    this(StateApplication application) pure nothrow
    in (application, "Parent application cannot be null.")
    {
        mApplication = application;
    }

public:
    enum StateChangeMethod
    {
        push,
        pop,
        change,
    }

    /// Override this function to perform logic every frame.
    ///
    /// Params:
    ///     frameTime = The time between this frame and the last.
    abstract void tick(in FrameTime frameTime);

    /// Override this function to perform rendering.
    abstract void draw() const;

    /// Called when this game state gets attached to a `StateApplication`.
    void onAttach(StateChangeMethod method)
    {
    }

    /// Called when this game state gets detached from a `StateApplication`.
    void onDetach(StateChangeMethod method)
    {
    }

    /// The application this game state is registered to.
    inout(StateApplication) application() pure inout nothrow
    {
        return mApplication;
    }
}
