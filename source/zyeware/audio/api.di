// This file is part of the ZyeWare Game Engine, and subject to the terms
// and conditions defined in the file 'LICENSE.txt', which is part
// of this source code package.
//
// Copyright 2021 ZyeByte
module zyeware.audio.api;

import zyeware.common;
import zyeware.audio;

struct AudioAPI
{
    @disable this();
    @disable this(this);

package(zyeware) static:
    void initialize();
    void loadLibraries();
    void cleanup();

public static:
    AudioBus getBus(string name);
    AudioBus addBus(string name);
    void removeBus(string name);

    Vector3f listenerLocation() nothrow;
    void listenerLocation(Vector3f value) nothrow;
}