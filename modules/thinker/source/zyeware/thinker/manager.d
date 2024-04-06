// This file is part of the ZyeWare Game Engine, and subject to the terms
// and conditions defined in the file 'LICENSE.txt', which is part
// of this source code package.
//
// Copyright © 2021-2024 ZyeByte. All rights reserved.
module zyeware.thinker.manager;

import std.algorithm : remove;

import zyeware.thinker;

struct ThinkerManager
{
private:
    Thinker[] mThinkers;

    size_t[] mQueuedRemovals;
    Thinker[] mQueuedAdditions;

public:
    void add(Thinker thinker) nothrow
    {
        mQueuedAdditions ~= thinker;
    }

    void remove(Thinker thinker) nothrow
    {
        for (size_t i; i < mThinkers.length; ++i)
        {
            if (mThinkers[i] is thinker)
            {
                mQueuedRemovals ~= i;
                return;
            }
        }
    }

    void tick()
    {
        for (size_t i; i < mThinkers.length; ++i)
        {
            Thinker thinker = mThinkers[i];

            thinker.tick();

            if (thinker.mIsFreeQueued)
                mQueuedRemovals ~= i;
        }

        if (mQueuedRemovals.length > 0)
        {
            foreach (size_t i; mQueuedRemovals)
                mThinkers = mThinkers.remove(i);

            mQueuedRemovals.length = 0;
        }

        if (mQueuedAdditions.length > 0)
        {
            foreach (Thinker thinker; mQueuedAdditions)
                mThinkers ~= thinker;

            mQueuedAdditions.length = 0;
        }
    }

    void draw() const
    {
        for (size_t i; i < mThinkers.length; i++)
        {
            if (auto thinker = cast(Drawer) mThinkers[i])
                thinker.draw();
        }
    }

    const(Thinker[]) thinkers() pure const nothrow => mThinkers;
}
