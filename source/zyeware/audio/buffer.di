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

@asset(Yes.cache)
class Sound
{
public:
    this(const(ubyte)[] encodedMemory, AudioProperties properties = AudioProperties.init);

    LoopPoint loopPoint() pure const nothrow;

    void loopPoint(LoopPoint value) pure nothrow;

    const(ubyte)[] encodedMemory() pure nothrow;

    static Sound load(string path);
}