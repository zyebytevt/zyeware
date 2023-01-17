// This file is part of the ZyeWare Game Engine, and subject to the terms
// and conditions defined in the file 'LICENSE.txt', which is part
// of this source code package.
//
// Copyright 2021 ZyeByte
module zyeware.audio.source;

import std.exception : enforce;
import std.algorithm : clamp;
import std.sumtype : match;
import std.math : isNaN;

import bindbc.openal;
import audioformats;

import zyeware.common;
import zyeware.audio;
import zyeware.audio.thread;

class AudioSource
{
private:
    /// Loads up `mProcBuffer` and returns the amount of samples read.
    pragma(inline, true)
    size_t readFromDecoder() 
    {
        return mDecoder.readSamplesFloat(&mProcBuffer[0], cast(int)(mProcBuffer.length/mDecoder.getNumChannels()))
            * mDecoder.getNumChannels();
    }

protected:
    enum State
    {
        stopped,
        paused,
        playing
    }

    float[] mProcBuffer;

    Audio mAudioStream;
    AudioStream mDecoder;
    uint mSourceId;
    uint[] mBufferIDs;
    int mProcessed;

    State mState;
    float mVolume = 1;
    float mPitch = 1;
    bool mLooping;
    AudioBus mBus;

package(zyeware):
    final void updateBuffers()
    {
        if (mState == State.stopped)
            return;

        size_t lastReadLength;
        int processed;
        uint pBuf;
        alGetSourcei(mSourceId, AL_BUFFERS_PROCESSED, &processed);

        while (processed--)
        {
            alSourceUnqueueBuffers(mSourceId, 1, &pBuf);

            lastReadLength = readFromDecoder();

            if (lastReadLength <= 0)
            {
                if (mLooping)
                {
                    mAudioStream.loopPoint.match!(
                        (int sample)
                        {
                            enforce!AudioException(!mDecoder.isModule, "Cannot seek by sample in tracker files.");
                            
                            if (!mDecoder.seekPosition(sample))
                                Logger.core.log(LogLevel.warning, "Seeking to sample %d failed.", sample);
                        },
                        (ModuleLoopPoint mod)
                        {
                            enforce!AudioException(mDecoder.isModule, "Cannot seek by pattern/row in non-tracker files.");

                            if (!mDecoder.seekPosition(mod.pattern, mod.row))
                                Logger.core.log(LogLevel.warning, "Seeking to pattern %d, row %d failed.", mod.pattern, mod.row);
                        }
                    );

                    lastReadLength = readFromDecoder();
                }
                else
                    break;
            }

            alBufferData(pBuf, mDecoder.getNumChannels() == 1 ? AL_FORMAT_MONO_FLOAT32 : AL_FORMAT_STEREO_FLOAT32,
                &mProcBuffer[0], cast(int) (lastReadLength * float.sizeof), cast(int) mDecoder.getSamplerate());

            alSourceQueueBuffers(mSourceId, 1, &pBuf);
        }

        int buffersQueued;
        alGetSourcei(mSourceId, AL_BUFFERS_QUEUED, &buffersQueued);
        if (buffersQueued == 0)
            stop();
    }

    final void updateVolume() nothrow
    {
        alSourcef(mSourceId, AL_GAIN, mVolume * mBus.volume);
    }

public:
    this(AudioBus bus = null)
    {
        mBus = bus ? bus : AudioAPI.getBus("master");

        mProcBuffer = new float[ZyeWare.projectProperties.audioBufferSize];
        mBufferIDs = new uint[ZyeWare.projectProperties.audioBufferCount];

        alGenSources(1, &mSourceId);
        alGenBuffers(cast(int) mBufferIDs.length, &mBufferIDs[0]);

        AudioThread.register(this);

        updateVolume();
    }

    ~this()
    {
        if (mDecoder.isOpenForReading())
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
            for (size_t i; i < mBufferIDs.length; ++i)
            {
                lastReadLength = readFromDecoder();
                
                alBufferData(mBufferIDs[i],
                    mDecoder.getNumChannels() == 1 ? AL_FORMAT_MONO_FLOAT32 : AL_FORMAT_STEREO_FLOAT32,
                    &mProcBuffer[0], cast(int) (lastReadLength * float.sizeof), cast(int) mDecoder.getSamplerate());
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

        mDecoder.seekPosition(0);

        int bufferCount;
        alGetSourcei(mSourceId, AL_BUFFERS_QUEUED, &bufferCount);
        
        for (size_t i; i < bufferCount; ++i)
        {
            uint removedBuffer;
            alSourceUnqueueBuffers(mSourceId, 1, &removedBuffer);
        }
    }

    inout(Audio) audio() inout nothrow
    {
        return mAudioStream;
    }

    void audio(Audio value)
        in (value, "Audio cannot be null.")
    {
        if (mState != State.stopped)
            stop();

        mAudioStream = value;
        
        try 
        {
            mDecoder.openFromMemory(mAudioStream.encodedMemory);
        }
        catch (AudioFormatsException ex)
        {
            // Copy manually managed memory to GC memory and rethrow exception.
            string errMsg = ex.msg.dup;
            string errFile = ex.file.dup;
            size_t errLine = ex.line;
            destroyAudioFormatException(ex);

            throw new AudioException(errMsg, errFile, errLine, null);
        }
    }

    bool looping() pure const nothrow
    {
        return mLooping;
    }

    void looping(bool value) pure nothrow
    {
        mLooping = value;
    }

    float volume() pure const nothrow
    {
        return mVolume;
    }

    void volume(float value) nothrow
        in (!isNaN(value), "Cannot set NaN as a volume.")
    {
        mVolume = clamp(value, 0f, 1f);
        updateVolume();
    }

    float pitch() pure const nothrow
    {
        return mPitch;
    }

    void pitch(float value) nothrow
        in (!isNaN(value), "Cannot set NaN as a pitch.")
    {
        mPitch = value;
        alSourcef(mSourceId, AL_PITCH, mPitch);
    }
}