// This file is part of the ZyeWare Game Engine, and subject to the terms
// and conditions defined in the file 'LICENSE.txt', which is part
// of this source code package.
//
// Copyright 2021 ZyeByte
module zyeware.pal.pal;

import zyeware;
import zyeware.pal.graphics.driver;
import zyeware.pal.display.driver;
import zyeware.pal.audio.driver;

struct Pal
{
    @disable this();
    @disable this(this);

private static:
    GraphicsDriver sGraphics;
    DisplayDriver sDisplay;
    AudioDriver sAudio;

    GraphicsDriverLoader[string] sGraphicsLoaders;
    DisplayDriverLoader[string] sDisplayLoaders;
    AudioDriverLoader[string] sAudioLoaders;

package(zyeware.pal) static:
    alias GraphicsDriverLoader = GraphicsDriver function() nothrow;
    alias DisplayDriverLoader = DisplayDriver function() nothrow;
    alias AudioDriverLoader = AudioDriver function() nothrow;

    void registerGraphicsDriver(string name, GraphicsDriverLoader callbacksGenerator) nothrow
    {
        sGraphicsLoaders[name] = callbacksGenerator;
    }

    void registerDisplayDriver(string name, DisplayDriverLoader callbacksGenerator) nothrow
    {
        sDisplayLoaders[name] = callbacksGenerator;
    }

    void registerAudioDriver(string name, AudioDriverLoader callbacksGenerator) nothrow
    {
        sAudioLoaders[name] = callbacksGenerator;
    }

package(zyeware) static:
    void loadGraphicsDriver(string name) nothrow
        in (name in sGraphicsLoaders, "GraphicsDriver " ~ name ~ " not registered")
    {
        sGraphics = sGraphicsLoaders[name]();
        Logger.core.info("Set graphics driver '%s' active.", name);
    }

    void loadDisplayDriver(string name) nothrow
        in (name in sDisplayLoaders, "DisplayDriver " ~ name ~ " not registered")
    {
        sDisplay = sDisplayLoaders[name]();
        Logger.core.info("Set display driver '%s' active.", name);
    }

    void loadAudioDriver(string name) nothrow
        in (name in sAudioLoaders, "AudioDriver " ~ name ~ " not registered")
    {
        sAudio = sAudioLoaders[name]();
        Logger.core.info("Set audio driver '%s' active.", name);
    }

    string[] registeredGraphicsDrivers() nothrow
    {
        return sGraphicsLoaders.keys;
    }

    string[] registeredDisplayDrivers() nothrow
    {
        return sDisplayLoaders.keys;
    }

    string[] registeredAudioDrivers() nothrow
    {
        return sAudioLoaders.keys;
    }

public static:
    pragma(inline, true)
    ref const(GraphicsDriver) graphics() nothrow
    {
        return sGraphics;
    }

    pragma(inline, true)
    ref const(DisplayDriver) display() nothrow
    {
        return sDisplay;
    }

    pragma(inline, true)
    ref const(AudioDriver) audio() nothrow
    {
        return sAudio;
    }
}