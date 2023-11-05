// This file is part of the ZyeWare Game Engine, and subject to the terms
// and conditions defined in the file 'LICENSE.txt', which is part
// of this source code package.
//
// Copyright 2021 ZyeByte
module zyeware.audio.buffer;

import std.sumtype;

import zyeware.common;
import zyeware.audio;

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

/// Contains an encoded audio segment, plus various information like
/// loop point etc.
@asset(Yes.cache)
interface Sound
{
public:
    /// The point where this sound should loop, if played through an `AudioSource`.
    LoopPoint loopPoint() pure const nothrow;

    /// ditto
    void loopPoint(LoopPoint value) pure nothrow;

    /// The encoded audio data.
    const(ubyte)[] encodedMemory() pure nothrow;

    /// Creates a new sound buffer with the given data.
    /// Params:
    ///   encodedMemory = An array of unsigned bytes that contains the encoded audio data.
    ///   properties = Instance of an `AudioProperties` struct to initialize the Sound with.
    static Sound create(const(ubyte)[] encodedMemory, AudioProperties properties = AudioProperties.init)
    {
        return AudioAPI.sCreateSoundImpl(encodedMemory, properties);
    }

    /// Loads a sound from a given VFS path.
    /// Params:
    ///   path = The path inside the VFS.
    /// Returns: A newly created `Sound` instance.
    /// Throws: `VFSException` if the given file can't be loaded.
    static Sound load(string path)
    {
        return AudioAPI.sLoadSoundImpl(path);
    }
}