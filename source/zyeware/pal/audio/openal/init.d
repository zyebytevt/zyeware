// This file is part of the ZyeWare Game Engine, and subject to the terms
// and conditions defined in the file 'LICENSE.txt', which is part
// of this source code package.
//
// Copyright 2021 ZyeByte
module zyeware.pal.audio.openal.init;
version (ZW_PAL_OPENAL)  : import zyeware.pal.generic.drivers;
import zyeware.pal.audio.openal.api;

package(zyeware.pal):

void load(ref AudioDriver driver) nothrow {
    driver.initialize = &initialize;
    driver.loadLibraries = &loadLibraries;
    driver.cleanup = &cleanup;

    driver.createSource = &createSource;
    driver.createBuffer = &createBuffer;
    driver.createBus = &createBus;

    driver.freeSource = &freeSource;
    driver.freeBuffer = &freeBuffer;
    driver.freeBus = &freeBus;

    driver.setBufferLoopPoint = &setBufferLoopPoint;
    driver.getBufferLoopPoint = &getBufferLoopPoint;

    driver.setSourceBuffer = &setSourceBuffer;
    driver.setSourceBus = &setSourceBus;
    driver.setSourceVolume = &setSourceVolume;
    driver.setSourcePitch = &setSourcePitch;
    driver.setSourceLooping = &setSourceLooping;

    driver.getSourceVolume = &getSourceVolume;
    driver.getSourcePitch = &getSourcePitch;
    driver.isSourceLooping = &isSourceLooping;
    driver.getSourceState = &getSourceState;

    driver.playSource = &playSource;
    driver.pauseSource = &pauseSource;
    driver.stopSource = &stopSource;

    driver.setBusVolume = &setBusVolume;
    driver.getBusVolume = &getBusVolume;

    driver.updateSourceBuffers = &updateSourceBuffers;
}
