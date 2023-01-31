// This file is part of the ZyeWare Game Engine, and subject to the terms
// and conditions defined in the file 'LICENSE.txt', which is part
// of this source code package.
//
// Copyright 2021 ZyeByte
module zyeware.audio.api;

import zyeware.common;
import zyeware.audio;

/// Allows direct access to the audio API.
struct AudioAPI
{
    @disable this();
    @disable this(this);

package(zyeware) static:
    void initialize();
    void loadLibraries();
    void cleanup();

public static:
    /// Requests an already registered bus from the audio subsystem.
    /// Params:
    ///   name = The name of the requested bus.
    /// Returns: The bus registered with the given name.
    /// Throws: `AudioException` if no bus with the given name exists.
    AudioBus getBus(string name);

    /// Adds a new audio bus with the given name to the audio subsystem.
    /// Params:
    ///   name = The name to register the new bus with.
    /// Returns: The newly registered bus.
    /// Throws: `AudioException` if a bus with the given name already exists.
    AudioBus addBus(string name);

    /// Removes the bus with the given name from the audio subsystem. If no such
    /// bus exists, nothing happens.
    /// Params:
    ///   name = The name of the bus to remove.
    void removeBus(string name);

    /// The location of the audio listener in 3D space.
    Vector3f listenerLocation() nothrow;

    /// ditto
    void listenerLocation(Vector3f value) nothrow;
}