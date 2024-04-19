// This file is part of the ZyeWare Game Engine, and subject to the terms
// and conditions defined in the file 'LICENSE.txt', which is part
// of this source code package.
//
// Copyright © 2021-2024 ZyeByte. All rights reserved.
module zyeware.subsystems.audio.subsystem;

import core.thread;

import std.string : fromStringz, format;

import soloud;
import bindbc.soloud;
import loader = bindbc.loader.sharedlib;

import zyeware;
import zyeware.subsystems.audio;

package alias SoloudHandle = int*;

struct AudioSubsystem
{
    @disable this();
    @disable this(this);

package static:
    SoloudHandle sEngine;
    AudioBus[string] sBuses;
    // To keep them from being collected by GC
    AudioFilter[maxFilters] sFilters;

package(zyeware) static:
    void load()
    {
        if (isSoloudLoaded())
            return;

        immutable slResult = loadSoloud();
        if (slResult != slSupport)
        {
            foreach (info; loader.errors)
                Logger.core.warning("Soloud loader: %s", info.message.fromStringz);

            switch (slResult)
            {
            case SLSupport.noLibrary:
                throw new AudioException("Could not find Soloud shared library.");

            case SLSupport.badLibrary:
                throw new AudioException("Provided Soloud shared library is corrupted.");

            default:
                Logger.core.warning(
                    "Got older Soloud version than expected. This might lead to errors.");
            }
        }

        sEngine = Soloud_create();
        Soloud_initEx(sEngine, Soloud.CLIP_ROUNDOFF, Soloud.AUTO, 44_100, Soloud.AUTO, 2);

        immutable uint soloudVersion = Soloud_getVersion(sEngine);

        Logger.core.info("Audio subsystem initialized, Soloud version: %d.%d.%d", soloudVersion >> 16 & 0xFF, soloudVersion >> 8 & 0xFF, soloudVersion & 0xFF);
    }

    void unload()
    {
        foreach (AudioBus bus; sBuses)
            bus.destroy();
        sBuses.clear();

        Soloud_deinit(sEngine);
    }

public static:
    enum maxFilters = 4;

    VoiceHandle createVoiceGroup()
    {
        immutable uint handle = Soloud_createVoiceGroup(sEngine);
        enforce!AudioException(handle != 0, "Failed to create voice group.");
        return VoiceHandle(handle);
    }

    AudioBus createBus(string name)
    {
        AudioBus* bus = name in sBuses;
        enforce!AudioException(!bus, format!"Bus with name '%s' already exists."(name));

        auto newBus = new AudioBus(name);
        sBuses[name] = newBus;

        return newBus;
    }

    AudioBus getBus(string name)
    {
        AudioBus* bus = name in sBuses;
        enforce!AudioException(bus, format!"Bus with name '%s' does not exist."(name));

        return *bus;
    }

    void destroyBus(string name)
    {
        AudioBus* bus = name in sBuses;
        enforce!AudioException(bus, format!"Bus with name '%s' does not exist."(name));

        (*bus).destroy();
        sBuses.remove(name);
    }

    void setFilter(uint filterId, AudioFilter filter) nothrow
    in (filterId < maxFilters, "Filter ID out of range.")
    {
        sFilters[filterId] = filter;
        Soloud_setGlobalFilter(sEngine, filterId, filter.mFilter);
    }

    void fadeGlobalVolume(float to, in Duration time) => Soloud_fadeGlobalVolume(sEngine, to, time.toDoubleSeconds);

    uint activeVoiceCount() nothrow => Soloud_getActiveVoiceCount(sEngine);
    uint voiceCount() nothrow => Soloud_getVoiceCount(sEngine);

    uint maxActiveVoiceCount() nothrow => Soloud_getMaxActiveVoiceCount(sEngine);
    uint maxActiveVoiceCount(uint value) nothrow
    {
        Soloud_setMaxActiveVoiceCount(sEngine, value);
        return value;
    }

    float globalVolume() nothrow => Soloud_getGlobalVolume(sEngine);
    float globalVolume(float value) nothrow
    {
        Soloud_setGlobalVolume(sEngine, value);
        return value;
    }

    void setListenerParameters(in vec3 position = vec3.zero, in vec3 forward = vec3.forward, in vec3 up = vec3.up, in vec3 velocity = vec3.zero)
    {
        Soloud_set3dListenerParametersEx(sEngine, position.x, position.y, position.z,
            forward.x, forward.y, forward.z, up.x, up.y, up.z, velocity.x, velocity.y, velocity.z);
    }
}