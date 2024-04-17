// This file is part of the ZyeWare Game Engine, and subject to the terms
// and conditions defined in the file 'LICENSE.txt', which is part
// of this source code package.
//
// Copyright © 2021-2024 ZyeByte. All rights reserved.
module zyeware.audio.api;

import core.thread;

import std.algorithm : remove;
import std.datetime : Duration, msecs;
import std.functional : toDelegate;

import bindbc.openal;

import zyeware;

enum audioBufferSize = 4096 * 4;
enum audioBufferCount = 4;

struct AudioApi
{
    @disable this();
    @disable this(this);

private static:
    ALCdevice* sDevice;
    ALCcontext* sContext;

    ThreadID sThread;
    __gshared bool sIsThreadRunning;
    __gshared AudioSource[] sSources;

    void threadRun() nothrow
    {
        // Determine the sleep time between updating the buffers.
        // YukieVT supplied the following formula for this:
        //     (BuffTotalLen / BuffCount) / SampleRate / 2 * 1000
        // We assume a default sample rate of 44100 for audio.

        immutable Duration waitTime = msecs(audioBufferSize / audioBufferCount / 44_100 / 2 * 1000);

        while (sIsThreadRunning)
        {
            foreach (ref AudioSource source; sSources)
                source.update();

            Thread.sleep(waitTime);
        }
    }

package(zyeware.audio) static:
    void registerSource(AudioSource source) nothrow
    {
        sSources ~= source;
    }

    void unregisterSource(AudioSource source) nothrow
    {
        for (size_t i; i < sSources.length; ++i)
        {
            if (sSources[i] is source)
            {
                sSources = sSources.remove(i);
                break;
            }
        }
    }

    void updateSources() nothrow
    {
        foreach (ref AudioSource source; sSources)
            source.update();
    }

package(zyeware) static:
    void initialize()
    {
        import loader = bindbc.loader.sharedlib;
        import std.string : fromStringz;

        if (isOpenALLoaded())
            return;

        immutable alResult = loadOpenAL();
        if (alResult != alSupport)
        {
            foreach (info; loader.errors)
                Logger.core.warning("OpenAL loader: %s", info.message.fromStringz);

            switch (alResult)
            {
            case ALSupport.noLibrary:
                throw new AudioException("Could not find OpenAL shared library.");

            case ALSupport.badLibrary:
                throw new AudioException("Provided OpenAL shared is corrupted.");

            default:
                Logger.core.warning(
                    "Got older OpenAL version than expected. This might lead to errors.");
            }
        }

        enforce!AudioException(sDevice = alcOpenDevice(null), "Failed to create audio device.");
        enforce!AudioException(sContext = alcCreateContext(sDevice, null),
            "Failed to create audio context.");

        enforce!AudioException(alcMakeContextCurrent(sContext), "Failed to make audio context current.");

        Logger.core.info("Initialized OpenAL:");
        Logger.core.info("    Version: %s", alGetString(AL_VERSION).fromStringz);
        Logger.core.info("    Vendor: %s", alGetString(AL_VENDOR).fromStringz);
        Logger.core.info("    Renderer: %s", alGetString(AL_RENDERER).fromStringz);
        Logger.core.info("    Extensions: %s", alGetString(AL_EXTENSIONS).fromStringz);

        sThread = createLowLevelThread(toDelegate(&threadRun));
        enforce!AudioException(sThread != ThreadID.init, "Failed to create audio thread.");
        sIsThreadRunning = true;

        Logger.core.info("Audio thread started.");
    }

    void cleanup()
    {
        sIsThreadRunning = false;
        joinLowLevelThread(sThread);
        alcCloseDevice(sDevice);

        Logger.core.info("Audio thread stopped, OpenAL terminated.");
    }
}