// This file is part of the ZyeWare Game Engine, and subject to the terms
// and conditions defined in the file 'LICENSE.txt', which is part
// of this source code package.
//
// Copyright 2021 ZyeByte
module zyeware.thinker.appstate;

import zyeware.core.application;
import zyeware.thinker;

class ThinkerAppState : AppState
{
private:
    ThinkerManager mThinkerManager;

protected:
    void addThinker(Thinker thinker)
    {
        mThinkerManager.add(thinker);
    }

    void removeThinker(Thinker thinker)
    {
        mThinkerManager.remove(thinker);
    }

public:
    this(StateApplication application)
    {
        super(application);
    }

    override void tick()
    {
        mThinkerManager.tick();
    }

    override void draw() const
    {
        mThinkerManager.draw();
    }
}
