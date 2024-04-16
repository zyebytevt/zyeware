// This file is part of the ZyeWare Game Engine, and subject to the terms
// and conditions defined in the file 'LICENSE.txt', which is part
// of this source code package.
//
// Copyright © 2021-2024 ZyeByte. All rights reserved.
module zyeware.audio.source;

import std.sumtype : SumType, match;
import std.algorithm : clamp;

import bindbc.openal;
import audioformats;

import zyeware;

/// Contains information about a loop point for a module sound file.
struct ModuleLoopPoint
{
    int pattern; /// The pattern to loop from.
    int row; /// The row to loop from.
}

/// Represents an audio sample position.
alias Sample = int;

/// A SumType for a loop point, containing either a sample position (`int`) or
/// pattern and row (`ModuleLoopPoint`).
alias LoopPoint = SumType!(Sample, ModuleLoopPoint);

/// Contains various data for Sound initialisation.
struct AudioProperties
{
    LoopPoint loopPoint = LoopPoint(0); /// The point to loop at. It differentiates between a sample or pattern & row (for modules)
}

/// Represents an individual source that can play sounds. Only one sound
/// can play at a time.
class AudioSource
{
protected:
    AudioBuffer mBuffer;

    uint mId;
    uint[] mBufferIds;
    short[] mProcessing;
    int mProcessedCount;

    float mVolume = 1f;
    float mPitch = 1f;
    bool mIsLooping;

    State mState;

    AudioStream mDecoder;
    const(AudioBus) mBus;

package(zyeware.audio):
    void update() nothrow
    {
        if (mState != State.playing)
            return;

        int processedCount;
        alGetSourcei(mId, AL_BUFFERS_PROCESSED, &processedCount);

        if (processedCount == 0)
            return;

        int bufferCount;
        alGetSourcei(mId, AL_BUFFERS_QUEUED, &bufferCount);

        while (processedCount > 0)
        {
            uint removedBuffer;
            alSourceUnqueueBuffers(mId, 1, &removedBuffer);

            size_t lastReadLength = readShortsFromDecoder(mDecoder, mProcessing);

            if (lastReadLength <= 0)
            {
                if (mIsLooping)
                {
                    mBuffer.loopPoint.match!((int sample) {
                        if (!mDecoder.seekPosition(sample))
                            Logger.core.warning("Seeking to sample %d failed.", sample);
                    }, (ModuleLoopPoint mod) {
                        if (!mDecoder.seekPosition(mod.pattern, mod.row))
                            Logger.core.warning("Seeking to pattern %d, row %d failed.",
                                mod.pattern, mod.row);
                    });

                    lastReadLength = readShortsFromDecoder(mDecoder, mProcessing);
                }
                else
                {
                    stop();
                    return;
                }
            }

            alBufferData(removedBuffer, mDecoder.getNumChannels() == 1 ? AL_FORMAT_MONO16
                    : AL_FORMAT_STEREO16, &mProcessing[0],
                cast(int)(lastReadLength * short.sizeof), cast(int) mDecoder.getSamplerate());

            alSourceQueueBuffers(mId, 1, &removedBuffer);

            --processedCount;
        }
    }

public:
    /// Represents what state the audio source is currently in.
    enum State
    {
        stopped, /// Currently no playback.
        paused, /// Playback was paused and can be resumed.
        playing /// Currently playing audio.
    }

    this(in AudioBus bus)
    in (bus, "Audio bus must be valid.")
    {
        mBus = bus;
        mBufferIds = new uint[audioBufferCount];
        mProcessing = new short[audioBufferSize];

        alGenSources(1, &mId);
        alGenBuffers(cast(uint) mBufferIds.length, &mBufferIds[0]);
        alSourcef(mId, AL_GAIN, mVolume * mBus.volume);

        AudioApi.registerSource(this);
    }

    ~this()
    {
        if (mDecoder.isOpenForReading())
            destroy!false(mDecoder);

        alDeleteBuffers(cast(uint) mBufferIds.length, &mBufferIds[0]);
        alDeleteSources(1, &mId);

        destroy(mBufferIds);
        destroy(mProcessing);

        AudioApi.unregisterSource(this);
    }

    /// Starts playback, or resumes if the source has been paused previously.
    void play()
    {
        if (mState == State.playing)
            stop();

        if (mState == State.stopped)
        {
            size_t lastReadLength;
            for (size_t i; i < mBufferIds.length; ++i)
            {
                lastReadLength = readShortsFromDecoder(mDecoder, mProcessing);

                alBufferData(mBufferIds[i], mDecoder.getNumChannels() == 1
                        ? AL_FORMAT_MONO16 : AL_FORMAT_STEREO16, &mProcessing[0],
                    cast(int)(lastReadLength * short.sizeof), cast(int) mDecoder.getSamplerate());

                alSourceQueueBuffers(mId, 1, &mBufferIds[i]);
            }
        }

        mState = State.playing;
        alSourcePlay(mId);
    }

    /// Pauses playback. If playback wasn't started, nothing happens.
    void pause() nothrow
    {
        if (mState != State.playing)
            return;

        mState = State.paused;
        alSourcePause(mId);
    }

    /// Stops playback completely. If playback wasn't started, nothing happens.
    void stop() nothrow
    {
        if (mState == State.stopped)
            return;

        mState = State.stopped;
        alSourceStop(mId);

        if (mDecoder.isOpenForReading())
            mDecoder.seekPosition(0);

        int bufferCount;
        alGetSourcei(mId, AL_BUFFERS_QUEUED, &bufferCount);

        for (size_t i; i < bufferCount; ++i)
        {
            uint removedBuffer;
            alSourceUnqueueBuffers(mId, 1, &removedBuffer);
        }
    }

    /// The `Sound` instance assigned to this source.
    inout(AudioBuffer) buffer() inout => mBuffer;

    /// ditto
    void buffer(AudioBuffer value)
    {
        mBuffer = value;
        
        if (mState != State.stopped)
            stop();

        mDecoder.openFromMemory(mBuffer.data);
        enforce!AudioException(mDecoder.isError, mDecoder.errorMessage);
    }

    /// Determines whether the source is looping it's sound. The loop point is defined by
    /// the assigned `Sound`.
    bool isLooping() const nothrow => mIsLooping;

    /// ditto
    bool isLooping(bool value) => mIsLooping = value;

    /// The volume of this source, ranging from 0 to 1.
    float volume() const nothrow => mVolume;

    /// ditto
    float volume(float value)
    {
        mVolume = clamp(value, 0, 1);
        alSourcef(mId, AL_GAIN, mVolume * mBus.volume);
        return mVolume;
    }

    /// The pitch of this source, ranging from 0 to 1.
    /// This controls pitch as well as speed.
    float pitch() const nothrow => mPitch;

    /// ditto
    void pitch(float value)
    {
        mPitch = clamp(value, 0, 1);
        alSourcef(mId, AL_PITCH, mPitch);
    }

    /// The state this source is currently in.
    State state() const nothrow => mState;
}

private:

// This function is essentially noGC, but it's not marked as such because the array
// is initialized the first time the function is called.
size_t readShortsFromDecoder(ref AudioStream decoder, ref short[] buffer) nothrow
in (decoder.isOpenForReading(), "Tried to decode while decoder is not open for reading.")
{
    // TODO: Can't this be a static array?
    static float[] readBuffer;
    if (!readBuffer)
        readBuffer = new float[audioBufferSize];

    size_t readCount = decoder.readSamplesFloat(&readBuffer[0],
        cast(int)(readBuffer.length / decoder.getNumChannels())) * decoder.getNumChannels();

    for (size_t i; i < readCount; ++i)
        buffer[i] = cast(short)(readBuffer[i] * short.max);

    return readCount;
}