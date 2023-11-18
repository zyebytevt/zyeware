module zyeware.pal.audio.api;

import std.sumtype : match;
import std.exception : enforce;
import std.algorithm : remove;
import std.string : fromStringz;

import bindbc.openal;
import audioformats;

import zyeware.common;
import zyeware.pal.audio.types;
import zyeware.pal.audio.callbacks;
import zyeware.pal.audio.thread;

public:

ALCdevice* pDevice;
ALCcontext* pContext;
BusData[string] pBusses;
AudioThread pAudioThread;

// This function is essentially noGC, but it's not marked as such because the array
// is initialized the first time the function is called.
size_t palReadShortsFromDecoder(ref AudioStream decoder, ref short[] buffer)
    in (decoder.isOpenForReading(), "Tried to decode while decoder is not open for reading.")
{
    static float[] readBuffer;
    if (!readBuffer)
        readBuffer = new float[ZyeWare.projectProperties.audioBufferSize];

    size_t readCount = decoder.readSamplesFloat(&readBuffer[0], cast(int)(readBuffer.length/decoder.getNumChannels()))
        * decoder.getNumChannels();

    for (size_t i; i < readCount; ++i)
        buffer[i] = cast(short) (readBuffer[i] * short.max);

    return readCount;
}

void palUpdateSourcesWithBus(in BusData* bus)
{
    foreach (source; pSources)
    {
        if (source.bus is bus)
            alSourcef(source.id, AL_GAIN, source.volume * bus.volume);
    }
}

__gshared SourceData*[] pSources;

struct BufferData
{
    const(ubyte[]) encodedMemory;
    LoopPoint loopPoint;
}

struct SourceData
{
    uint id;
    uint[] bufferIds;
    short[] processingBuffer;
    int processedCount;

    float volume = 1f;
    float pitch = 1f;
    bool isLooping;

    SourceState state;

    AudioStream decoder;
    const(BufferData)* bufferData;
    const(BusData)* bus;
}

struct BusData
{
    string name;
    float volume = 1f;
}

void palInitialize()
{
    palLoadLibraries();

    Logger.pal.log(LogLevel.info, "OpenAL initialized:");
    Logger.pal.log(LogLevel.info, "    Version: %s", alGetString(AL_VERSION).fromStringz);
    Logger.pal.log(LogLevel.info, "    Vendor: %s", alGetString(AL_VENDOR).fromStringz);
    Logger.pal.log(LogLevel.info, "    Renderer: %s", alGetString(AL_RENDERER).fromStringz);
    Logger.pal.log(LogLevel.info, "    Extensions: %s", alGetString(AL_EXTENSIONS).fromStringz);

    enforce!AudioException(pDevice = alcOpenDevice(null), "Failed to create audio device.");
    enforce!AudioException(pContext = alcCreateContext(pDevice, null), "Failed to create audio context.");

    enforce!AudioException(alcMakeContextCurrent(pContext), "Failed to make audio context current.");

    pAudioThread = new AudioThread();
    pAudioThread.start();

    Logger.pal.log(LogLevel.info, "Audio thread started.");
}

void palLoadLibraries()
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

void palCleanup()
{
    pAudioThread.stop();
    pAudioThread.join();
    
    alcCloseDevice(pDevice);

    Logger.pal.log(LogLevel.info, "Audio thread stopped, OpenAL terminated.");
}

NativeHandle palCreateSource(in NativeHandle busHandle)
{
    auto source = new SourceData();

    source.bufferIds = new uint[ZyeWare.projectProperties.audioBufferCount];
    source.processingBuffer = new short[ZyeWare.projectProperties.audioBufferSize];
    source.bus = cast(const(BusData*)) busHandle;

    alGenSources(1, &source.id);
    alGenBuffers(cast(uint) source.bufferIds.length, &source.bufferIds[0]);
    alSourcef(source.id, AL_GAIN, source.volume * source.bus.volume);

    pSources ~= source;

    return cast(NativeHandle) source;
}

void palFreeSource(NativeHandle handle)
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

NativeHandle palCreateBuffer(in ubyte[] encodedMemory, in AudioProperties properties)
{
    return cast(NativeHandle) new BufferData(encodedMemory, properties.loopPoint);
}

void palFreeBuffer(NativeHandle handle)
{
    destroy(handle);
}

NativeHandle palCreateBus(string name)
{
    pBusses[name] = BusData(name);
    return cast(NativeHandle) (name in pBusses);
}

void palFreeBus(NativeHandle handle)
{
    auto bus = cast(BusData*) handle;
    pBusses.remove(bus.name);
    destroy(bus);
}

void palSetBufferLoopPoint(NativeHandle handle, in LoopPoint loopPoint)
{
    auto buffer = cast(BufferData*) handle;

    buffer.loopPoint = loopPoint;
}

LoopPoint palGetBufferLoopPoint(in NativeHandle handle) nothrow
{
    auto buffer = cast(BufferData*) handle;

    return buffer.loopPoint;
}

void palSetSourceBuffer(NativeHandle sourceHandle, in NativeHandle bufferHandle)
{
    auto source = cast(SourceData*) sourceHandle;

    if (source.state != SourceState.stopped)
        palStopSource(sourceHandle);

    source.bufferData = cast(BufferData*) bufferHandle;

    source.decoder.openFromMemory(source.bufferData.encodedMemory);
    if (source.decoder.isError)
        throw new AudioException(source.decoder.errorMessage);
}

void palSetSourceBus(NativeHandle sourceHandle, in NativeHandle busHandle)
{
    auto source = cast(SourceData*) sourceHandle;
    auto bus = cast(const(BusData*)) busHandle;

    source.bus = bus;
}

void palPlaySource(NativeHandle handle)
{
    auto source = cast(SourceData*) handle;

    if (source.state == SourceState.playing)
        palStopSource(handle);

    if (source.state == SourceState.stopped)
    {
        size_t lastReadLength;
        for (size_t i; i < source.bufferIds.length; ++i)
        {
            lastReadLength = palReadShortsFromDecoder(source.decoder, source.processingBuffer);
            
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

void palPauseSource(NativeHandle handle)
{
    auto source = cast(SourceData*) handle;

    if (source.state != SourceState.playing)
        return;

    source.state = SourceState.paused;
    alSourcePause(source.id);
}

void palStopSource(NativeHandle handle)
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

void palUpdateSourceBuffers(NativeHandle handle)
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

        size_t lastReadLength = palReadShortsFromDecoder(source.decoder, source.processingBuffer);

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

                lastReadLength = palReadShortsFromDecoder(source.decoder, source.processingBuffer);
            }
            else
            {
                palStopSource(handle);
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

void palSetSourceVolume(NativeHandle handle, float volume)
{
    auto source = cast(SourceData*) handle;

    source.volume = volume;
    alSourcef(source.id, AL_GAIN, volume * source.bus.volume);
}

void palSetSourcePitch(NativeHandle handle, float pitch)
{
    auto source = cast(SourceData*) handle;

    source.pitch = pitch;
    alSourcef(source.id, AL_PITCH, pitch);
}

void palSetSourceLooping(NativeHandle handle, bool isLooping)
{
    auto source = cast(SourceData*) handle;

    source.isLooping = isLooping;
}

float palGetSourceVolume(in NativeHandle handle) nothrow
{
    auto source = cast(SourceData*) handle;

    return source.volume;
}

float palGetSourcePitch(in NativeHandle handle) nothrow
{
    auto source = cast(SourceData*) handle;

    return source.pitch;
}

bool palGetSourceLooping(in NativeHandle handle) nothrow
{
    auto source = cast(SourceData*) handle;

    return source.isLooping;
}

SourceState palGetSourceState(in NativeHandle handle) nothrow
{
    auto source = cast(SourceData*) handle;

    return source.state;
}

void palSetBusVolume(NativeHandle handle, float volume)
{
    auto bus = cast(BusData*) handle;

    bus.volume = volume;
    palUpdateSourcesWithBus(bus);
}

float palGetBusVolume(in NativeHandle handle) nothrow
{
    auto bus = cast(BusData*) handle;

    return bus.volume;
}

AudioPal palGenerateCallbacks()
{
    return AudioPal(
        &palInitialize,
        &palLoadLibraries,
        &palCleanup,
        &palCreateSource,
        &palCreateBuffer,
        &palCreateBus,
        &palFreeSource,
        &palFreeBuffer,
        &palFreeBus,
        &palSetBufferLoopPoint,
        &palGetBufferLoopPoint,
        &palSetSourceBuffer,
        &palSetSourceBus,
        &palSetSourceVolume,
        &palSetSourcePitch,
        &palSetSourceLooping,
        &palGetSourceVolume,
        &palGetSourcePitch,
        &palGetSourceLooping,
        &palGetSourceState,
        &palPlaySource,
        &palPauseSource,
        &palStopSource,
        &palSetBusVolume,
        &palGetBusVolume,
        &palUpdateSourceBuffers,
    );
}

shared static this()
{
    import std.stdio;
    writeln("OpenAL Pal initialized lol.");
}