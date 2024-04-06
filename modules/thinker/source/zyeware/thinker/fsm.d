// This file is part of the ZyeWare Game Engine, and subject to the terms
// and conditions defined in the file 'LICENSE.txt', which is part
// of this source code package.
//
// Copyright 2024 ZyeByte
module zyeware.thinker.fsm;

import zyeware;
import zyeware.thinker;

abstract class StateThinker : Thinker
{
private:
    FiniteStateMachine mFsm;

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
        mFsm.tick();
    }
}
