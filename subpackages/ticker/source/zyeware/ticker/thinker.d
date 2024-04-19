// This file is part of the ZyeWare Game Engine, and subject to the terms
// and conditions defined in the file 'LICENSE.txt', which is part
// of this source code package.
//
// Copyright © 2021-2024 ZyeByte. All rights reserved.
module zyeware.ticker.thinker;

import zyeware;
import zyeware.ticker;

class Thinker : Ticker
{
private:
    ThinkFunction mThink;
    Duration mNextThink;
    FrameTime mFrameTime;

protected:
    alias ThinkFunction = ThinkResult delegate();

    struct ThinkResult
    {
        Duration nextThinkIn;
        ThinkFunction think;
    }

    pragma(inline, true) FrameTime frameTime() @safe pure const nothrow => mFrameTime;

public:
    this(TickerManager manager)
    {
        super(manager);
    }

    override void tick(in FrameTime frameTime)
    {
        if (ZyeWare.upTime < mNextThink)
            return;

        if (mThink)
        {
            mFrameTime = frameTime;
            immutable ThinkResult result = mThink();
            mNextThink = ZyeWare.upTime + result.nextThinkIn;
            mThink = result.think;
        }
    }
}