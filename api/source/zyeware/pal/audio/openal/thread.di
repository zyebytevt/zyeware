// D import file generated from 'source/zyeware/pal/audio/openal/thread.d'
module zyeware.pal.audio.openal.thread;
import core.thread : Thread, Duration, msecs, thread_detachThis, rt_moduleTlsDtor;
import zyeware.common;
import zyeware.pal.audio.openal.api;
class AudioThread : Thread
{
	protected
	{
		bool mIsRunning;
		void run();
		public
		{
			this();
			void stop();
		}
	}
}
