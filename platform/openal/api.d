// This file is part of the ZyeWare Game Engine, and subject to the terms
// and conditions defined in the file 'LICENSE.txt', which is part
// of this source code package.
//
// Copyright 2021 ZyeByte
module zyeware.audio.api;

import std.string : format, fromStringz;
import std.exception : enforce;

import bindbc.openal;

import zyeware.common;
import zyeware.audio;

struct AudioAPI
{
    @disable this();
    @disable this(this);

private static:
    ALCdevice* sDevice;
    ALCcontext* sContext;

    AudioBus[string] sBusses;

package(zyeware) static:
    void initialize()
    {
        loadLibraries();

        addBus("master");

        enforce!AudioException(sDevice = alcOpenDevice(null), "Failed to create audio device.");
        enforce!AudioException(sContext = alcCreateContext(sDevice, null), "Failed to create audio context.");

        enforce!AudioException(alcMakeContextCurrent(sContext), "Failed to make audio context current.");
    }

    void loadLibraries()
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

    void cleanup()
    {
        alcCloseDevice(sDevice);
    }

public static:

    AudioBus getBus(string name)
        in (name, "Name cannot be null.")
    {
        AudioBus result = sBusses.get(name, null);
        enforce!AudioException(result, format!"No audio bus named '%s' exists."(name));
        
        return result;
    }

    AudioBus addBus(string name)
        in (name, "Name cannot be null.")
    {
        enforce!AudioException(!(name in sBusses), format!"Audio bus named '%s' already exists."(name));

        auto bus = new AudioBus(name);
        sBusses[name] = bus;

        return bus;
    }

    void removeBus(string name)
        in (name, "Name cannot be null.")
    {
        if (name in sBusses)
        {
            sBusses[name].dispose();
            sBusses.remove(name);
        }
    }

    Vector3f listenerLocation() nothrow
    {
        return Vector3f(0);
    }

    void listenerLocation(Vector3f value) nothrow
    {

    }
}