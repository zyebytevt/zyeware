// This file is part of the ZyeWare Game Engine, and subject to the terms
// and conditions defined in the file 'LICENSE.txt', which is part
// of this source code package.
//
// Copyright 2021 ZyeByte
module zyeware.audio.buffer;

import zyeware.common;
import zyeware.audio;

alias NoiseBitties = AudioStream;
alias AirVibrationData = AudioStream;
alias EarMassager = AudioStream;
alias SonicStream = AudioStream;

@asset(Yes.cache)
class AudioStream
{
public:
    this(const(ubyte)[] encodedMemory);

    const(ubyte)[] encodedMemory() pure nothrow;

    static AudioStream load(string path);
}

/*
@asset(Yes.cache)
class Sound
{
public:
    static Sound load(string path);

    uint id() const pure nothrow;
}

@asset(Yes.cache)
class StreamedSound
{
public:
    static StreamedSound load(string path);
}
*/