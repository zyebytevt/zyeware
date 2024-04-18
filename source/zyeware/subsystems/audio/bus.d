// This file is part of the ZyeWare Game Engine, and subject to the terms
// and conditions defined in the file 'LICENSE.txt', which is part
// of this source code package.
//
// Copyright © 2021-2024 ZyeByte. All rights reserved.
module zyeware.subsystems.audio.bus;

import soloud;
import bindbc.soloud;

import zyeware;
import zyeware.subsystems.audio;

class AudioBus
{
protected:
    string mName;

package:
    SoloudHandle mBus;
    // To keep them from being collected by GC
    AudioFilter[AudioSubsystem.maxFilters] mFilters;

    this(string name) nothrow
    {
        mBus = Bus_create();

        mName = name;
    }

public:
    ~this() nothrow
    {
        Bus_destroy(mBus);
    }

    void setFilter(uint filterId, AudioFilter filter) nothrow
    in (filterId < AudioSubsystem.maxFilters, "Filter ID out of range.")
    {
        mFilters[filterId] = filter;
        Bus_setFilter(mBus, filterId, filter.mFilter);
    }

    string name() const nothrow => mName;
}
