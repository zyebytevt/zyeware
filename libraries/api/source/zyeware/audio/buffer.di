// D import file generated from 'source/zyeware/audio/buffer.d'
module zyeware.audio.buffer;
import std.conv : to;
import zyeware;
import zyeware.pal;
import zyeware.pal.audio.types;
import zyeware.utils.tokenizer;
@(asset(Yes.cache))class AudioBuffer : NativeObject
{
	protected
	{
		NativeHandle mNativeHandle;
		public
		{
			this(const(ubyte)[] encodedMemory, AudioProperties properties = AudioProperties.init);
			~this();
			const nothrow LoopPoint loopPoint();
			void loopPoint(LoopPoint value);
			const pure nothrow const(NativeHandle) handle();
			static AudioBuffer load(string path);
		}
	}
}
