// This file is part of the ZyeWare Game Engine, and subject to the terms
// and conditions defined in the file 'LICENSE.txt', which is part
// of this source code package.
//
// Copyright © 2021-2024 ZyeByte. All rights reserved.
module zyeware.audio.buffer;

import std.conv : to;

import zyeware;

/// Contains an encoded audio segment, plus various information like
/// loop point etc.
@asset(Yes.cache)
class AudioBuffer
{
protected:
    const(ubyte[]) mData;
    LoopPoint mLoopPoint;

public:
    this(const(ubyte)[] data, AudioProperties properties = AudioProperties.init)
    {
        mData = data;
        mLoopPoint = properties.loopPoint;
    }

    /// The point where this sound should loop, if played through an `AudioSource`.
    LoopPoint loopPoint() const nothrow => mLoopPoint;

    /// ditto
    LoopPoint loopPoint(LoopPoint value) => mLoopPoint = value;

    /// The encoded audio data.
    const(ubyte[]) data() => mData;

    /// Loads a sound from a given Files path.
    /// Params:
    ///   path = The path inside the Files.
    /// Returns: A newly created `Sound` instance.
    /// Throws: `VfsException` if the given file can't be loaded.
    static AudioBuffer load(string path)
    {
        // The daemons are the best community!

        File source = Files.open(path);
        ubyte[] rawFileData = source.readAll!(ubyte[])();
        source.close();

        AudioProperties properties;

        if (Files.hasFile(path ~ ".props")) // Properties file exists
        {
            try
            {
                SDLNode* root = loadSdlDocument(path ~ ".props");

                if (SDLNode* loopNode = root.getChild("loop"))
                {
                    if (SDLNode* sampleNode = loopNode.getChild("sample"))
                    {
                        properties.loopPoint = LoopPoint(sampleNode.expectValue!int());
                    }
                    else if (SDLNode* moduleNode = loopNode.getChild("module"))
                    {
                        properties.loopPoint = LoopPoint(ModuleLoopPoint(moduleNode.expectValue!int(),
                                moduleNode.expectChildValue!int("row")));
                    }
                    else
                        throw new ResourceException("Could not interpret loop point.");
                }
            }
            catch (Exception ex)
            {
                Logger.core.warning("Failed to parse properties file for '%s': %s",
                    path, ex.message);
            }
        }

        Logger.core.debug_("Loaded file '%s' into memory for streaming.", path);

        return new AudioBuffer(rawFileData, properties);
    }
}
