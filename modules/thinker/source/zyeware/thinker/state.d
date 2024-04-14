// This file is part of the ZyeWare Game Engine, and subject to the terms
// and conditions defined in the file 'LICENSE.txt', which is part
// of this source code package.
//
// Copyright © 2021-2024 ZyeByte. All rights reserved.
module zyeware.thinker.state;

import std.datetime : Duration;

import zyeware;
import zyeware.thinker;

abstract class StateThinker : Thinker
{
private:
    FiniteStateMachine mFsm;
    Duration mNextTick;

protected:
    void addState(string name, void delegate() tick, void delegate() enter = null,
        void delegate() exit = null)
    {
        mFsm.addState(name, FiniteStateMachine.State(tick, enter, exit));
    }

    void removeState(string name)
    {
        mFsm.removeState(name);
    }

public:
    override void tick()
    {
        if (ZyeWare.upTime < mNextTick)
            return;

        mFsm.tick();
    }
}
