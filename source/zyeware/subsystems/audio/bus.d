// This file is part of the ZyeWare Game Engine, and subject to the terms
// and conditions defined in the file 'LICENSE.txt', which is part
// of this source code package.
//
// Copyright © 2021-2024 ZyeByte. All rights reserved.
module zyeware.subsystems.audio.bus;

import soloud;

import zyeware;
import zyeware.subsystems.audio;

class AudioBus
{
protected:
    SoloudHandle mBus;
    string mName;

package:
    this(string name)
    {
        mBus = Bus_create();

        mName = name;
    }

public:
    ~this()
    {
        Bus_destroy(mBus);
    }

    SoundHandle play(AudioSource source, float volume = 1f, float pan = 0f)
    {
        return SoundHandle(Bus_playEx(mBus, source.mSound, volume, pan, 0));
    }
    
    SoundHandle play3d(AudioSource source, vec3 position, vec3 velocity, float volume = 1f)
    {
        return SoundHandle(Bus_play3dEx(mBus, source.mSound, position.x, position.y, position.z,
            velocity.x, velocity.y, velocity.z, volume, 0));
    }

    string name() const nothrow => mName;
}
