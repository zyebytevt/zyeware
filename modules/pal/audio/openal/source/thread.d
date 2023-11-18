module zyeware.pal.audio.thread;

import core.thread : Thread, Duration, msecs, thread_detachThis, rt_moduleTlsDtor;

import zyeware.common;
import zyeware.pal.audio.api;

class AudioThread : Thread
{
protected:
    bool mIsRunning;

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
            foreach (SourceData* sourceData; pSources)
                palUpdateSourceBuffers(sourceData);

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