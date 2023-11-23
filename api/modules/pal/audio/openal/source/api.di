// D import file generated from 'modules/pal/audio/openal/source/api.d'
module zyeware.pal.audio.openal.api;
import std.sumtype : match;
import std.exception : enforce;
import std.algorithm : remove;
import std.string : fromStringz;
import bindbc.openal;
import audioformats;
import zyeware.common;
import zyeware.pal;
import zyeware.pal.audio.openal.types;
import zyeware.pal.audio.openal.thread;
package(zyeware.pal.audio.openal)
{
	extern ALCdevice* pDevice;
	extern ALCcontext* pContext;
	extern BusData[string] pBusses;
	extern AudioThread pAudioThread;
	extern __gshared SourceData*[] pSources;
	size_t readShortsFromDecoder(ref AudioStream decoder, ref short[] buffer);
	void updateSourcesWithBus(in BusData* bus);
	void initialize();
	void loadLibraries();
	void cleanup();
	NativeHandle createSource(in NativeHandle busHandle);
	void freeSource(NativeHandle handle);
	NativeHandle createBuffer(in ubyte[] encodedMemory, in AudioProperties properties);
	void freeBuffer(NativeHandle handle);
	NativeHandle createBus(string name);
	void freeBus(NativeHandle handle);
	void setBufferLoopPoint(NativeHandle handle, in LoopPoint loopPoint);
	nothrow LoopPoint getBufferLoopPoint(in NativeHandle handle);
	void setSourceBuffer(NativeHandle sourceHandle, in NativeHandle bufferHandle);
	void setSourceBus(NativeHandle sourceHandle, in NativeHandle busHandle);
	void playSource(NativeHandle handle);
	void pauseSource(NativeHandle handle);
	void stopSource(NativeHandle handle);
	void updateSourceBuffers(NativeHandle handle);
	void setSourceVolume(NativeHandle handle, float volume);
	void setSourcePitch(NativeHandle handle, float pitch);
	void setSourceLooping(NativeHandle handle, bool isLooping);
	nothrow float getSourceVolume(in NativeHandle handle);
	nothrow float getSourcePitch(in NativeHandle handle);
	nothrow bool getSourceLooping(in NativeHandle handle);
	nothrow SourceState getSourceState(in NativeHandle handle);
	void setBusVolume(NativeHandle handle, float volume);
	nothrow float getBusVolume(in NativeHandle handle);
}
