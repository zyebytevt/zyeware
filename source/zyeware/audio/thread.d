module zyeware.audio.thread;

import core.thread : Thread, msecs;
import std.algorithm : countUntil, remove;

import zyeware.common;
import zyeware.audio;

package(zyeware) struct AudioThread
{
private static:
    Thread sThread;
    
    __gshared AudioSource[] sRegisteredSources;
    __gshared bool sRunning;

    void threadBody()
    {
        while (sRunning)
        {
            foreach (AudioSource source; sRegisteredSources)
                source.updateBuffers();

            // TODO: Check if the buffer is still alive (or smth idk)
            // TODO: Also change sleep time depending on buffer length
            // (BuffTotalLen / BuffCount) / SampleRate / 2 * 1000

            Thread.sleep(10.msecs);
        }
    }

package(zyeware):
    void register(AudioSource source)
    {
        sRegisteredSources ~= source;
    }

    void unregister(AudioSource source)
    {
        sRegisteredSources.removeElement(source);
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