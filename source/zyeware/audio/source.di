// This file is part of the ZyeWare Game Engine, and subject to the terms
// and conditions defined in the file 'LICENSE.txt', which is part
// of this source code package.
//
// Copyright 2021 ZyeByte
module zyeware.audio.source;

import zyeware.common;
import zyeware.audio;

class AudioSource
{
package(zyeware):
    void updateBuffers();
    void updateVolume();

public:
    enum State
    {
        stopped,
        paused,
        playing
    }

    this(AudioBus bus = null);

    ~this();

    void play();
    void pause();
    void stop();

    inout(Audio) audio() pure inout nothrow;
    void audio(Audio value) pure nothrow;

    bool looping() pure const nothrow;
    void looping(bool value) pure nothrow;

    float volume() pure const nothrow;
    void volume(float value) nothrow;

    float pitch() pure const nothrow;
    void pitch(float value) nothrow;

    State state() pure const nothrow;
}