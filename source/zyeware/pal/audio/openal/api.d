module zyeware.pal.audio.openal.api;

import std.sumtype : match;
import std.exception : enforce;
import std.algorithm : remove;

import bindbc.openal;
import audioformats;

import zyeware.common;
import zyeware.pal.audio.types;
import zyeware.pal.audio.callbacks;
import zyeware.pal.audio.openal.thread;

private:

ALCdevice* pDevice;
ALCcontext* pContext;
BusData[string] pBusses;
AudioThread pAudioThread;

// This function is essentially noGC, but it's not marked as such because the array
// is initialized the first time the function is called.
size_t palAlReadShortsFromDecoder(ref AudioStream decoder, ref short[] buffer)
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

void palAlUpdateSourcesWithBus(in BusData* bus)
{
    foreach (source; pSources)
    {
        if (source.bus is bus)
            alSourcef(source.id, AL_GAIN, source.volume * bus.volume);
    }
}

package(zyeware.pal):

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

void palAlInitialize()
{
    palAlLoadLibraries();

    enforce!AudioException(pDevice = alcOpenDevice(null), "Failed to create audio device.");
    enforce!AudioException(pContext = alcCreateContext(pDevice, null), "Failed to create audio context.");

    enforce!AudioException(alcMakeContextCurrent(pContext), "Failed to make audio context current.");

    pAudioThread = new AudioThread();
    pAudioThread.start();
}

void palAlLoadLibraries()
{
    import loader = bindbc.loader.sharedlib;
    import std.string : fromStringz;

    if (isOpenALLoaded())
        return;

    immutable alResult = loadOpenAL();
    if (alResult != alSupport)
    {
        foreach (info; loader.errors)
            Logger.core.log(LogLevel.warning, "OpenAL loader: %s", info.message.fromStringz);

        switch (alResult)
        {
        case ALSupport.noLibrary:
            throw new AudioException("Could not find OpenAL shared library.");

        case ALSupport.badLibrary:
            throw new AudioException("Provided OpenAL shared is corrupted.");

        default:
            Logger.core.log(LogLevel.warning, "Got older OpenAL version than expected. This might lead to errors.");
        }
    }
}

void palAlCleanup()
{
    pAudioThread.stop();
    pAudioThread.join();
    
    alcCloseDevice(pDevice);
}

NativeHandle palAlCreateSource(in NativeHandle busHandle)
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

void palAlFreeSource(NativeHandle handle)
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

NativeHandle palAlCreateBuffer(in ubyte[] encodedMemory, in AudioProperties properties)
{
    return cast(NativeHandle) new BufferData(encodedMemory, properties.loopPoint);
}

void palAlFreeBuffer(NativeHandle handle)
{
    destroy(handle);
}

NativeHandle palAlCreateBus(string name)
{
    pBusses[name] = BusData(name);
    return cast(NativeHandle) (name in pBusses);
}

void palAlFreeBus(NativeHandle handle)
{
    auto bus = cast(BusData*) handle;
    pBusses.remove(bus.name);
    destroy(bus);
}

void palAlSetBufferLoopPoint(NativeHandle handle, in LoopPoint loopPoint)
{
    auto buffer = cast(BufferData*) handle;

    buffer.loopPoint = loopPoint;
}

LoopPoint palAlGetBufferLoopPoint(in NativeHandle handle) nothrow
{
    auto buffer = cast(BufferData*) handle;

    return buffer.loopPoint;
}

void palAlSetSourceBuffer(NativeHandle sourceHandle, in NativeHandle bufferHandle)
{
    auto source = cast(SourceData*) sourceHandle;

    if (source.state != SourceState.stopped)
        palAlStopSource(sourceHandle);

    source.bufferData = cast(BufferData*) bufferHandle;

    try
    {
        source.decoder.openFromMemory(source.bufferData.encodedMemory);
    }
    catch (AudioFormatsException ex)
    {
        // Copy manually managed memory to GC memory and rethrow exception.
        string errMsg = ex.message.dup;
        string errFile = ex.file.dup;
        size_t errLine = ex.line;
        destroyAudioFormatException(ex);

        throw new AudioException(errMsg, errFile, errLine, null);
    }
}

void palAlSetSourceBus(NativeHandle sourceHandle, in NativeHandle busHandle)
{
    auto source = cast(SourceData*) sourceHandle;
    auto bus = cast(const(BusData*)) busHandle;

    source.bus = bus;
}

void palAlPlaySource(NativeHandle handle)
{
    auto source = cast(SourceData*) handle;

    if (source.state == SourceState.playing)
        palAlStopSource(handle);

    if (source.state == SourceState.stopped)
    {
        size_t lastReadLength;
        for (size_t i; i < source.bufferIds.length; ++i)
        {
            lastReadLength = palAlReadShortsFromDecoder(source.decoder, source.processingBuffer);
            
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

void palAlPauseSource(NativeHandle handle)
{
    auto source = cast(SourceData*) handle;

    if (source.state != SourceState.playing)
        return;

    source.state = SourceState.paused;
    alSourcePause(source.id);
}

void palAlStopSource(NativeHandle handle)
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

void palAlUpdateSourceBuffers(NativeHandle handle)
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

        size_t lastReadLength = palAlReadShortsFromDecoder(source.decoder, source.processingBuffer);

        if (lastReadLength <= 0)
        {
            if (source.isLooping)
            {
                source.bufferData.loopPoint.match!(
                    (int sample)
                    {
                        if (!source.decoder.seekPosition(sample))
                            Logger.core.log(LogLevel.warning, "Seeking to sample %d failed.", sample);
                    },
                    (ModuleLoopPoint mod)
                    {
                        if (!source.decoder.seekPosition(mod.pattern, mod.row))
                            Logger.core.log(LogLevel.warning, "Seeking to pattern %d, row %d failed.", mod.pattern, mod.row);
                    }
                );

                lastReadLength = palAlReadShortsFromDecoder(source.decoder, source.processingBuffer);
            }
            else
            {
                palAlStopSource(handle);
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

void palAlSetSourceVolume(NativeHandle handle, float volume)
{
    auto source = cast(SourceData*) handle;

    source.volume = volume;
    alSourcef(source.id, AL_GAIN, volume * source.bus.volume);
}

void palAlSetSourcePitch(NativeHandle handle, float pitch)
{
    auto source = cast(SourceData*) handle;

    source.pitch = pitch;
    alSourcef(source.id, AL_PITCH, pitch);
}

void palAlSetSourceLooping(NativeHandle handle, bool isLooping)
{
    auto source = cast(SourceData*) handle;

    source.isLooping = isLooping;
}

float palAlGetSourceVolume(in NativeHandle handle) nothrow
{
    auto source = cast(SourceData*) handle;

    return source.volume;
}

float palAlGetSourcePitch(in NativeHandle handle) nothrow
{
    auto source = cast(SourceData*) handle;

    return source.pitch;
}

bool palAlGetSourceLooping(in NativeHandle handle) nothrow
{
    auto source = cast(SourceData*) handle;

    return source.isLooping;
}

SourceState palAlGetSourceState(in NativeHandle handle) nothrow
{
    auto source = cast(SourceData*) handle;

    return source.state;
}

void palAlSetBusVolume(NativeHandle handle, float volume)
{
    auto bus = cast(BusData*) handle;

    bus.volume = volume;
    palAlUpdateSourcesWithBus(bus);
}

float palAlGetBusVolume(in NativeHandle handle) nothrow
{
    auto bus = cast(BusData*) handle;

    return bus.volume;
}

public:

AudioPALCallbacks palAlGenerateCallbacks()
{
    return AudioPALCallbacks(
        &palAlInitialize,
        &palAlLoadLibraries,
        &palAlCleanup,
        &palAlCreateSource,
        &palAlCreateBuffer,
        &palAlCreateBus,
        &palAlFreeSource,
        &palAlFreeBuffer,
        &palAlFreeBus,
        &palAlSetBufferLoopPoint,
        &palAlGetBufferLoopPoint,
        &palAlSetSourceBuffer,
        &palAlSetSourceBus,
        &palAlSetSourceVolume,
        &palAlSetSourcePitch,
        &palAlSetSourceLooping,
        &palAlGetSourceVolume,
        &palAlGetSourcePitch,
        &palAlGetSourceLooping,
        &palAlGetSourceState,
        &palAlPlaySource,
        &palAlPauseSource,
        &palAlStopSource,
        &palAlSetBusVolume,
        &palAlGetBusVolume,
        &palAlUpdateSourceBuffers,
    );
}