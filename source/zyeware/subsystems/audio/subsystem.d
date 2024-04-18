// This file is part of the ZyeWare Game Engine, and subject to the terms
// and conditions defined in the file 'LICENSE.txt', which is part
// of this source code package.
//
// Copyright © 2021-2024 ZyeByte. All rights reserved.
module zyeware.subsystems.audio.subsystem;

import core.thread;

import std.string : fromStringz, format;

import soloud;
import loader = bindbc.loader.sharedlib;

import zyeware;

package alias SoloudHandle = int*;

struct AudioSubsystem
{
    @disable this();
    @disable this(this);

package static:
    SoloudHandle sEngine;
    AudioBus[string] sBuses;

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

            //case SLSupport.badLibrary:
            //    throw new AudioException("Provided Soloud shared library is corrupted.");

            default:
                Logger.core.warning(
                    "Got older Soloud version than expected. This might lead to errors.");
            }
        }

        sEngine = Soloud_create();
        Soloud_initEx(sEngine, Soloud.CLIP_ROUNDOFF, Soloud.SDL2, Soloud.AUTO, Soloud.AUTO, Soloud.AUTO);
    }

    void unload()
    {
        foreach (AudioBus bus; sBuses)
            bus.destroy();
        sBuses.clear();

        Soloud_deinit(sEngine);
    }

public:
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
}