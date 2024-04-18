// This file is part of the ZyeWare Game Engine, and subject to the terms
// and conditions defined in the file 'LICENSE.txt', which is part
// of this source code package.
//
// Copyright © 2021-2024 ZyeByte. All rights reserved.
module zyeware.subsystems.audio.source;

import soloud;

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

public:
    SoundHandle play(float volume = 1f, float pan = 0f)
    {
        return SoundHandle(Soloud_playEx(AudioSubsystem.sEngine, mSound, volume, pan, 0, 0));
    }
    
    SoundHandle play3d(vec3 position, vec3 velocity, float volume = 1f)
    {
        return SoundHandle(Soloud_play3dEx(AudioSubsystem.sEngine, mSound, position.x, position.y, position.z,
            velocity.x, velocity.y, velocity.z, volume, 0, 0));
    }

    abstract void stop();

    abstract double loopPoint() nothrow;
    abstract double loopPoint(double value) nothrow;
}

struct SoundHandle
{
private:
    uint mHandle;

public:
    int seek(double seconds) => Soloud_seek(AudioSubsystem.sEngine, mHandle, seconds);
    void stop() => Soloud_stop(AudioSubsystem.sEngine, mHandle);
}

@asset(Yes.cache)
class Sound : AudioSource
{
public:
    this(ubyte[] data, SoundProperties properties = SoundProperties.init)
    {
        mSound = Wav_create();
        Wav_loadMemEx(mSound, data.ptr, cast(uint) data.length, false, false);
        
        Wav_setLooping(mSound, properties.isLooping);
        Wav_setLoopPoint(mSound, properties.loopPoint);
    }

    ~this()
    {
        Wav_destroy(mSound);
    }

    override void stop() => Wav_stop(mSound);

    override double loopPoint() nothrow => Wav_getLoopPoint(mSound);
    override double loopPoint(double value) nothrow
    {
        Wav_setLoopPoint(mSound, value);
        return value;
    }

    /// Loads a sound from a given Files path.
    /// Params:
    ///   path = The path inside the Files.
    /// Returns: A newly created `Sound` instance.
    /// Throws: `VfsException` if the given file can't be loaded.
    static Sound load(string path)
    {
        // The daemons are the best community!

        File source = Files.open(path);
        ubyte[] rawFileData = source.readAll!(ubyte[])();
        source.close();

        SoundProperties properties;

        immutable string propsPath = path ~ ".props";
        if (Files.hasFile(propsPath)) // Properties file exists
            parseSoundProperties(propsPath, properties);

        Logger.core.debug_("Loaded sound '%s'.", path);

        return new Sound(rawFileData, properties);
    }
}

private:

void parseSoundProperties(string path, out SoundProperties properties)
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