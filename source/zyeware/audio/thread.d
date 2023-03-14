module zyeware.audio.thread;

import core.thread : Thread, Duration, msecs, thread_detachThis, rt_moduleTlsDtor;
import std.algorithm : countUntil, remove;

import zyeware.common;
import zyeware.audio;
import zyeware.core.weakref;

debug import std.stdio;

package(zyeware)
struct AudioThread
{
private static:
    Thread sThread;
    
    __gshared WeakReference!AudioSource[64] sRegisteredSources;
    __gshared size_t sRegisteredSourcesPointer;
    __gshared bool sRunning;
    __gshared Object sMutex = new Object();

    void threadBody()
    {
        thread_detachThis();
        // Just as a safety precaution, we want to call the TLS destructors.
        scope (exit) rt_moduleTlsDtor();

        // Determine the sleep time between updating the buffers.
        // YukieVT supplied the following formula for this:
        //     (BuffTotalLen / BuffCount) / SampleRate / 2 * 1000
        // We assume a default sample rate of 44100 for audio.

        immutable Duration waitTime = msecs(ZyeWare.projectProperties.audioBackendProperties.bufferSize
            / ZyeWare.projectProperties.audioBackendProperties.bufferCount / 44_100 / 2 * 1000);

        while (sRunning)
        {
            synchronized (sMutex)
            {
                for (size_t i; i < sRegisteredSourcesPointer; ++i)
                {
                    if (!sRegisteredSources[i].alive)
                    {
                        debug writefln("Removing source #%d...", i);
                        sRegisteredSources[i] = sRegisteredSources[sRegisteredSourcesPointer - 1];
                        --sRegisteredSourcesPointer;
                        --i;
                        continue;
                    }

                    sRegisteredSources[i].target.updateBuffers();
                }
            }
            
            Thread.sleep(waitTime);
        }
    }

package(zyeware):
    void register(AudioSource source)
    {
        synchronized (sMutex)
        {
            assert(sRegisteredSourcesPointer < sRegisteredSources.length, "Cannot add more sources.");
            sRegisteredSources[sRegisteredSourcesPointer++] = weakReference(source);
        }
    }

    void updateVolumeForSources()
    {
        synchronized (sMutex)
        {
            for (size_t i; i < sRegisteredSources.length; ++i)
            {
                if (!sRegisteredSources[i].alive)
                    continue;

                sRegisteredSources[i].target.updateVolume();
            }
        }
    }

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