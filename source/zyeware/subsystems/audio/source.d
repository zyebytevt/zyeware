// This file is part of the ZyeWare Game Engine, and subject to the terms
// and conditions defined in the file 'LICENSE.txt', which is part
// of this source code package.
//
// Copyright © 2021-2024 ZyeByte. All rights reserved.
module zyeware.subsystems.audio.source;

import soloud;
import bindbc.soloud;

import zyeware;
import zyeware.subsystems.audio;

/// Contains various data for Sound initialisation.
struct SoundProperties
{
    bool isLooping; /// If the sound should loop.
    double loopPoint = 0.0; /// The point to loop at. It differentiates between a sample or pattern & row (for modules)
}

abstract class AudioSource
{
package:
    SoloudHandle mSound;
    // To keep them from being collected by GC
    AudioFilter[AudioSubsystem.maxFilters] mFilters;

public:
    enum InaudibleBehavior
    {
        /// The sound will be paused when it becomes inaudible.
        pause,
        /// The sound will be stopped when it becomes inaudible.
        stop,
        /// The sound will continue playing even when it becomes inaudible.
        continue_,
    }

    VoiceHandle play(AudioBus bus = null, float volume = 1f, float pan = 0f) nothrow
    {
        if (!bus)
            return VoiceHandle(Soloud_playEx(AudioSubsystem.sEngine, mSound, volume, pan, 0, 0));
        else
            return VoiceHandle(Bus_playEx(bus.mBus, mSound, volume, pan, 0));
    }
    
    VoiceHandle playClocked(AudioBus bus = null, float volume = 1f, float pan = 0f, double soundTime = 0.0) nothrow
    {
        if (!bus)
            return VoiceHandle(Soloud_playClockedEx(AudioSubsystem.sEngine, soundTime, mSound, volume, pan, 0));
        else
            return VoiceHandle(Bus_playClockedEx(bus.mBus, soundTime, mSound, volume, pan));
    }

    VoiceHandle play3d(vec3 position, vec3 velocity, AudioBus bus = null, float volume = 1f) nothrow
    {
        if (!bus)
            return VoiceHandle(Soloud_play3dEx(AudioSubsystem.sEngine, mSound, position.x, position.y, position.z,
                velocity.x, velocity.y, velocity.z, volume, 0, 0));
        else
            return VoiceHandle(Bus_play3dEx(bus.mBus, mSound, position.x, position.y, position.z,
                velocity.x, velocity.y, velocity.z, volume, 0));
    }

    VoiceHandle play3dClocked(vec3 position, vec3 velocity, AudioBus bus = null, float volume = 1f, double soundTime = 0.0) nothrow
    {
        if (!bus)
            return VoiceHandle(Soloud_play3dClockedEx(AudioSubsystem.sEngine, soundTime, mSound, position.x, position.y, position.z,
                velocity.x, velocity.y, velocity.z, volume, 0));
        else
            return VoiceHandle(Bus_play3dClockedEx(bus.mBus, soundTime, mSound, position.x, position.y, position.z,
                velocity.x, velocity.y, velocity.z, volume));
    }

    abstract void stop() nothrow;

    abstract void setDefaultVolume(float volume) nothrow;

    void setFilter(uint filterId, AudioFilter filter) nothrow
    in (filterId < AudioSubsystem.maxFilters, "Filter ID out of range.")
    {
        mFilters[filterId] = filter;
    }

    uint count() nothrow => Soloud_countAudioSource(AudioSubsystem.sEngine, mSound);
}

@asset(Yes.cache)
class SoundSample : AudioSource
{
protected:
    InaudibleBehavior mInaudibleBehavior = InaudibleBehavior.pause;

public:
    this(ubyte[] data, SoundProperties properties = SoundProperties.init)
    {
        mSound = Wav_create();
        immutable result = Wav_loadMemEx(mSound, data.ptr, cast(uint) data.length, false, false);
        enforce!AudioException(result == 0, "Failed to load sound sample.");
        
        Wav_setLooping(mSound, properties.isLooping);
        Wav_setLoopPoint(mSound, properties.loopPoint);
    }

    ~this() nothrow
    {
        Wav_destroy(mSound);
    }

    override void stop() nothrow => Wav_stop(mSound);

    override void setFilter(uint filterId, AudioFilter filter) nothrow
    {
        super.setFilter(filterId, filter);
        Wav_setFilter(mSound, filterId, filter.mFilter);
    }

    override void setDefaultVolume(float volume) nothrow => Wav_setVolume(mSound, volume);

    double loopPoint() nothrow => Wav_getLoopPoint(mSound);
    double loopPoint(double value) nothrow
    {
        Wav_setLoopPoint(mSound, value);
        return value;
    }

    InaudibleBehavior inaudibleBehavior() nothrow => mInaudibleBehavior;
    InaudibleBehavior inaudibleBehavior(InaudibleBehavior value) nothrow
    {
        mInaudibleBehavior = value;
        Wav_setInaudibleBehavior(mSound, value == InaudibleBehavior.continue_, value == InaudibleBehavior.stop);
        return value;
    }

    /// Loads a sound from a given Files path.
    /// Params:
    ///   path = The path inside the Files.
    /// Returns: A newly created `Sound` instance.
    /// Throws: `VfsException` if the given file can't be loaded.
    static SoundSample load(string path)
    {
        // The daemons are the best community!

        ubyte[] rawFileData;
        SoundProperties properties;

        loadDataWithProperties(path, rawFileData, properties);

        Logger.core.debug_("Loaded sound '%s'.", path);

        return new SoundSample(rawFileData, properties);
    }
}

@asset(Yes.cache)
class SoundStream : AudioSource
{
protected:
    // To keep it from being collected by GC
    ubyte[] mRawData;
    InaudibleBehavior mInaudibleBehavior = InaudibleBehavior.pause;

public:
    this(ubyte[] data, SoundProperties properties = SoundProperties.init)
    {
        mRawData = data;
        mSound = WavStream_create();
        immutable result = WavStream_loadMemEx(mSound, mRawData.ptr, cast(uint) mRawData.length, false, false);
        enforce!AudioException(result == 0, "Failed to load sound stream.");
        
        WavStream_setLooping(mSound, properties.isLooping);
        WavStream_setLoopPoint(mSound, properties.loopPoint);
    }

    ~this() nothrow
    {
        WavStream_destroy(mSound);
    }

    override void stop() nothrow => WavStream_stop(mSound);

    override void setDefaultVolume(float volume) nothrow => WavStream_setVolume(mSound, volume);

    override void setFilter(uint filterId, AudioFilter filter) nothrow
    {
        super.setFilter(filterId, filter);
        WavStream_setFilter(mSound, filterId, filter.mFilter);
    }

    double loopPoint() nothrow => WavStream_getLoopPoint(mSound);
    double loopPoint(double value) nothrow
    {
        WavStream_setLoopPoint(mSound, value);
        return value;
    }

    InaudibleBehavior inaudibleBehavior() nothrow => mInaudibleBehavior;
    InaudibleBehavior inaudibleBehavior(InaudibleBehavior value) nothrow
    {
        mInaudibleBehavior = value;
        WavStream_setInaudibleBehavior(mSound, value == InaudibleBehavior.continue_, value == InaudibleBehavior.stop);
        return value;
    }


    /// Loads a sound from a given Files path.
    /// Params:
    ///   path = The path inside the Files.
    /// Returns: A newly created `Sound` instance.
    /// Throws: `VfsException` if the given file can't be loaded.
    static SoundStream load(string path)
    {
        // The daemons are the best community!

        ubyte[] rawFileData;
        SoundProperties properties;

        loadDataWithProperties(path, rawFileData, properties);

        Logger.core.debug_("Loaded sound stream '%s'.", path);

        return new SoundStream(rawFileData, properties);
    }
}

private:

void loadDataWithProperties(string path, out ubyte[] data, out SoundProperties properties)
{
    File source = Files.open(path);
    scope (exit) source.close();
    data = source.readAll!(ubyte[])();

    immutable string propsPath = path ~ ".props";
    if (Files.hasFile(propsPath)) // Properties file exists
    {
        try
        {
            SDLNode* root = loadSdlDocument(path);

            if (SDLNode* loopNode = root.getChild("loop"))
            {
                properties.isLooping = loopNode.getValue!bool(false);
                properties.loopPoint = loopNode.getAttributeValue!double("loop-point", 0.0);
            }
        }
        catch (Exception ex)
        {
            Logger.core.warning("Failed to parse properties file for '%s': %s",
                path, ex.message);
        }
    }
}