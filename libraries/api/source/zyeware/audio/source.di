// D import file generated from 'source/zyeware/audio/source.d'
module zyeware.audio.source;
import zyeware.common;
import zyeware.audio;
import zyeware.pal;
import zyeware.pal.audio.types;
class AudioSource : NativeObject
{
	protected
	{
		NativeHandle mNativeHandle;
		AudioBuffer mBuffer;
		public
		{
			this(in AudioBus bus);
			void play();
			void pause();
			void stop();
			inout inout(AudioBuffer) buffer();
			void buffer(AudioBuffer value);
			const nothrow bool looping();
			void looping(bool value);
			const nothrow float volume();
			void volume(float value);
			const nothrow float pitch();
			void pitch(float value);
			const nothrow SourceState state();
			const pure nothrow const(NativeHandle) handle();
		}
	}
}
