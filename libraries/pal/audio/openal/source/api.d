// This file is part of the ZyeWare Game Engine, and subject to the terms
// and conditions defined in the file 'LICENSE.txt', which is part
// of this source code package.
//
// Copyright 2021 ZyeByte
module zyeware.pal.audio.openal.api;

import std.sumtype : match;
import std.exception : enforce;
import std.algorithm : remove;
import std.string : fromStringz;

import bindbc.openal;
import audioformats;

import zyeware;
import zyeware.pal;
import zyeware.pal.audio.openal.types;
import zyeware.pal.audio.openal.thread;

package(zyeware.pal.audio.openal):

enum audioBufferSize = 4096 * 4;
enum audioBufferCount = 4;

ALCdevice* pDevice;
ALCcontext* pContext;
BusData[string] pBusses;
AudioThread pAudioThread;
__gshared SourceData*[] pSources;

// This function is essentially noGC, but it's not marked as such because the array
// is initialized the first time the function is called.
size_t readShortsFromDecoder(ref AudioStream decoder, ref short[] buffer)
    in (decoder.isOpenForReading(), "Tried to decode while decoder is not open for reading.")
{
    static float[] readBuffer;
    if (!readBuffer)
        readBuffer = new float[audioBufferSize];

    size_t readCount = decoder.readSamplesFloat(&readBuffer[0], cast(int)(readBuffer.length/decoder.getNumChannels()))
        * decoder.getNumChannels();

    for (size_t i; i < readCount; ++i)
        buffer[i] = cast(short) (readBuffer[i] * short.max);

    return readCount;
}

void updateSourcesWithBus(in BusData* bus)
{
    foreach (source; pSources)
    {
        if (source.bus is bus)
            alSourcef(source.id, AL_GAIN, source.volume * bus.volume);
    }
}

void initialize()
{
    loadLibraries();

    enforce!AudioException(pDevice = alcOpenDevice(null), "Failed to create audio device.");
    enforce!AudioException(pContext = alcCreateContext(pDevice, null), "Failed to create audio context.");

    enforce!AudioException(alcMakeContextCurrent(pContext), "Failed to make audio context current.");

    Logger.pal.log(LogLevel.info, "Initialized OpenAL:");
    Logger.pal.log(LogLevel.info, "    Version: %s", alGetString(AL_VERSION).fromStringz);
    Logger.pal.log(LogLevel.info, "    Vendor: %s", alGetString(AL_VENDOR).fromStringz);
    Logger.pal.log(LogLevel.info, "    Renderer: %s", alGetString(AL_RENDERER).fromStringz);
    Logger.pal.log(LogLevel.info, "    Extensions: %s", alGetString(AL_EXTENSIONS).fromStringz);

    pAudioThread = new AudioThread();
    pAudioThread.start();

    Logger.pal.log(LogLevel.info, "Audio thread started.");
}

void loadLibraries()
{
    import loader = bindbc.loader.sharedlib;
    import std.string : fromStringz;

    if (isOpenALLoaded())
        return;

    immutable alResult = loadOpenAL();
    if (alResult != alSupport)
    {
        foreach (info; loader.errors)
            Logger.pal.log(LogLevel.warning, "OpenAL loader: %s", info.message.fromStringz);

        switch (alResult)
        {
        case ALSupport.noLibrary:
            throw new AudioException("Could not find OpenAL shared library.");

        case ALSupport.badLibrary:
            throw new AudioException("Provided OpenAL shared is corrupted.");

        default:
            Logger.pal.log(LogLevel.warning, "Got older OpenAL version than expected. This might lead to errors.");
        }
    }
}

void cleanup()
{
    pAudioThread.stop();
    pAudioThread.join();
    
    alcCloseDevice(pDevice);

    Logger.pal.log(LogLevel.info, "Audio thread stopped, OpenAL terminated.");
}

NativeHandle createSource(in NativeHandle busHandle)
{
    auto source = new SourceData();

    source.bufferIds = new uint[audioBufferCount];
    source.processingBuffer = new short[audioBufferSize];
    source.bus = cast(const(BusData*)) busHandle;

    alGenSources(1, &source.id);
    alGenBuffers(cast(uint) source.bufferIds.length, &source.bufferIds[0]);
    alSourcef(source.id, AL_GAIN, source.volume * source.bus.volume);

    pSources ~= source;

    return cast(NativeHandle) source;
}

void freeSource(NativeHandle handle)
{
    auto source = cast(SourceData*) handle;

    if (source.decoder.isOpenForReading())
        destroy!false(source.decoder);

    alDeleteBuffers(cast(uint) source.bufferIds.length, &source.bufferIds[0]);
    alDeleteSources(1, &source.id);

    destroy(source.bufferIds);
    destroy(source.processingBuffer);

    for (size_t i; i < pSources.length; ++i)
    {
        if (pSources[i] is source)
        {
            pSources.remove(i);
            break;
        }
    }

    destroy(source);
}

NativeHandle createBuffer(in ubyte[] encodedMemory, in AudioProperties properties)
{
    return cast(NativeHandle) new BufferData(encodedMemory, properties.loopPoint);
}

void freeBuffer(NativeHandle handle)
{
    destroy(handle);
}

NativeHandle createBus(string name)
{
    pBusses[name] = BusData(name);
    return cast(NativeHandle) (name in pBusses);
}

void freeBus(NativeHandle handle)
{
    auto bus = cast(BusData*) handle;
    pBusses.remove(bus.name);
    destroy(bus);
}

void setBufferLoopPoint(NativeHandle handle, in LoopPoint loopPoint)
{
    auto buffer = cast(BufferData*) handle;

    buffer.loopPoint = loopPoint;
}

LoopPoint getBufferLoopPoint(in NativeHandle handle) nothrow
{
    auto buffer = cast(BufferData*) handle;

    return buffer.loopPoint;
}

void setSourceBuffer(NativeHandle sourceHandle, in NativeHandle bufferHandle)
{
    auto source = cast(SourceData*) sourceHandle;

    if (source.state != SourceState.stopped)
        stopSource(sourceHandle);

    source.bufferData = cast(BufferData*) bufferHandle;

    source.decoder.openFromMemory(source.bufferData.encodedMemory);
    if (source.decoder.isError)
        throw new AudioException(source.decoder.errorMessage);
}

void setSourceBus(NativeHandle sourceHandle, in NativeHandle busHandle)
{
    auto source = cast(SourceData*) sourceHandle;
    auto bus = cast(const(BusData*)) busHandle;

    source.bus = bus;
}

void playSource(NativeHandle handle)
{
    auto source = cast(SourceData*) handle;

    if (source.state == SourceState.playing)
        stopSource(handle);

    if (source.state == SourceState.stopped)
    {
        size_t lastReadLength;
        for (size_t i; i < source.bufferIds.length; ++i)
        {
            lastReadLength = readShortsFromDecoder(source.decoder, source.processingBuffer);
            
            alBufferData(source.bufferIds[i],
                source.decoder.getNumChannels() == 1 ? AL_FORMAT_MONO16 : AL_FORMAT_STEREO16,
                &source.processingBuffer[0], cast(int) (lastReadLength * short.sizeof),
                cast(int) source.decoder.getSamplerate());
            
            alSourceQueueBuffers(source.id, 1, &source.bufferIds[i]);
        }
    }

    source.state = SourceState.playing;
    alSourcePlay(source.id);
}

void pauseSource(NativeHandle handle)
{
    auto source = cast(SourceData*) handle;

    if (source.state != SourceState.playing)
        return;

    source.state = SourceState.paused;
    alSourcePause(source.id);
}

void stopSource(NativeHandle handle)
{
    auto source = cast(SourceData*) handle;

    if (source.state == SourceState.stopped)
        return;

    source.state = SourceState.stopped;
    alSourceStop(source.id);

    if (source.decoder.isOpenForReading())
        source.decoder.seekPosition(0);

    int bufferCount;
    alGetSourcei(source.id, AL_BUFFERS_QUEUED, &bufferCount);
    
    for (size_t i; i < bufferCount; ++i)
    {
        uint removedBuffer;
        alSourceUnqueueBuffers(source.id, 1, &removedBuffer);
    }
}

void updateSourceBuffers(NativeHandle handle)
{
    auto source = cast(SourceData*) handle;

    if (source.state != SourceState.playing)
        return;

    int processedCount;
    alGetSourcei(source.id, AL_BUFFERS_PROCESSED, &processedCount);

    if (processedCount == 0)
        return;

    int bufferCount;
    alGetSourcei(source.id, AL_BUFFERS_QUEUED, &bufferCount);

    while (processedCount > 0)
    {
        uint removedBuffer;
        alSourceUnqueueBuffers(source.id, 1, &removedBuffer);

        size_t lastReadLength = readShortsFromDecoder(source.decoder, source.processingBuffer);

        if (lastReadLength <= 0)
        {
            if (source.isLooping)
            {
                source.bufferData.loopPoint.match!(
                    (int sample)
                    {
                        if (!source.decoder.seekPosition(sample))
                            Logger.pal.log(LogLevel.warning, "Seeking to sample %d failed.", sample);
                    },
                    (ModuleLoopPoint mod)
                    {
                        if (!source.decoder.seekPosition(mod.pattern, mod.row))
                            Logger.pal.log(LogLevel.warning, "Seeking to pattern %d, row %d failed.", mod.pattern, mod.row);
                    }
                );

                lastReadLength = readShortsFromDecoder(source.decoder, source.processingBuffer);
            }
            else
            {
                stopSource(handle);
                return;
            }
        }

        alBufferData(removedBuffer,
            source.decoder.getNumChannels() == 1 ? AL_FORMAT_MONO16 : AL_FORMAT_STEREO16,
            &source.processingBuffer[0], cast(int) (lastReadLength * short.sizeof),
            cast(int) source.decoder.getSamplerate());

        alSourceQueueBuffers(source.id, 1, &removedBuffer);

        --processedCount;
    }
}

void setSourceVolume(NativeHandle handle, float volume)
{
    auto source = cast(SourceData*) handle;

    source.volume = volume;
    alSourcef(source.id, AL_GAIN, volume * source.bus.volume);
}

void setSourcePitch(NativeHandle handle, float pitch)
{
    auto source = cast(SourceData*) handle;

    source.pitch = pitch;
    alSourcef(source.id, AL_PITCH, pitch);
}

void setSourceLooping(NativeHandle handle, bool isLooping)
{
    auto source = cast(SourceData*) handle;

    source.isLooping = isLooping;
}

float getSourceVolume(in NativeHandle handle) nothrow
{
    auto source = cast(SourceData*) handle;

    return source.volume;
}

float getSourcePitch(in NativeHandle handle) nothrow
{
    auto source = cast(SourceData*) handle;

    return source.pitch;
}

bool getSourceLooping(in NativeHandle handle) nothrow
{
    auto source = cast(SourceData*) handle;

    return source.isLooping;
}

SourceState getSourceState(in NativeHandle handle) nothrow
{
    auto source = cast(SourceData*) handle;

    return source.state;
}

void setBusVolume(NativeHandle handle, float volume)
{
    auto bus = cast(BusData*) handle;

    bus.volume = volume;
    updateSourcesWithBus(bus);
}

float getBusVolume(in NativeHandle handle) nothrow
{
    auto bus = cast(BusData*) handle;

    return bus.volume;
}