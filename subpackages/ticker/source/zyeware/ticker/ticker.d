// This file is part of the ZyeWare Game Engine, and subject to the terms
// and conditions defined in the file 'LICENSE.txt', which is part
// of this source code package.
//
// Copyright © 2021-2024 ZyeByte. All rights reserved.
module zyeware.ticker.ticker;

import zyeware;
import zyeware.ticker;

interface Drawer
{
    void draw() const;
}

abstract class Ticker
{
package(zyeware.ticker):
    bool mIsFreeQueued;
    TickerManager mManager;

protected:
    pragma(inline, true)
    TickerManager manager() @safe pure nothrow => mManager;

public:
    this(TickerManager manager)
    {
        mManager = manager;
    }

    void onAdd() {}
    void onRemove() {}

    void preTick(in FrameTime frameTime) {}
    abstract void tick(in FrameTime frameTime);
    void postTick(in FrameTime frameTime) {}

    void free() @safe nothrow
    {
        mIsFreeQueued = true;
    }

    final bool isFreeQueued() @safe pure nothrow => mIsFreeQueued;
}
