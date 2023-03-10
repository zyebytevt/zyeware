// This file is part of the ZyeWare Game Engine, and subject to the terms
// and conditions defined in the file 'LICENSE.txt', which is part
// of this source code package.
//
// Copyright 2021 ZyeByte
module zyeware.audio.openal.source;

version (ZW_OpenAL):
package(zyeware.audio.openal):

import std.exception : enforce;
import std.algorithm : clamp;
import std.sumtype : match;
import std.math : isNaN;

import bindbc.openal;
import audioformats;

import zyeware.common;
import zyeware.audio;
import zyeware.audio.thread;

class OALAudioSource : AudioSource
{
private:
    /// Loads up `mProcBuffer` and returns the amount of samples read.
    pragma(inline, true)
    size_t readFromDecoder() @nogc
        in (mDecoder.isOpenForReading(), "Tried to decode while decoder is not open for reading.")
    {
        size_t readCount = mDecoder.readSamplesFloat(&mTempProcBuffer[0], cast(int)(mTempProcBuffer.length/mDecoder.getNumChannels()))
            * mDecoder.getNumChannels();

        for (size_t i; i < readCount; ++i)
            mRealProcBuffer[i] = cast(short) (mTempProcBuffer[i] * short.max);

        return readCount;
    }

protected:
    // TODO: Decoder sucks, replace with a better one soonish.
    float[] mTempProcBuffer;
    short[] mRealProcBuffer;

    Sound mSound;
    AudioStream mDecoder;
    uint mSourceId;
    uint[] mBufferIDs;
    int mProcessed;

    State mState;
    float mVolume = 1f;
    float mPitch = 1f;
    bool mLooping;
    AudioBus mBus;

package(zyeware.audio.openal):
    this(AudioBus bus)
    {
        mState = State.stopped;
        mBus = bus ? bus : AudioAPI.getBus("master");

        mTempProcBuffer = new float[ZyeWare.projectProperties.audioBufferSize];
        mRealProcBuffer = new short[mTempProcBuffer.length];
        mBufferIDs = new uint[ZyeWare.projectProperties.audioBufferCount];

        alGenSources(1, &mSourceId);
        alGenBuffers(cast(int) mBufferIDs.length, &mBufferIDs[0]);

        AudioThread.register(this);

        updateVolume();
    }

public:
    ~this()
    {
        if (mDecoder.isOpenForReading())
            destroy!false(mDecoder);

        alDeleteBuffers(cast(int) mBufferIDs.length, &mBufferIDs[0]);
        alDeleteSources(1, &mSourceId);

        dispose(mTempProcBuffer);
        dispose(mBufferIDs);
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
                    mDecoder.getNumChannels() == 1 ? AL_FORMAT_MONO16 : AL_FORMAT_STEREO16,
                    &mRealProcBuffer[0], cast(int) (lastReadLength * short.sizeof), cast(int) mDecoder.getSamplerate());
                
                alSourceQueueBuffers(mSourceId, 1, &mBufferIDs[i]);
            }
        }

        mState = State.playing;
        alSourcePlay(mSourceId);
    }

    void pause()
    {
        if (mState != State.playing)
            return;

        mState = State.paused;
        alSourcePause(mSourceId);
    }

    void stop()
    {
        if (mState == State.stopped)
            return;

        mState = State.stopped;
        alSourceStop(mSourceId);

        if (mDecoder.isOpenForReading())
            mDecoder.seekPosition(0);

        int bufferCount;
        alGetSourcei(mSourceId, AL_BUFFERS_QUEUED, &bufferCount);
        
        for (size_t i; i < bufferCount; ++i)
        {
            uint removedBuffer;
            alSourceUnqueueBuffers(mSourceId, 1, &removedBuffer);
        }
    }

    inout(Sound) sound() inout nothrow
    {
        return mSound;
    }

    void sound(Sound value)
        in (value, "Sound cannot be null.")
    {
        if (mState != State.stopped)
            stop();

        mSound = value;
        
        try 
        {
            mDecoder.openFromMemory(mSound.encodedMemory);
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

    State state() pure const nothrow
    {
        return mState;
    }

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
                    mSound.loopPoint.match!(
                        (int sample)
                        {
                            //enforce!AudioException(!mDecoder.isModule, "Cannot seek by sample in tracker files.");
                            
                            if (!mDecoder.seekPosition(sample))
                                Logger.core.log(LogLevel.warning, "Seeking to sample %d failed.", sample);
                        },
                        (ModuleLoopPoint mod)
                        {
                            //enforce!AudioException(mDecoder.isModule, "Cannot seek by pattern/row in non-tracker files.");

                            if (!mDecoder.seekPosition(mod.pattern, mod.row))
                                Logger.core.log(LogLevel.warning, "Seeking to pattern %d, row %d failed.", mod.pattern, mod.row);
                        }
                    );

                    lastReadLength = readFromDecoder();
                }
                else
                    break;
            }

            alBufferData(pBuf, mDecoder.getNumChannels() == 1 ? AL_FORMAT_MONO16 : AL_FORMAT_STEREO16,
                &mRealProcBuffer[0], cast(int) (lastReadLength * short.sizeof), cast(int) mDecoder.getSamplerate());

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
}