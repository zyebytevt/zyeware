module zyeware.audio.sample;

import std.exception : enforce;
import std.string : format;

import gamemixer;

import zyeware.common;
import zyeware.audio;

@asset(Yes.cache)
class AudioSample
{
package:
    IAudioSource mSource;

    this(IAudioSource source)
    {
        mSource = source;
    }

public:
    static AudioSample load(string path)
    {
        scope VFSFile file = VFS.getFile(path);
        ubyte[] data = file.readAll!(ubyte[]);
        file.close();

        IAudioSource source = AudioAPI.sMixer.createSourceFromMemory(data);
        enforce!AudioException(source, format!"Failed to load audio sample '%s'."(path));

        return new AudioSample(source);
    }
}