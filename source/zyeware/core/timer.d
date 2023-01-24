// This file is part of the ZyeWare Game Engine, and subject to the terms
// and conditions defined in the file 'LICENSE.txt', which is part
// of this source code package.
//
// Copyright 2021 ZyeByte
module zyeware.core.timer;

import core.time;
import std.exception : collectException;
import std.typecons : Tuple, Flag, Yes, No;
import std.algorithm : remove, countUntil;

import zyeware.common;

/// A timer is used to call a callback function after a specified
/// amount of time has passed. It can be set to trigger only once,
/// or repeatedly.
/// <b>Note:</b> This class only works properly if `ZyeWare` is actually running.
///
/// See_Also: ZyeWare
final class Timer
{
private:
    alias TimerEntry = Tuple!(Timer, "timer", Duration, "timeLeft");

    bool mIsRunning;
    bool mOneshot;
    Duration mInterval;
    Callback mCallback;

    static TimerEntry[] sTimerEntries;

package(zyeware.core):
    static void tickEntries(FrameTime frameTime)
    {
        for (size_t i; i < sTimerEntries.length; ++i)
        {
            TimerEntry* entry = &sTimerEntries[i];
            entry.timeLeft -= frameTime.deltaTime;

            if (entry.timeLeft <= Duration.zero)
            {
                Timer timer = entry.timer;

                if (timer.mCallback)
                    timer.mCallback(timer);

                if (timer.mOneshot)
                {
                    sTimerEntries[i] = sTimerEntries[$ - 1];
                    sTimerEntries[$ - 1].timer = null;
                    --sTimerEntries.length;
                    --i;
                    continue;
                }
                else
                    entry.timeLeft = timer.mInterval;
            }
        }
    }

public:
    /// The function type for timer callback.
    alias Callback = void delegate(Timer timer);

    /// Params:
    ///     interval = The time between each callback.
    ///     callback = The callback function.
    ///     oneshot = Whether the timer should repeatedly call the callback or only once.
    ///     autostart = Whether to start the timer immediately after construction.
    this(Duration interval, Callback callback, Flag!"oneshot" oneshot = No.oneshot,
        Flag!"autostart" autostart = No.autostart) nothrow
        in (callback, "Callback cannot be null.")
    {
        mInterval = interval;
        mCallback = callback;
        mOneshot = oneshot;

        if (autostart)
            start();
    }

    /// Starts the timer.
    void start() nothrow
    {
        if (!mIsRunning)
        {
            sTimerEntries ~= TimerEntry(this, mInterval);
            mIsRunning = true;
        }
    }

    /// Stops the timer.
    void stop() nothrow
    {
        auto idx = countUntil!"a.timer is b"(sTimerEntries, this);
        if (idx >= 0)
        {
            sTimerEntries[idx] = sTimerEntries[$ - 1];
            sTimerEntries[$ - 1].timer = null;
            --sTimerEntries.length;
            mIsRunning = false;
        }
    }

    /// The time between each callback.
    Duration interval() pure const nothrow
    {
        return mInterval;
    }

    /// ditto
    void interval(in Duration value) pure nothrow
    {
        mInterval = value;
    }

    /// Whether the timer should repeatedly call the callback or only once.
    bool oneshot() pure const nothrow
    {
        return mOneshot;
    }

    /// ditto
    void oneshot(bool value) pure nothrow
    {
        mOneshot = value;
    }

    /// If the timer is currently running.
    bool isRunning() pure const nothrow
    {
        return mIsRunning;
    }

    /// ditto
    void isRunning(bool value) nothrow
    {
        if (value)
            start();
        else
            stop();
    }
}