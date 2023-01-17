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
    alias NoiseBitties = Audio;
    alias AirVibrationData = Audio;
    alias EarMassager = Audio;
    alias SonicStream = Audio;
}

@asset(Yes.cache)
class Audio
{
public:
    this(const(ubyte)[] encodedMemory, AudioProperties properties = AudioProperties.init);

    LoopPoint loopPoint() pure const nothrow;

    void loopPoint(LoopPoint value) pure nothrow;

    const(ubyte)[] encodedMemory() pure nothrow;

    static Audio load(string path);
}