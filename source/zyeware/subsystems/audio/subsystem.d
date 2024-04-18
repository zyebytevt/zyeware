// This file is part of the ZyeWare Game Engine, and subject to the terms
// and conditions defined in the file 'LICENSE.txt', which is part
// of this source code package.
//
// Copyright © 2021-2024 ZyeByte. All rights reserved.
module zyeware.subsystems.audio.subsystem;

import core.thread;

import std.string : fromStringz;

import soloud;
import loader = bindbc.loader.sharedlib;

import zyeware;

struct AudioSubsystem
{
    @disable this();
    @disable this(this);

package static:
    Soloud sEngine;

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

        sEngine = Soloud.create();
        sEngine.init(Soloud.CLIP_ROUNDOFF, Soloud.SDL2);
    }

    void unload()
    {
        sEngine.deinit();
    }
}