// This file is part of the ZyeWare Game Engine, and subject to the terms
// and conditions defined in the file 'LICENSE.txt', which is part
// of this source code package.
//
// Copyright 2021 ZyeByte
module zyeware.thinker.manager;

import std.algorithm : remove;

import zyeware.thinker;

struct ThinkerManager {
private:
    Thinkable[] mThinkers;

    size_t[] mQueuedRemovals;
    Thinkable[] mQueuedAdditions;

public:
    void add(Thinkable thinker) nothrow {
        mQueuedAdditions ~= thinker;
    }

    void remove(Thinkable thinker) nothrow {
        for (size_t i; i < mThinkers.length; ++i) {
            if (mThinkers[i] is thinker) {
                mQueuedRemovals ~= i;
                return;
            }
        }
    }

    void tick() {
        for (size_t i; i < mThinkers.length; ++i) {
            Thinkable thinker = mThinkers[i];

            thinker.tick();

            if (thinker.isFreeQueued) {
                mQueuedRemovals ~= i;
            }
        }

        if (mQueuedRemovals.length > 0) {
            foreach (size_t i; mQueuedRemovals) {
                mThinkers = mThinkers.remove(i);
            }
            mQueuedRemovals.length = 0;
        }

        if (mQueuedAdditions.length > 0) {
            foreach (Thinkable thinker; mQueuedAdditions) {
                mThinkers ~= thinker;
            }
            mQueuedAdditions.length = 0;
        }
    }

    void draw() const {
        for (size_t i; i < mThinkers.length; i++) {
            if (auto thinker = cast(Drawable) mThinkers[i]) {
                thinker.draw();
            }
        }
    }

    const(Thinkable[]) thinkers() const pure nothrow {
        return mThinkers;
    }
}
