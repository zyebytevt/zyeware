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
import zyeware.audio.thread;

class AudioSource
{
private:
    static const(ubyte)[] sEmptyData = new ubyte[0];

protected:
    enum State
    {
        stopped,
        paused,
        playing
    }

    // TODO: Add engine-wide buffer size settings
    enum bufferSize = 4096 * 4;
    enum bufferCount = 4;

    float[] mProcBuffer;

    AudioStream mAudioStream;
    AudioDecoder mDecoder;
    uint mSourceId;
    uint[] mBufferIDs;
    int mProcessed;

    State mState;
    bool mLooping; // TODO: Maybe add loop point?
    AudioBus mBus;

package(zyeware):
    void updateBuffers()
    {
        if (mState == State.stopped)
            return;

        long lastReadLength;
        int processed;
        uint pBuf;
        alGetSourcei(mSourceId, AL_BUFFERS_PROCESSED, &processed);

        while (processed--)
        {
            alSourceUnqueueBuffers(mSourceId, 1, &pBuf);

            lastReadLength = mDecoder.read(mProcBuffer);

            if (lastReadLength <= 0)
            {
                if (mLooping)
                {
                    mDecoder.seekTo(0); // TODO: Replace with a loop point
                    lastReadLength = mDecoder.read(mProcBuffer);
                }
                else
                    break;
            }

            alBufferData(pBuf, mDecoder.channels == 1 ? AL_FORMAT_MONO_FLOAT32 : AL_FORMAT_STEREO_FLOAT32,
                &mProcBuffer[0], cast(int) (lastReadLength * float.sizeof), cast(int) mDecoder.sampleRate);

            alSourceQueueBuffers(mSourceId, 1, &pBuf);
        }

        int buffersQueued;
        alGetSourcei(mSourceId, AL_BUFFERS_QUEUED, &buffersQueued);
        if (buffersQueued == 0)
            stop();
    }

public:
    this(AudioBus bus = null)
    {
        mBus = bus ? bus : AudioAPI.getBus("master");

        mProcBuffer = new float[bufferSize];
        mBufferIDs = new uint[bufferCount];

        alGenSources(1, &mSourceId);
        alGenBuffers(cast(int) mBufferIDs.length, &mBufferIDs[0]);

        AudioThread.register(this);
    }

    ~this()
    {
        AudioThread.unregister(this);

        destroy!false(mDecoder);

        alDeleteBuffers(cast(int) mBufferIDs.length, &mBufferIDs[0]);
        alDeleteSources(1, &mSourceId);
    }

    void play()
    {
        if (mState == State.playing)
            stop();

        if (mState == State.stopped)
        {
            long lastReadLength;
            for (size_t i; i < bufferCount; ++i)
            {
                lastReadLength = mDecoder.read(mProcBuffer);
                alBufferData(mBufferIDs[i], mDecoder.channels == 1 ? AL_FORMAT_MONO_FLOAT32 : AL_FORMAT_STEREO_FLOAT32,
                    &mProcBuffer[0], cast(int) (lastReadLength * float.sizeof), cast(int) mDecoder.sampleRate);
                alSourceQueueBuffers(mSourceId, 1, &mBufferIDs[i]);
            }
        }

        mState = State.playing;
        alSourcePlay(mSourceId);
    }

    void pause()
    {
        mState = State.paused;
        alSourcePause(mSourceId);
    }

    void stop()
    {
        mState = State.stopped;
        alSourceStop(mSourceId);

        mDecoder.seekTo(0);

        int bufferCount;
        alGetSourcei(mSourceId, AL_BUFFERS_QUEUED, &bufferCount);
        
        for (size_t i; i < bufferCount; ++i)
        {
            uint removedBuffer;
            alSourceUnqueueBuffers(mSourceId, 1, &removedBuffer);
        }
    }

    inout(AudioStream) stream() inout nothrow
    {
        return mAudioStream;
    }

    void stream(AudioStream value)
    {
        if (mState != State.stopped)
            stop();

        mAudioStream = value;
        mDecoder.setData(mAudioStream.encodedMemory);
    }
}

/*
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
}*/