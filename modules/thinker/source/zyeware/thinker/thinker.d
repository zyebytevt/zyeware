// This file is part of the ZyeWare Game Engine, and subject to the terms
// and conditions defined in the file 'LICENSE.txt', which is part
// of this source code package.
//
// Copyright 2024 ZyeByte
module zyeware.thinker.thinker;

interface Drawer
{
    void draw() const;
}

abstract class Thinker
{
package(zyeware.thinker):
    bool mIsFreeQueued;

public:
    abstract void tick();

    void free() @safe nothrow
    {
        mIsFreeQueued = true;
    }

    final bool isFreeQueued() @safe pure nothrow
    {
        return mIsFreeQueued;
    }
}
