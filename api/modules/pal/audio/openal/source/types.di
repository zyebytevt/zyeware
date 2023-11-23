// D import file generated from 'modules/pal/audio/openal/source/types.d'
module zyeware.pal.audio.openal.types;
import audioformats;
import zyeware.pal.audio.types;
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
