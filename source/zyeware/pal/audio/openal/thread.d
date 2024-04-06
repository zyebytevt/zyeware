// This file is part of the ZyeWare Game Engine, and subject to the terms
// and conditions defined in the file 'LICENSE.txt', which is part
// of this source code package.
//
// Copyright 2021 ZyeByte
module zyeware.pal.audio.openal.thread;
version (ZW_PAL_OPENAL)  :  //import core.thread : Thread, Duration, msecs, thread_detachThis, rt_moduleTlsDtor;

import core.thread;

import zyeware;
import zyeware.pal.audio.openal.api : audioBufferCount, audioBufferSize,
    updateSourceBuffers, pSources;
import zyeware.pal.audio.openal.types;

package:

class AudioThread
{
protected:
    ThreadID mThreadID;
    bool mIsRunning;

    void run() nothrow
    {
        // Determine the sleep time between updating the buffers.
        // YukieVT supplied the following formula for this:
        //     (BuffTotalLen / BuffCount) / SampleRate / 2 * 1000
        // We assume a default sample rate of 44100 for audio.

        immutable Duration waitTime = msecs(audioBufferSize / audioBufferCount / 44_100 / 2 * 1000);

        while (mIsRunning)
        {
            foreach (SourceData* sourceData; pSources)
            {
                updateSourceBuffers(sourceData);
            }

            Thread.sleep(waitTime);
        }
    }

public:
    void start()
    {
        mIsRunning = true;
        mThreadID = createLowLevelThread(&run);
        enforce!AudioException(mThreadID != ThreadID.init, "Failed to create audio thread.");
    }

    void stop()
    {
        mIsRunning = false;
        joinLowLevelThread(mThreadID);
    }
}
