// D import file generated from 'source/zyeware/audio/bus.d'
module zyeware.audio.bus;
import std.algorithm : clamp;
import zyeware;
import zyeware.pal;
class AudioBus : NativeObject
{
	private
	{
		static AudioBus[string] sAudioBuses;
		this(string name);
		protected
		{
			string mName;
			NativeHandle mNativeHandle;
			public
			{
				~this();
				const nothrow string name();
				const nothrow float volume();
				void volume(float value);
				const pure nothrow const(NativeHandle) handle();
				static AudioBus create(string name);
				static void remove(string name);
				static nothrow AudioBus get(string name);
			}
		}
	}
}
