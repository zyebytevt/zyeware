// This file is part of the ZyeWare Game Engine, and subject to the terms
// and conditions defined in the file 'LICENSE.txt', which is part
// of this source code package.
//
// Copyright 2021 ZyeByte
module zyeware.audio.source;

import zyeware;
import zyeware.pal.pal;

/// Represents an individual source that can play sounds. Only one sound
/// can play at a time.
class AudioSource : NativeObject
{
protected:
    NativeHandle mNativeHandle;
    AudioBuffer mBuffer;

public:
    this(in AudioBus bus)
        in (bus, "Audio bus must be valid.")
    {
        mNativeHandle = Pal.audio.createSource(bus.handle);
    }

    /// Starts playback, or resumes if the source has been paused previously.
    void play()
    {
        Pal.audio.playSource(mNativeHandle);
    }

    /// Pauses playback. If playback wasn't started, nothing happens.
    void pause()
    {
        Pal.audio.pauseSource(mNativeHandle);
    }

    /// Stops playback completely. If playback wasn't started, nothing happens.
    void stop()
    {
        Pal.audio.stopSource(mNativeHandle);
    }

    /// The `Sound` instance assigned to this source.
    inout(AudioBuffer) buffer() inout
    {
        return mBuffer;
    }
    
    /// ditto
    void buffer(AudioBuffer value)
    {
        mBuffer = value;
        Pal.audio.setSourceBuffer(mNativeHandle, value.handle);
    }

    /// Determines whether the source is looping it's sound. The loop point is defined by
    /// the assigned `Sound`.
    bool looping() const nothrow
    {
        return Pal.audio.isSourceLooping(mNativeHandle);
    }

    /// ditto
    void looping(bool value)
    {
        Pal.audio.setSourceLooping(mNativeHandle, value);
    }

    /// The volume of this source, ranging from 0 to 1.
    float volume() const nothrow
    {
        return Pal.audio.getSourceVolume(mNativeHandle);
    }

    /// ditto
    void volume(float value)
    {
        Pal.audio.setSourceVolume(mNativeHandle, value);
    }

    /// The pitch of this source, ranging from 0 to 1.
    /// This controls pitch as well as speed.
    float pitch() const nothrow
    {
        return Pal.audio.getSourcePitch(mNativeHandle);
    }

    /// ditto
    void pitch(float value)
    {
        Pal.audio.setSourcePitch(mNativeHandle, value);
    }

    /// The state this source is currently in.
    SourceState state() const nothrow
    {
        return Pal.audio.getSourceState(mNativeHandle);
    }

    const(NativeHandle) handle() pure const nothrow
    {
        return mNativeHandle;
    }
}