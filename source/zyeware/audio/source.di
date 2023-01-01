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
protected:
    uint mId;
    float mSelfVolume = 1f;
    AudioBus mBus;

    this(AudioBus bus);

public:
    Vector3f position() const nothrow;
    void position(Vector3f value) nothrow;
    float volume() const nothrow;

    void volume(float value) nothrow;

    abstract void play() nothrow;
    abstract void pause() nothrow;
    abstract void stop() nothrow;

    abstract bool loop() nothrow;
    abstract void loop(bool value) nothrow;
}

class AudioSampleSource : AudioSource
{
protected:
    Sound mBuffer;

public:
    this(AudioBus bus);

    void buffer(Sound value) nothrow;
    Sound buffer() nothrow;

    override void play() nothrow;
    override void pause() nothrow;
    override void stop() nothrow;
    override bool loop() nothrow;
    override void loop(bool value) nothrow;
}