module zyeware.pal.pal;

import zyeware.pal.graphics.callbacks;
import zyeware.pal.display.callbacks;
import zyeware.pal.renderer.callbacks;
import zyeware.pal.audio.callbacks;

struct Pal
{
    @disable this();
    @disable this(this);

private static:
    GraphicsPal sGraphics;
    DisplayPal sDisplay;
    Renderer2dPal sRenderer2D;
    Renderer3dPal sRenderer3D;
    AudioPal sAudio;

    GraphicsPalLoader[string] sGraphicsLoaders;
    DisplayPalLoader[string] sDisplayLoaders;
    Renderer2dPalLoader[string] sRenderer2dLoaders;
    Renderer3dPalLoader[string] sRenderer3dLoaders;
    AudioPalLoader[string] sAudioLoaders;

package(zyeware.pal) static:
    alias GraphicsPalLoader = GraphicsPal function() nothrow;
    alias DisplayPalLoader = DisplayPal function() nothrow;
    alias Renderer2dPalLoader = Renderer2dPal function() nothrow;
    alias Renderer3dPalLoader = Renderer3dPal function() nothrow;
    alias AudioPalLoader = AudioPal function() nothrow;

    void registerGraphics(string name, GraphicsPalLoader callbacksGenerator) nothrow
    {
        sGraphicsLoaders[name] = callbacksGenerator;
    }

    void registerDisplay(string name, DisplayPalLoader callbacksGenerator) nothrow
    {
        sDisplayLoaders[name] = callbacksGenerator;
    }

    void registerRenderer2d(string name, Renderer2dPalLoader callbacksGenerator) nothrow
    {
        sRenderer2dLoaders[name] = callbacksGenerator;
    }

    void registerRenderer3d(string name, Renderer3dPalLoader callbacksGenerator) nothrow
    {
        sRenderer3dLoaders[name] = callbacksGenerator;
    }

    void registerAudio(string name, AudioPalLoader callbacksGenerator) nothrow
    {
        sAudioLoaders[name] = callbacksGenerator;
    }

package(zyeware) static:
    void loadGraphics(string name) nothrow
        in (name in sGraphicsLoaders, "GraphicsPal " ~ name ~ " not registered")
    {
        sGraphics = sGraphicsLoaders[name]();
    }

    void loadDisplay(string name) nothrow
        in (name in sDisplayLoaders, "DisplayPal " ~ name ~ " not registered")
    {
        sDisplay = sDisplayLoaders[name]();
    }

    void loadRenderer2d(string name) nothrow
        in (name in sRenderer2dLoaders, "Renderer2dPal " ~ name ~ " not registered")
    {
        sRenderer2D = sRenderer2dLoaders[name]();
    }

    void loadRenderer3d(string name) nothrow
        in (name in sRenderer3dLoaders, "Renderer3dPal " ~ name ~ " not registered")
    {
        sRenderer3D = sRenderer3dLoaders[name]();
    }

    void loadAudio(string name) nothrow
        in (name in sAudioLoaders, "AudioPal " ~ name ~ " not registered")
    {
        sAudio = sAudioLoaders[name]();
    }

    string[] registeredGraphics() nothrow
    {
        return sGraphicsLoaders.keys;
    }

    string[] registeredDisplay() nothrow
    {
        return sDisplayLoaders.keys;
    }

    string[] registeredRenderer2d() nothrow
    {
        return sRenderer2dLoaders.keys;
    }

    string[] registeredRenderer3d() nothrow
    {
        return sRenderer3dLoaders.keys;
    }

    string[] registeredAudio() nothrow
    {
        return sAudioLoaders.keys;
    }

    pragma(inline, true)
    ref Renderer2dPal renderer2d() nothrow
    {
        return sRenderer2D;
    }

    pragma(inline, true)
    ref Renderer3dPal renderer3d() nothrow
    {
        return sRenderer3D;
    }

public static:
    pragma(inline, true)
    ref GraphicsPal graphics() nothrow
    {
        return sGraphics;
    }

    pragma(inline, true)
    ref DisplayPal display() nothrow
    {
        return sDisplay;
    }

    pragma(inline, true)
    ref AudioPal audio() nothrow
    {
        return sAudio;
    }
}