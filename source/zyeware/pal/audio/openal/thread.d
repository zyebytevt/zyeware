module zyeware.pal.audio.openal.thread;

import core.thread : Thread, Duration, msecs, thread_detachThis, rt_moduleTlsDtor;

import zyeware.common;
import zyeware.pal.audio.openal.api;

class AudioThread : Thread
{
protected:
    bool mIsRunning;
    SourceData*[] mSources;

    void run()
    {
        mIsRunning = true;

        thread_detachThis();
        scope (exit) rt_moduleTlsDtor();

        // Determine the sleep time between updating the buffers.
        // YukieVT supplied the following formula for this:
        //     (BuffTotalLen / BuffCount) / SampleRate / 2 * 1000
        // We assume a default sample rate of 44100 for audio.

        immutable Duration waitTime = msecs(ZyeWare.projectProperties.audioBufferSize
            / ZyeWare.projectProperties.audioBufferCount / 44_100 / 2 * 1000);

        while (mIsRunning)
        {
            synchronized (this)
            {
                // TODO: Move the update logic from the statuc AudioThread into here.
                // I tried to make this thread have access to the __gshared sources
                // from the Audio API, but I don't think that's a good idea.
                // Instead, this should still do manual (de)registration of sources,
                // which definitely need to be synchronized. Thanks to this being
                // non-static, we can use the synchronized keyword on this instance.
            }

            Thread.sleep(waitTime);
        }
    }

public:
    this()
    {
        super(&run);
    }

    void stop()
    {
        mIsRunning = false;
    }
}