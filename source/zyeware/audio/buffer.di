// This file is part of the ZyeWare Game Engine, and subject to the terms
// and conditions defined in the file 'LICENSE.txt', which is part
// of this source code package.
//
// Copyright 2021 ZyeByte
module zyeware.audio.buffer;

import std.sumtype;

import zyeware.common;
import zyeware.audio;

deprecated("This was a joke.")
{
    /// Joke alias. Do not use in production.
    alias NoiseBitties = Sound;
    /// Joke alias. Do not use in production.
    alias AirVibrationData = Sound;
    /// Joke alias. Do not use in production.
    alias EarMassager = Sound;
    /// Joke alias. Do not use in production.
    alias SonicStream = Sound;
}

/// Contains an encoded audio segment, plus various information like
/// loop point etc.
@asset(Yes.cache)
class Sound
{
public:
    /// Params:
    ///   encodedMemory = An array of unsigned bytes that contains the encoded audio data.
    ///   properties = Instance of an `AudioProperties` struct to initialize the Sound with.
    this(const(ubyte)[] encodedMemory, AudioProperties properties = AudioProperties.init);

    /// The point where this sound should loop, if played through an `AudioSource`.
    LoopPoint loopPoint() pure const nothrow;

    /// ditto
    void loopPoint(LoopPoint value) pure nothrow;

    /// The encoded audio data.
    const(ubyte)[] encodedMemory() pure nothrow;

    /// Loads a sound from a given VFS path.
    /// Params:
    ///   path = The path inside the VFS.
    /// Returns: A newly created `Sound` instance.
    /// Throws: `VFSException` if the given file can't be loaded.
    static Sound load(string path);
}