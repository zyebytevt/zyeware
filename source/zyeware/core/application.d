// This file is part of the ZyeWare Game Engine, and subject to the terms
// and conditions defined in the file 'LICENSE.txt', which is part
// of this source code package.
//
// Copyright 2021 ZyeByte
module zyeware.core.application;

import core.memory : GC;
import std.algorithm : min;
import std.typecons : Nullable;

import zyeware;
import zyeware.utils.collection;

abstract class Application {
public:
    /// Override this method for application initialization.
    abstract void initialize();

    /// Override this method to perform logic on every frame.
    abstract void tick();

    /// Override this method to perform rendering.
    abstract void draw();

    /// Destroys the application.
    void cleanup() {
    }
}

/// A ZyeWare application that takes care of the game state logic.
/// Game states can be set, pushed and popped.
class StateApplication : Application {
protected:
    GrowableStack!AppState mStateStack;

public:
    Signal!() stateChanged;

    override void tick() {
        if (hasState)
            currentState.tick();
    }

    override void draw() {
        if (hasState)
            currentState.draw();
    }

    /// Change the current state to the given one.
    /// This method should not be called during event emission. Use a deferred call
    /// for this purpose.
    ///
    /// Params:
    ///     state = The game state to switch to.
    /// See_Also: ZyeWare.callDeferred
    void changeState(AppState state)
    in (state, "Game state cannot be null.") {
        if (hasState)
            mStateStack.pop().onDetach();

        mStateStack.push(state);
        state.onAttach(!state.mWasAlreadyAttached);
        state.mWasAlreadyAttached = true;
        stateChanged();
        ZyeWare.collect();
    }

    /// Pushes the given state onto the stack, and switches to it.
    /// This method should not be called during event emission. Use a deferred call
    /// for this purpose.
    ///
    /// Params:
    ///     state = The state to push and switch to.
    /// See_Also: ZyeWare.callDeferred
    void pushState(AppState state)
    in (state, "Game state cannot be null.") {
        if (hasState)
            currentState.onDetach();

        mStateStack.push(state);
        state.onAttach(!state.mWasAlreadyAttached);
        state.mWasAlreadyAttached = true;
        stateChanged();
        ZyeWare.collect();
    }

    /// Pops the current state from the stack, restoring the previous state.
    /// This method should not be called during event emission. Use a deferred call
    /// for this purpose.
    /// See_Also: ZyeWare.callDeferred
    void popState() {
        if (hasState)
            mStateStack.pop().onDetach();

        currentState.onAttach(!currentState.mWasAlreadyAttached);
        currentState.mWasAlreadyAttached = true;
        stateChanged();
        ZyeWare.collect();
    }

    /// The current game state.
    pragma(inline, true)
    AppState currentState() {
        return mStateStack.peek;
    }

    /// If this application currently has a game state loaded.
    pragma(inline, true)
    bool hasState() const nothrow {
        return !mStateStack.empty;
    }
}

/// An application state is used in conjunction with a `StateApplication` instance
/// to make managing an application with different states easier.
abstract class AppState {
private:
    StateApplication mApplication;
    bool mWasAlreadyAttached;

protected:
    this(StateApplication application) pure nothrow
    in (application, "Parent application cannot be null.") {
        mApplication = application;
    }

public:
    /// Override this function to perform logic every frame.
    ///
    /// Params:
    ///     frameTime = The time between this frame and the last.
    abstract void tick();

    /// Override this function to perform rendering.
    abstract void draw() const;

    /// Called when this game state gets attached to a `StateApplication`.
    ///
    /// Params:
    ///     firstTime = Whether it gets attached the first time or not.
    void onAttach(bool firstTime) {
    }

    /// Called when this game state gets detached from a `StateApplication`.
    void onDetach() {
    }

    /// The application this game state is registered to.
    inout(StateApplication) application() pure inout nothrow {
        return mApplication;
    }

    /// Whether this game state was already attached once or not.
    bool wasAlreadyAttached() pure const nothrow {
        return mWasAlreadyAttached;
    }
}
