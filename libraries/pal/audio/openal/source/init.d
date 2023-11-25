// This file is part of the ZyeWare Game Engine, and subject to the terms
// and conditions defined in the file 'LICENSE.txt', which is part
// of this source code package.
//
// Copyright 2021 ZyeByte
module zyeware.pal.audio.openal.init;

import zyeware.pal;
import zyeware.pal.audio.driver;

import zyeware.pal.audio.openal.api;

public:

shared static this()
{
    Pal.registerAudioDriver("openal", () => AudioDriver(
        &initialize,
        &loadLibraries,
        &cleanup,
        &createSource,
        &createBuffer,
        &createBus,
        &freeSource,
        &freeBuffer,
        &freeBus,
        &setBufferLoopPoint,
        &getBufferLoopPoint,
        &setSourceBuffer,
        &setSourceBus,
        &setSourceVolume,
        &setSourcePitch,
        &setSourceLooping,
        &getSourceVolume,
        &getSourcePitch,
        &getSourceLooping,
        &getSourceState,
        &playSource,
        &pauseSource,
        &stopSource,
        &setBusVolume,
        &getBusVolume,
        &updateSourceBuffers
    ));
}