// This file is part of the ZyeWare Game Engine, and subject to the terms
// and conditions defined in the file 'LICENSE.txt', which is part
// of this source code package.
//
// Copyright © 2021-2024 ZyeByte. All rights reserved.
module zyeware.audio.bus;

import std.algorithm : clamp;

import zyeware;

/// Controls the mixing of various sounds which are assigned to this audio bus, 
class AudioBus
{
private:
    static AudioBus[string] sAudioBuses;

    this(string name)
    {
        mName = name;
    }

protected:
    string mName;
    float mVolume = 1f;

public:
    ~this()
    {
        sAudioBuses.remove(mName);
    }

    /// The name of this audio bus, as registered in the audio subsystem.
    string name() const nothrow => mName;

    /// The volume of this audio bus, ranging from 0 to 1.
    float volume() const nothrow => mVolume;

    /// ditto
    void volume(float value)
    {
        mVolume = clamp(value, 0.0f, 1.0f);
        // TODO: Update all volumes
    }

    static AudioBus create(string name)
    {
        return sAudioBuses[name] = new AudioBus(name);
    }

    static void remove(string name)
    {
        auto bus = name in sAudioBuses;
        if (bus)
        {
            sAudioBuses.remove(name);
            destroy(*bus);
        }
    }

    static AudioBus get(string name) nothrow
    {
        auto bus = name in sAudioBuses;
        return bus ? *bus : null;
    }
}
