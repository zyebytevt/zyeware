// This file is part of the ZyeWare Game Engine, and subject to the terms
// and conditions defined in the file 'LICENSE.txt', which is part
// of this source code package.
//
// Copyright 2021 ZyeByte
module zyeware.audio.bus;

import std.algorithm : clamp;

import zyeware.common;

class AudioBus
{
protected:
    string mName;
    float mVolume = 1;

public:
    this(string name) pure nothrow
    {
        mName = name;
    }
    
    string name() const nothrow
    {
        return mName;
    }

    /// The volume of this audio bus, ranging from 0 to 1.
    float volume() const nothrow
    {
        return mVolume;
    }

    /// ditto
    void gain(float value) nothrow
    {
        mVolume = clamp(value, 0.0f, 1.0f);
    }
}