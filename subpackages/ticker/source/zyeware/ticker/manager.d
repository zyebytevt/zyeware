// This file is part of the ZyeWare Game Engine, and subject to the terms
// and conditions defined in the file 'LICENSE.txt', which is part
// of this source code package.
//
// Copyright © 2021-2024 ZyeByte. All rights reserved.
module zyeware.ticker.manager;

import std.algorithm : remove, filter, map;

import zyeware;
import zyeware.ticker;

class TickerManager
{
private:
    Ticker[] mTickers;
    Ticker[] mQueuedAdditions;

public:
    void add(Ticker ticker) nothrow
    {
        mQueuedAdditions ~= ticker;
    }

    void remove(Ticker ticker) nothrow
    {
        foreach (const Ticker t; mTickers)
        {
            if (t is ticker)
            {
                ticker.mIsFreeQueued = true;
                return;
            }
        }
    }

    void tick(in FrameTime frameTime)
    {
        foreach (Ticker ticker; mTickers)
            ticker.preTick(frameTime);

        foreach (Ticker ticker; mTickers)
            ticker.tick(frameTime);

        foreach (Ticker ticker; mTickers)
            ticker.postTick(frameTime);

        for (size_t i; i < mTickers.length; ++i)
        {
            if (mTickers[i].mIsFreeQueued)
            {
                mTickers[i].onRemove();
                mTickers = mTickers.remove(i--);
            }
        }

        if (mQueuedAdditions.length > 0)
        {
            foreach (Ticker ticker; mQueuedAdditions)
            {
                mTickers ~= ticker;
                ticker.onAdd();
            }

            mQueuedAdditions.length = 0;
        }
    }

    void draw() const
    {
        foreach (const Ticker ticker; mTickers)
            if (auto drawer = cast(Drawer) ticker)
                drawer.draw();
    }

    pragma(inline, true)
    auto getByType(T)() pure nothrow
    if (is(T : Ticker) || is(T == interface))
    {
        return mTickers.map!(ticker => cast(T) ticker).filter!(ticker => ticker);
    }
}
