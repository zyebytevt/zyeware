// This file is part of the ZyeWare Game Engine, and subject to the terms
// and conditions defined in the file 'LICENSE.txt', which is part
// of this source code package.
//
// Copyright 2021 ZyeByte
module zyeware.audio.source;

import zyeware.common;
import zyeware.audio;

/// Represents an individual source that can play sounds. Only one sound
/// can play at a time.
class AudioSource
{
package(zyeware):
    void updateBuffers() @nogc;
    void updateVolume();

public:
    /// Represents what state the `AudioSource` is currently in.
    enum State
    {
        stopped, /// Currently no playback.
        paused, /// Playback was paused, `play()` resumes.
        playing /// Currently playing audio.
    }

    /// Params:
    ///   bus = The audio bus this source belongs to.
    this(AudioBus bus = null);

    ~this();

    /// Starts playback, or resumes if the source has been paused previously.
    void play();
    /// Pauses playback. If playback wasn't started, nothing happens.
    void pause();
    /// Stops playback completely. If playback wasn't started, nothing happens.
    void stop();

    /// The `Sound` instance assigned to this source.
    inout(Sound) sound() pure inout nothrow;
    
    /// ditto
    void sound(Sound value) pure nothrow;

    /// Determines whether the source is looping it's sound. The loop point is defined by
    /// the assigned `Sound`.
    bool looping() pure const nothrow;

    /// ditto
    void looping(bool value) pure nothrow;

    /// The volume of this source, ranging from 0 to 1.
    float volume() pure const nothrow;

    /// ditto
    void volume(float value) nothrow;

    /// The pitch of this source, ranging from 0 to 1.
    /// This controls pitch as well as speed.
    float pitch() pure const nothrow;

    /// ditto
    void pitch(float value) nothrow;

    /// The state this source is currently in.
    State state() pure const nothrow;
}