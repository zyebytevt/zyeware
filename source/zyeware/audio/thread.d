module zyeware.audio.thread;

import core.thread : Thread, Duration, msecs;
import std.algorithm : countUntil, remove;

import zyeware.common;
import zyeware.audio;
import zyeware.core.weakref;

package(zyeware) struct AudioThread
{
private static:
    Thread sThread;
    
    __gshared WeakReference!AudioSource[] sRegisteredSources;
    __gshared bool sRunning;

    void threadBody()
    {
        // Determine the sleep time between updating the buffers.
        // YukieVT supplied the following formula for this:
        //     (BuffTotalLen / BuffCount) / SampleRate / 2 * 1000
        // We assume a default sample rate of 44100 for audio.

        immutable Duration waitTime = msecs(ZyeWare.projectProperties.audioBufferSize
            / ZyeWare.projectProperties.audioBufferCount / 44_100 / 2 * 1000);

        while (sRunning)
        {
            for (size_t i; i < sRegisteredSources.length; ++i)
            {
                if (!sRegisteredSources[i].alive)
                {
                    sRegisteredSources[i] = sRegisteredSources[$ - 1];
                    --i;
                    continue;
                }

                sRegisteredSources[i].target.updateBuffers();
            }
            
            Thread.sleep(waitTime);
        }
    }

package(zyeware):
    void register(AudioSource source)
    {
        sRegisteredSources ~= weakReference(source);
    }

    void updateVolumeForSources() nothrow
    {
        for (size_t i; i < sRegisteredSources.length; ++i)
        {
            if (!sRegisteredSources[i].alive)
                continue;

            sRegisteredSources[i].target.updateVolume();
        }
    }

public static:
    void initialize()
    {
        sRunning = true;
        sThread = new Thread(&threadBody);
        sThread.start();
    }

    void cleanup()
    {
        sRunning = false;
        sThread.join(true);
    }
}