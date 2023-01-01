// This file is part of the ZyeWare Game Engine, and subject to the terms
// and conditions defined in the file 'LICENSE.txt', which is part
// of this source code package.
//
// Copyright 2021 ZyeByte
module zyeware.audio.source;

import std.algorithm : clamp;

import bindbc.openal;

import zyeware.common;
import zyeware.audio;

class AudioSource
{
protected:
    uint mId;
    float mSelfVolume = 1f;
    AudioBus mBus;

    this(AudioBus bus)
    {
        mBus = bus ? bus : AudioAPI.getBus("master");

        alGenSources(1, &mId);
    }

public:
    ~this()
    {
        alDeleteSources(1, &mId);
    }

    Vector3f position() const nothrow
    {
        float x, y, z;
        alGetSource3f(mId, AL_POSITION, &x, &y, &z);
        return Vector3f(x, y, z);
    }

    void position(Vector3f value) nothrow
    {
        alSource3f(mId, AL_POSITION, value.x, value.y, value.z);
    }

    float volume() const nothrow
    {
        return mSelfVolume;
    }

    void volume(float value) nothrow
    {
        mSelfVolume = clamp(value, 0.0f, 1.0f);
        //AudioServer._recalculateChannelGains(_audioBus);
    }

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
    this(AudioBus bus)
    {
        super(bus);
    }

    void buffer(Sound value) nothrow
    {
        stop();
        mBuffer = value;

        alSourcei(mId, AL_BUFFER, mBuffer ? mBuffer.id : 0);
    }

    Sound buffer() nothrow
    {
        return mBuffer;
    }

    override void play() nothrow
    {
        alSourcePlay(mId);
    }

    override void pause() nothrow
    {
        alSourcePause(mId);
    }

    override void stop() nothrow
    {
        alSourceStop(mId);
    }

    override bool loop() nothrow
    {
        int loopValue;
        alGetSourcei(mId, AL_LOOPING, &loopValue);
        return loopValue == AL_TRUE;
    }

    override void loop(bool value) nothrow
    {
        alSourcei(mId, AL_LOOPING, value);
    }
}