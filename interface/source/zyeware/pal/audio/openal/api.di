// D import file generated from 'source/zyeware/pal/audio/openal/api.d'
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
private
{
	extern ALCdevice* pDevice;
	extern ALCcontext* pContext;
	extern BusData[string] pBusses;
	extern AudioThread pAudioThread;
	size_t palAlReadShortsFromDecoder(ref AudioStream decoder, ref short[] buffer);
	void palAlUpdateSourcesWithBus(in BusData* bus);
	package(zyeware.pal)
	{
		extern __gshared SourceData*[] pSources;
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
			float volume = 1.0F;
			float pitch = 1.0F;
			bool isLooping;
			SourceState state;
			AudioStream decoder;
			const(BufferData)* bufferData;
			const(BusData)* bus;
		}
		struct BusData
		{
			string name;
			float volume = 1.0F;
		}
		void palAlInitialize();
		void palAlLoadLibraries();
		void palAlCleanup();
		NativeHandle palAlCreateSource(in NativeHandle busHandle);
		void palAlFreeSource(NativeHandle handle);
		NativeHandle palAlCreateBuffer(in ubyte[] encodedMemory, in AudioProperties properties);
		void palAlFreeBuffer(NativeHandle handle);
		NativeHandle palAlCreateBus(string name);
		void palAlFreeBus(NativeHandle handle);
		void palAlSetBufferLoopPoint(NativeHandle handle, in LoopPoint loopPoint);
		nothrow LoopPoint palAlGetBufferLoopPoint(in NativeHandle handle);
		void palAlSetSourceBuffer(NativeHandle sourceHandle, in NativeHandle bufferHandle);
		void palAlSetSourceBus(NativeHandle sourceHandle, in NativeHandle busHandle);
		void palAlPlaySource(NativeHandle handle);
		void palAlPauseSource(NativeHandle handle);
		void palAlStopSource(NativeHandle handle);
		void palAlUpdateSourceBuffers(NativeHandle handle);
		void palAlSetSourceVolume(NativeHandle handle, float volume);
		void palAlSetSourcePitch(NativeHandle handle, float pitch);
		void palAlSetSourceLooping(NativeHandle handle, bool isLooping);
		nothrow float palAlGetSourceVolume(in NativeHandle handle);
		nothrow float palAlGetSourcePitch(in NativeHandle handle);
		nothrow bool palAlGetSourceLooping(in NativeHandle handle);
		nothrow SourceState palAlGetSourceState(in NativeHandle handle);
		void palAlSetBusVolume(NativeHandle handle, float volume);
		nothrow float palAlGetBusVolume(in NativeHandle handle);
		public AudioPALCallbacks palAlGenerateCallbacks();
	}
}
