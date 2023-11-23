module zyeware.pal.pal;

import zyeware.common;
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
        Logger.core.log(LogLevel.info, "Loaded graphics driver: " ~ name);
    }

    void loadDisplayDriver(string name) nothrow
        in (name in sDisplayLoaders, "DisplayDriver " ~ name ~ " not registered")
    {
        sDisplay = sDisplayLoaders[name]();
        Logger.core.log(LogLevel.info, "Loaded display driver: " ~ name);
    }

    void loadAudioDriver(string name) nothrow
        in (name in sAudioLoaders, "AudioDriver " ~ name ~ " not registered")
    {
        sAudio = sAudioLoaders[name]();
        Logger.core.log(LogLevel.info, "Loaded audio driver: " ~ name);
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
    ref GraphicsDriver graphics() nothrow
    {
        return sGraphics;
    }

    pragma(inline, true)
    ref DisplayDriver display() nothrow
    {
        return sDisplay;
    }

    pragma(inline, true)
    ref AudioDriver audio() nothrow
    {
        return sAudio;
    }
}