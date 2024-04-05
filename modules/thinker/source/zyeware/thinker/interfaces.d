// This file is part of the ZyeWare Game Engine, and subject to the terms
// and conditions defined in the file 'LICENSE.txt', which is part
// of this source code package.
//
// Copyright 2021 ZyeByte
module zyeware.thinker.interfaces;

interface Thinkable {
    void tick();
    void free();
    bool isFreeQueued() const;
}

interface Drawable {
    void draw() const;
}
