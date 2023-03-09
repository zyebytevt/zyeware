// This file is part of the ZyeWare Game Engine, and subject to the terms
// and conditions defined in the file 'LICENSE.txt', which is part
// of this source code package.
//
// Copyright 2021 ZyeByte
module zyeware.audio.openal.impl;

version (ZW_OpenAL):
package(zyeware):

import zyeware.audio;

import zyeware.audio.openal.api;
import zyeware.audio.openal.buffer;
import zyeware.audio.openal.source;

void loadOpenALBackend()
{
    AudioAPI.sInitializeImpl = &apiInitialize;
    AudioAPI.sLoadLibrariesImpl = &apiLoadLibraries;
    AudioAPI.sCleanupImpl = &apiCleanup;

    AudioAPI.sAddBusImpl = &apiAddBus;
    AudioAPI.sGetBusImpl = &apiGetBus;
    AudioAPI.sRemoveBusImpl = &apiRemoveBus;
    AudioAPI.sSetListenerLocationImpl = &apiSetListenerLocation;
    AudioAPI.sGetListenerLocationImpl = &apiGetListenerLocation;

    AudioAPI.sCreateSoundImpl = (encMem, props) => new OALSound(encMem, props);
    AudioAPI.sCreateAudioSourceImpl = (bus) => new OALAudioSource(bus);

    AudioAPI.sLoadSoundImpl = (path) => OALSound.load(path);
}