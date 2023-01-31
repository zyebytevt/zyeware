// This file is part of the ZyeWare Game Engine, and subject to the terms
// and conditions defined in the file 'LICENSE.txt', which is part
// of this source code package.
//
// Copyright 2021 ZyeByte
module zyeware.audio.bus;

import std.algorithm : clamp;

import zyeware.common;
import zyeware.audio.thread;

/// Controls the mixing of various sounds which are assigned to this audio bus, 
class AudioBus
{
protected:
    string mName;
    float mVolume = 1;

public:
    /// Params:
    ///   name = The name of this audio bus.
    this(string name) pure nothrow
    {
        mName = name;
    }
    
    /// The name of this audio bus, as registered in the audio subsystem.
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
    void volume(float value)
    {
        mVolume = clamp(value, 0.0f, 1.0f);
        AudioThread.updateVolumeForSources();
    }
}