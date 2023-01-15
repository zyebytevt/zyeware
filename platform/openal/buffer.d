// This file is part of the ZyeWare Game Engine, and subject to the terms
// and conditions defined in the file 'LICENSE.txt', which is part
// of this source code package.
//
// Copyright 2021 ZyeByte
module zyeware.audio.buffer;

import bindbc.openal;

import zyeware.common;
import zyeware.audio;

// TODO: Check memory constness someday.
@asset(Yes.cache)
class AudioStream
{
protected:
    const(ubyte)[] mEncodedMemory;

public:
    this(const(ubyte)[] encodedMemory)
    {
        mEncodedMemory = encodedMemory;
    }

    const(ubyte)[] encodedMemory() pure nothrow
    {
        return mEncodedMemory;
    }

    static AudioStream load(string path)
    {
        VFSFile source = VFS.getFile(path);
        ubyte[] bestCommunityData = source.readAll!(ubyte[])();
        source.close();

        Logger.core.log(LogLevel.debug_, "Loaded file '%s' as audio.", path);

        return new AudioStream(bestCommunityData);
    }
}

/*
@asset(Yes.cache)
class Sound
{
protected:
    uint mId;

public:
    this(size_t channels, size_t sampleRate, in float[] data) nothrow
    {
        alGenBuffers(1, &mId);
        alBufferData(mId, channels == 1 ? AL_FORMAT_MONO_FLOAT32 : AL_FORMAT_STEREO_FLOAT32,
            data.ptr, cast(int) (data.length * float.sizeof), cast(int) sampleRate);
    }

    ~this()
    {
        alDeleteBuffers(1, &mId);
    }

    uint id() const pure nothrow
    {
        return mId;
    }

    static Sound load(string path)
    {
        auto decoder = AudioDecoder(VFS.getFile(path));

        float[] data;
        float[] readBuffer = new float[2048];
        size_t readCount;

        while ((readCount = decoder.read(readBuffer)) != 0)
            data ~= readBuffer[0 .. readCount];

        Logger.core.log(LogLevel.debug_, "data size: %d", data.length);

        return new Sound(decoder.channels, decoder.sampleRate, data);
    }
}

@asset(Yes.cache)
class StreamingSound
{
public:
    static StreamingSound load(string path);
}*/