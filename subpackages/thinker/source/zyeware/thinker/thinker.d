// This file is part of the ZyeWare Game Engine, and subject to the terms
// and conditions defined in the file 'LICENSE.txt', which is part
// of this source code package.
//
// Copyright © 2021-2024 ZyeByte. All rights reserved.
module zyeware.thinker.thinker;

import zyeware;
import zyeware.thinker;

interface Drawer
{
    void draw() const;
}

abstract class Thinker
{
package(zyeware.thinker):
    bool mIsFreeQueued;
    ThinkerManager mManager;

protected:
    pragma(inline, true)
    ThinkerManager manager() @safe pure nothrow => mManager;

public:
    this(ThinkerManager manager)
    {
        mManager = manager;
    }

    void preTick(in FrameTime frameTime) {}
    abstract void tick(in FrameTime frameTime);
    void postTick(in FrameTime frameTime) {}

    void free() @safe nothrow
    {
        mIsFreeQueued = true;
    }

    final bool isFreeQueued() @safe pure nothrow
    {
        return mIsFreeQueued;
    }
}
