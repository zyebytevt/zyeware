module zyeware.core.debugging.info;

import core.memory;

import zyeware;

version (ZW_Profiling)
package(zyeware)
struct DebugInfoManager
{
    @disable this();
    @disable this(this);

private static:
    bool sDebugKeyPressed;

    void logMemoryStatistics() nothrow
    {
        auto stats = GC.stats();
        auto profileStats = GC.profileStats();

        Logger.core.log(LogLevel.debug_, "========== [ MEMORY STATISTICS ] ==========");
        Logger.core.log(LogLevel.debug_, "Used memory: %d bytes (%s)", stats.usedSize, bytesToString(stats.usedSize));
        Logger.core.log(LogLevel.debug_, "Free memory for allocation: %d bytes (%s)", stats.freeSize,
            bytesToString(stats.freeSize));
        Logger.core.log(LogLevel.debug_, "Allocated in current thread: %d bytes (%s)", stats.allocatedInCurrentThread,
            bytesToString(stats.allocatedInCurrentThread));
        Logger.core.log(LogLevel.debug_, "---------- [ Garbage Collector ] ----------");
        Logger.core.log(LogLevel.debug_, "Collections since startup: %d", profileStats.numCollections);
        Logger.core.log(LogLevel.debug_, "Largest collection time: %d ns", profileStats.maxCollectionTime.total!"nsecs");
        Logger.core.log(LogLevel.debug_, "Total collection time: %d ns", profileStats.totalCollectionTime.total!"nsecs");
        Logger.core.log(LogLevel.debug_, "Largest thread pause: %d ns", profileStats.maxPauseTime.total!"nsecs");
        Logger.core.log(LogLevel.debug_, "Total thread pause: %d ns", profileStats.totalPauseTime.total!"nsecs");
    }

package(zyeware.core) static:
    void receive(InputEventKey key) nothrow
    {
        if (key.keycode == KeyCode.scrolllock)
        {
            sDebugKeyPressed = key.isPressed();
            return;
        }

        if (!sDebugKeyPressed || !key.isPressed())
            return;

        switch (key.keycode)
        {
        case KeyCode.m:
            logMemoryStatistics();
            break;

        default:
        }
    }
}