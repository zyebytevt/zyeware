// This file is part of the ZyeWare Game Engine, and subject to the terms
// and conditions defined in the file 'LICENSE.txt', which is part
// of this source code package.
//
// Copyright © 2021-2024 ZyeByte. All rights reserved.
module zyeware.thinker.appstate;

import zyeware.core.application;
import zyeware.thinker;
import zyeware;

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
        mThinkerManager = new ThinkerManager();
    }

    override void tick(in FrameTime frameTime)
    {
        mThinkerManager.tick(frameTime);
    }

    override void draw() const
    {
        mThinkerManager.draw();
    }
}
