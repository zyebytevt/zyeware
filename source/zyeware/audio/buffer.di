// This file is part of the ZyeWare Game Engine, and subject to the terms
// and conditions defined in the file 'LICENSE.txt', which is part
// of this source code package.
//
// Copyright 2021 ZyeByte
module zyeware.audio.buffer;

import zyeware.common;
import zyeware.audio;

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