// This file is part of the ZyeWare Game Engine, and subject to the terms
// and conditions defined in the file 'LICENSE.txt', which is part
// of this source code package.
//
// Copyright 2021 ZyeByte
module zyeware.core.debugging.profiler;

import std.datetime.stopwatch : StopWatch;
import std.datetime : Duration;

import zyeware.common;

version (ZW_Profiling):

/// Contains various functions for profiling.
struct Profiler
{
private static:
    Data[2] sData;
    size_t sReadDataPointer;
    size_t sWriteDataPointer = 1;

package(zyeware) static:
    struct Data
    {
        RenderData renderData;
        Result[] results;
    }

    struct RenderData
    {
        size_t drawCalls;
        size_t polygonCount;
        size_t rectCount;
    }

    ushort sFPS;

    void initialize() nothrow
    {
    }

    void clearAndSwap() nothrow
    {
        if (++sReadDataPointer == sData.length)
            sReadDataPointer = 0;

        if (++sWriteDataPointer == sData.length)
            sWriteDataPointer = 0;

        Data* data = currentWriteData;

        data.results.length = 0;
        data.renderData = RenderData.init;
    }

public static:
    struct Result
    {
        immutable string name;
        immutable Duration duration;
    }

    /// Represents a profiling timer, allowing easy profiling of code sections.
    /// Use the mixins `ProfileScope` and `ProfileFunction` for convenience.
    struct Timer
    {
    private:
        StopWatch mWatch;
        immutable string mName;

    public:
        /// Params:
        ///   name = The name of the section that is timed.
        this(string name) nothrow
            in (name, "Name cannot be null.")
        {
            mName = name;
            if (!mWatch.running)
                mWatch.start();
        }

        /// Stops the timer.
        void stop() nothrow
        {
            mWatch.stop();

            Profiler.currentWriteData.results ~= Profiler.Result(mName, mWatch.peek);
        }
    }

    /// Returns the profiling data from last frame. This should only be read from.
    const(Data)* currentReadData() nothrow
    {
        return &sData[sReadDataPointer];
    }

    /// Returns the profiling data of the current frame. This should only be written to.
    Data* currentWriteData() nothrow
    {
        return &sData[sWriteDataPointer];
    }

    /// The current frames per second.
    ushort fps() nothrow
    {
        return sFPS;
    }
}

/// Convenience mixin template that creates a profiling timer for the
/// current function. If not assigned a custom name, it will take
/// the pretty name of the function.
template ProfileFunction(string customName = null)
{
    static if (!customName)
        enum timerName = "__FUNCTION__";
    else
        enum timerName = customName;

    enum ProfileFunction = `version (ZW_Profiling) {
        auto ptimer__ = Profiler.Timer(` ~ timerName ~ `);
        scope (success) ptimer__.stop();
    }`;
}

/// Convenience mixin template that creates a profiling timer for
/// the enclosing scope. The name will always contain the function,
/// and if not given a custom name, also contains the line number.
template ProfileScope(string customName = null)
{
    static if (!customName)
        enum timerName = `__LINE__ ~ " @ " ~ __FUNCTION__`;
    else
        enum timerName = `"` ~ customName ~ `" ~ " @ " ~ __FUNCTION__`;

    enum ProfileScope = `version (ZW_Profiling) {
        auto ptimer__ = Profiler.Timer(` ~ timerName ~ `);
        scope (success) ptimer__.stop();
    }`;
}