module zyeware.audio.api;

import std.exception : enforce;
import std.string : format;
import std.typecons : Rebindable;

import gamemixer;

import zyeware.common;
import zyeware.audio;

struct AudioAPI
{
    @disable this();
    @disable this(this);

package static:
    IMixer sMixer;

    AudioBus[string] sBusses;
    AudioBus sMasterBus;

public static:
    void initialize()
    {
        sMixer = mixerCreate();

        sMasterBus = addBus("master");
    }

    void cleanup()
    {
        mixerDestroy(sMixer);
    }

    AudioBus getBus(string name)
    {
        AudioBus result = sBusses.get(name, null);
        enforce!AudioException(result, format!"No audio bus named '%s' exists."(name));
        
        return result;
    }

    AudioBus addBus(string name)
    {
        enforce!AudioException(!(name in sBusses), format!"Audio bus named '%s' already exists."(name));

        auto bus = new AudioBus(name);
        sBusses[name] = bus;

        return bus;
    }

    void removeBus(string name)
    {
        if (name in sBusses)
        {
            sBusses.remove(name);
        }
    }

    void stopAll() nothrow
    {
        sMixer.stopAllChannels();
    }

    void play(AudioSample sample, in PlayProperties properties = PlayProperties.init)
    {
        PlayOptions options;

        // First, get mixer and multiply volume
        Rebindable!(const AudioBus) bus = properties.bus;
        if (!bus)
            bus = sMasterBus;

        options.volume = properties.volume * bus.volume;
        options.loopCount = properties.looping ? loopForever : 1;
        options.channel = properties.channel;

        sMixer.play(sample.mSource, options);
    }

    Vector3f listenerLocation() nothrow
    {
        return Vector3f(0);
    }

    void listenerLocation(Vector3f value) nothrow
    {
    }
}