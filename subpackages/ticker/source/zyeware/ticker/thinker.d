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
protected:
    void delegate() mThink;
    Duration mNextThink;

public:
    this(TickerManager manager)
    {
        super(manager);
    }

    override void tick(in FrameTime frameTime)
    {
        if (ZyeWare.upTime < mNextThink)
            return;

        mThink();
    }
}