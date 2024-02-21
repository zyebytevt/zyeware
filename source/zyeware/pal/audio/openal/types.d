// This file is part of the ZyeWare Game Engine, and subject to the terms
// and conditions defined in the file 'LICENSE.txt', which is part
// of this source code package.
//
// Copyright 2021 ZyeByte
module zyeware.pal.audio.openal.types;
version (ZW_PAL_OPENAL)  : import audioformats;

import zyeware.pal.generic.types.audio;

package:

struct BufferData {
    const(ubyte[]) encodedMemory;
    LoopPoint loopPoint;
}

struct SourceData {
    uint id;
    uint[] bufferIds;
    short[] processingBuffer;
    int processedCount;

    float volume = 1f;
    float pitch = 1f;
    bool isLooping;

    SourceState state;

    AudioStream decoder;
    const(BufferData)* bufferData;
    const(BusData)* bus;
}

struct BusData {
    string name;
    float volume = 1f;
}
