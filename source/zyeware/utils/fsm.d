// This file is part of the ZyeWare Game Engine, and subject to the terms
// and conditions defined in the file 'LICENSE.txt', which is part
// of this source code package.
//
// Copyright © 2021-2024 ZyeByte. All rights reserved.
module zyeware.core.fsm;

import std.exception : enforce;
import std.string : format;

import zyeware;

struct FiniteStateMachine
{
private:
    State[string] mStates;
    string mCurrentStateName;
    State* mCurrentState;

public:
    struct State
    {
        void delegate() onTick;
        void delegate() onEnter;
        void delegate() onExit;
    }

    void addState(string name, State state) @safe pure nothrow
    {
        mStates[name] = state;
    }

    void removeState(string name) @safe pure nothrow
    in (mCurrentStateName != name)
    {
        mStates.remove(name);
    }

    void tick()
    {
        if (mCurrentState && mCurrentState.onTick)
            mCurrentState.onTick();
    }

    string state() @safe pure nothrow => mCurrentStateName;

    string state(string value)
    {
        if (mCurrentState && mCurrentState.onExit)
            mCurrentState.onExit();

        mCurrentStateName = value;
        mCurrentState = mCurrentStateName in mStates;
        enforce!CoreException(mCurrentState,
            format!"State '%s' does not exist."(mCurrentStateName));

        if (mCurrentState.onEnter)
            mCurrentState.onEnter();

        return mCurrentStateName;
    }
}
