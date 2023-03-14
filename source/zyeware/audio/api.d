// This file is part of the ZyeWare Game Engine, and subject to the terms
// and conditions defined in the file 'LICENSE.txt', which is part
// of this source code package.
//
// Copyright 2021 ZyeByte
module zyeware.audio.api;

import zyeware.common;
import zyeware.audio;


/// Holds information about the audio backend.
struct AudioBackendProperties
{
    /// Used for selecting an audio backend at the start of the engine.
    enum Backend
    {
        mostAppropriate, /// Chooses the most appropriate backend for platform.
        headless, /// A dummy API, does nothing.
        openAl /// Used OpenAL for audio playback.
    }

    Backend backend; /// The backend to use.
    Flag!"debugMode" debugMode = No.debugMode;
    uint bufferSize = 4096 * 4; /// The size of an individual audio buffer in samples.
    uint bufferCount = 4; /// The amount of audio buffers to cycle through for streaming.
}

/// Allows direct access to the audio API.
struct AudioAPI
{
    @disable this();
    @disable this(this);

package(zyeware) static:
    void function() sInitializeImpl;
    void function() sLoadLibrariesImpl;
    void function() sCleanupImpl;

    AudioBus function(string) sGetBusImpl;
    AudioBus function(string) sAddBusImpl;
    void function(string) sRemoveBusImpl;
    Vector3f function() nothrow sGetListenerLocationImpl;
    void function(Vector3f) nothrow sSetListenerLocationImpl;

    Sound function(const(ubyte)[], AudioProperties) sCreateSoundImpl;
    Sound function(string) sLoadSoundImpl;
    AudioSource function(AudioBus) sCreateAudioSourceImpl;

    pragma(inline, true)
    void initialize()
    {
        sInitializeImpl();
    }

    pragma(inline, true)
    void loadLibraries()
    {
        sLoadLibrariesImpl();
    }

    pragma(inline, true)
    void cleanup()
    {
        sCleanupImpl();
    }

public static:
    /// Requests an already registered bus from the audio subsystem.
    /// Params:
    ///   name = The name of the requested bus.
    /// Returns: The bus registered with the given name.
    /// Throws: `AudioException` if no bus with the given name exists.
    pragma(inline, true)
    AudioBus getBus(string name)
    {
        return sGetBusImpl(name);
    }

    /// Adds a new audio bus with the given name to the audio subsystem.
    /// Params:
    ///   name = The name to register the new bus with.
    /// Returns: The newly registered bus.
    /// Throws: `AudioException` if a bus with the given name already exists.
    pragma(inline, true)
    AudioBus addBus(string name)
    {
        return sAddBusImpl(name);
    }

    /// Removes the bus with the given name from the audio subsystem. If no such
    /// bus exists, nothing happens.
    /// Params:
    ///   name = The name of the bus to remove.
    pragma(inline, true)
    void removeBus(string name)
    {
        sRemoveBusImpl(name);
    }

    /// The location of the audio listener in 3D space.
    pragma(inline, true)
    Vector3f listenerLocation() nothrow
    {
        return sGetListenerLocationImpl();
    }

    /// ditto
    pragma(inline, true)
    void listenerLocation(Vector3f value) nothrow
    {
        return sSetListenerLocationImpl(value);
    }
}