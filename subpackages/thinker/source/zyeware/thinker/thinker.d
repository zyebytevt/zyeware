// This file is part of the ZyeWare Game Engine, and subject to the terms
// and conditions defined in the file 'LICENSE.txt', which is part
// of this source code package.
//
// Copyright © 2021-2024 ZyeByte. All rights reserved.
module zyeware.thinker.thinker;

import zyeware;

interface Drawer
{
    void draw() const;
}

abstract class Thinker
{
package(zyeware.thinker):
    bool mIsFreeQueued;

public:
    abstract void tick(in FrameTime frameTime);

    void free() @safe nothrow
    {
        mIsFreeQueued = true;
    }

    final bool isFreeQueued() @safe pure nothrow
    {
        return mIsFreeQueued;
    }
}
