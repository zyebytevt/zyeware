module zyeware.pal.audio.callbacks;

import zyeware.common;
import zyeware.pal.audio.types;

struct AudioDriver
{
public:
    void function() initialize;
    void function() loadLibraries;
    void function() cleanup;

    NativeHandle function(in NativeHandle busHandle) createSource;
    NativeHandle function(in ubyte[] encodedMemory, in AudioProperties properties) createBuffer;
    NativeHandle function(string name) createBus;

    void function(NativeHandle handle) freeSource;
    void function(NativeHandle handle) freeBuffer;
    void function(NativeHandle handle) freeBus;

    void function(NativeHandle handle, in LoopPoint loopPoint) setBufferLoopPoint;
    LoopPoint function(in NativeHandle handle) nothrow getBufferLoopPoint;

    void function(NativeHandle sourceHandle, in NativeHandle bufferHandle) setSourceBuffer;
    void function(NativeHandle sourceHandle, in NativeHandle busHandle) setSourceBus;
    void function(NativeHandle handle, float volume) setSourceVolume;
    void function(NativeHandle handle, float pitch) setSourcePitch;
    void function(NativeHandle handle, bool isLooping) setSourceLooping;
    float function(in NativeHandle handle) nothrow getSourceVolume;
    float function(in NativeHandle handle) nothrow getSourcePitch;
    bool function(in NativeHandle handle) nothrow isSourceLooping;
    SourceState function(in NativeHandle handle) nothrow getSourceState;

    void function(NativeHandle handle) playSource;
    void function(NativeHandle handle) pauseSource;
    void function(NativeHandle handle) stopSource;

    void function(NativeHandle handle, float volume) setBusVolume;
    float function(in NativeHandle handle) nothrow getBusVolume;

    void function(NativeHandle handle) updateSourceBuffers;
}