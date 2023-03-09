// This file is part of the ZyeWare Game Engine, and subject to the terms
// and conditions defined in the file 'LICENSE.txt', which is part
// of this source code package.
//
// Copyright 2021 ZyeByte
module zyeware.audio.openal.api;

version (ZW_OpenAL):
package(zyeware.audio.openal):

import std.string : format, fromStringz;
import std.exception : enforce;

import bindbc.openal;

import zyeware.common;
import zyeware.audio;

ALCdevice* pDevice;
ALCcontext* pContext;
AudioBus[string] pBusses;

void apiInitialize()
{
    apiLoadLibraries();

    apiAddBus("master");

    enforce!AudioException(pDevice = alcOpenDevice(null), "Failed to create audio device.");
    enforce!AudioException(pContext = alcCreateContext(pDevice, null), "Failed to create audio context.");

    enforce!AudioException(alcMakeContextCurrent(pContext), "Failed to make audio context current.");
}

void apiLoadLibraries()
{
    import loader = bindbc.loader.sharedlib;
    import std.string : fromStringz;

    if (isOpenALLoaded())
        return;

    immutable alResult = loadOpenAL();
    if (alResult != alSupport)
    {
        foreach (info; loader.errors)
            Logger.core.log(LogLevel.warning, "OpenAL loader: %s", info.message.fromStringz);

        switch (alResult)
        {
        case ALSupport.noLibrary:
            throw new AudioException("Could not find OpenAL shared library.");

        case ALSupport.badLibrary:
            throw new AudioException("Provided OpenAL shared is corrupted.");

        default:
            Logger.core.log(LogLevel.warning, "Got older OpenAL version than expected. This might lead to errors.");
        }
    }
}

void apiCleanup()
{
    alcCloseDevice(pDevice);
}

AudioBus apiGetBus(string name)
    in (name, "Name cannot be null.")
{
    AudioBus result = pBusses.get(name, null);
    enforce!AudioException(result, format!"No audio bus named '%s' exists."(name));
    
    return result;
}

AudioBus apiAddBus(string name)
    in (name, "Name cannot be null.")
{
    enforce!AudioException(!(name in pBusses), format!"Audio bus named '%s' already exists."(name));

    auto bus = new AudioBus(name);
    pBusses[name] = bus;

    return bus;
}

void apiRemoveBus(string name)
    in (name, "Name cannot be null.")
{
    if (name in pBusses)
    {
        pBusses.remove(name);
    }
}

Vector3f apiGetListenerLocation() nothrow
{
    return Vector3f(0);
}

void apiSetListenerLocation(Vector3f value) nothrow
{

}