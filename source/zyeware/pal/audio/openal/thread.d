// This file is part of the ZyeWare Game Engine, and subject to the terms
// and conditions defined in the file 'LICENSE.txt', which is part
// of this source code package.
//
// Copyright 2021 ZyeByte
module zyeware.pal.audio.openal.thread; version(ZW_PAL_OPENAL):

import core.thread : Thread, Duration, msecs, thread_detachThis, rt_moduleTlsDtor;

import zyeware;
import zyeware.pal.audio.openal.api : audioBufferCount, audioBufferSize, updateSourceBuffers, pSources;
import zyeware.pal.audio.openal.types;

package:

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

        immutable Duration waitTime = msecs(audioBufferSize / audioBufferCount / 44_100 / 2 * 1000);

        while (mIsRunning)
        {
            foreach (SourceData* sourceData; pSources)
                updateSourceBuffers(sourceData);

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
        join();
    }
}