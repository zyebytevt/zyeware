// This file is part of the ZyeWare Game Engine, and subject to the terms
// and conditions defined in the file 'LICENSE.txt', which is part
// of this source code package.
//
// Copyright 2021 ZyeByte
module zyeware.pal.pal;

import zyeware;
import zyeware.pal.generic.drivers;

package(zyeware):

struct Pal {
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
    alias GraphicsDriverLoader = void function(ref GraphicsDriver) nothrow;
    alias DisplayDriverLoader = void function(ref DisplayDriver) nothrow;
    alias AudioDriverLoader = void function(ref AudioDriver) nothrow;

package(zyeware) static:
    void initialize() nothrow {
        version (ZW_PAL_OPENGL)
            sGraphicsLoaders["opengl"] = &imported!"zyeware.pal.graphics.opengl.init".load;

        version (ZW_PAL_OPENAL)
            sAudioLoaders["openal"] = &imported!"zyeware.pal.audio.openal.init".load;

        version (ZW_PAL_SDL)
            sDisplayLoaders["sdl"] = &imported!"zyeware.pal.display.sdl.init".load;
    }

    void loadGraphicsDriver(string name) nothrow
    in (name in sGraphicsLoaders, "GraphicsDriver " ~ name ~ " not registered") {
        sGraphicsLoaders[name](sGraphics);
        Logger.core.info("Set graphics driver '%s' active.", name);
    }

    void loadDisplayDriver(string name) nothrow
    in (name in sDisplayLoaders, "DisplayDriver " ~ name ~ " not registered") {
        sDisplayLoaders[name](sDisplay);
        Logger.core.info("Set display driver '%s' active.", name);
    }

    void loadAudioDriver(string name) nothrow
    in (name in sAudioLoaders, "AudioDriver " ~ name ~ " not registered") {
        sAudioLoaders[name](sAudio);
        Logger.core.info("Set audio driver '%s' active.", name);
    }

    string[] registeredGraphicsDrivers() nothrow {
        return sGraphicsLoaders.keys;
    }

    string[] registeredDisplayDrivers() nothrow {
        return sDisplayLoaders.keys;
    }

    string[] registeredAudioDrivers() nothrow {
        return sAudioLoaders.keys;
    }

    pragma(inline, true)
    ref const(GraphicsDriver) graphics() nothrow {
        return sGraphics;
    }

    pragma(inline, true)
    ref const(DisplayDriver) display() nothrow {
        return sDisplay;
    }

    pragma(inline, true)
    ref const(AudioDriver) audio() nothrow {
        return sAudio;
    }
}
