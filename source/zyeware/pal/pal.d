module zyeware.pal.pal;

import zyeware.pal.graphicsDriver.callbacks;
import zyeware.pal.display.callbacks;
import zyeware.pal.renderer.callbacks;
import zyeware.pal.audio.callbacks;

struct Pal
{
    @disable this();
    @disable this(this);

private static:
    GraphicsDriver sGraphics;
    DisplayDriver sDisplay;
    Renderer2dDriver sRenderer2D;
    Renderer3dDriver sRenderer3D;
    AudioDriver sAudio;

    GraphicsDriverLoader[string] sGraphicsLoaders;
    DisplayDriverLoader[string] sDisplayLoaders;
    Renderer2dDriverLoader[string] sRenderer2dLoaders;
    Renderer3dDriverLoader[string] sRenderer3dLoaders;
    AudioDriverLoader[string] sAudioLoaders;

package(zyeware.pal) static:
    alias GraphicsDriverLoader = GraphicsDriver function() nothrow;
    alias DisplayDriverLoader = DisplayDriver function() nothrow;
    alias Renderer2dDriverLoader = Renderer2dDriver function() nothrow;
    alias Renderer3dDriverLoader = Renderer3dDriver function() nothrow;
    alias AudioDriverLoader = AudioDriver function() nothrow;

    void registerGraphics(string name, GraphicsDriverLoader callbacksGenerator) nothrow
    {
        sGraphicsLoaders[name] = callbacksGenerator;
    }

    void registerDisplay(string name, DisplayDriverLoader callbacksGenerator) nothrow
    {
        sDisplayLoaders[name] = callbacksGenerator;
    }

    void registerRenderer2d(string name, Renderer2dDriverLoader callbacksGenerator) nothrow
    {
        sRenderer2dLoaders[name] = callbacksGenerator;
    }

    void registerRenderer3d(string name, Renderer3dDriverLoader callbacksGenerator) nothrow
    {
        sRenderer3dLoaders[name] = callbacksGenerator;
    }

    void registerAudio(string name, AudioDriverLoader callbacksGenerator) nothrow
    {
        sAudioLoaders[name] = callbacksGenerator;
    }

package(zyeware) static:
    void loadGraphicsDriver(string name) nothrow
        in (name in sGraphicsLoaders, "GraphicsDriver " ~ name ~ " not registered")
    {
        sGraphics = sGraphicsLoaders[name]();
    }

    void loadDisplayDriver(string name) nothrow
        in (name in sDisplayLoaders, "DisplayDriver " ~ name ~ " not registered")
    {
        sDisplay = sDisplayLoaders[name]();
    }

    void loadRenderer2dDriver(string name) nothrow
        in (name in sRenderer2dLoaders, "Renderer2dDriver " ~ name ~ " not registered")
    {
        sRenderer2D = sRenderer2dLoaders[name]();
    }

    void loadRenderer3dDriver(string name) nothrow
        in (name in sRenderer3dLoaders, "Renderer3dDriver " ~ name ~ " not registered")
    {
        sRenderer3D = sRenderer3dLoaders[name]();
    }

    void loadAudioDriver(string name) nothrow
        in (name in sAudioLoaders, "AudioDriver " ~ name ~ " not registered")
    {
        sAudio = sAudioLoaders[name]();
    }

    string[] registeredGraphicsDrivers() nothrow
    {
        return sGraphicsLoaders.keys;
    }

    string[] registeredDisplayDrivers() nothrow
    {
        return sDisplayLoaders.keys;
    }

    string[] registeredRenderer2dDrivers() nothrow
    {
        return sRenderer2dLoaders.keys;
    }

    string[] registeredRenderer3dDrivers() nothrow
    {
        return sRenderer3dLoaders.keys;
    }

    string[] registeredAudioDrivers() nothrow
    {
        return sAudioLoaders.keys;
    }

    pragma(inline, true)
    ref Renderer2dDriver renderer2d() nothrow
    {
        return sRenderer2D;
    }

    pragma(inline, true)
    ref Renderer3dDriver renderer3d() nothrow
    {
        return sRenderer3D;
    }

public static:
    pragma(inline, true)
    ref GraphicsDriver graphicsDriver() nothrow
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