// This file is part of the ZyeWare Game Engine, and subject to the terms
// and conditions defined in the file 'LICENSE.txt', which is part
// of this source code package.
//
// Copyright 2021 ZyeByte
module zyeware.core.debugging.profiler;

import std.datetime.stopwatch : StopWatch;
import std.datetime : Duration;

import zyeware.common;

version (Profiling)
struct Profiler
{
private static:
    Result[] sResults;

package(zyeware) static:
    RenderData sRenderData;
    ushort sFPS;

    void initialize() nothrow
    {
        sResults.reserve(200);
    }

    void clear() nothrow
    {
        sResults.length = 0;
        sRenderData = RenderData.init;
    }

public static:
    struct Result
    {
        immutable string name;
        immutable Duration duration;
    }

    struct Timer
    {
    private:
        StopWatch mWatch;
        immutable string mName;

    public:
        this(string name) nothrow
            in (name, "Name cannot be null.")
        {
            mName = name;
            if (!mWatch.running)
                mWatch.start();
        }

        void stop() nothrow
        {
            mWatch.stop();

            Profiler.sResults ~= Profiler.Result(mName, mWatch.peek);
        }
    }

    struct RenderData
    {
        size_t drawCalls;
        size_t polygonCount;
        size_t rectCount;
    }

    Result[] results() nothrow
    {
        return sResults;
    }

    RenderData renderData() nothrow
    {
        return sRenderData;
    }

    ushort fps() nothrow
    {
        return sFPS;
    }
}

template ProfileFunction(string customName = null)
{
    static if (!customName)
        enum timerName = "__FUNCTION__";
    else
        enum timerName = customName;

    enum ProfileFunction = `version (Profiling) {
        auto ptimer__ = Profiler.Timer(` ~ timerName ~ `);
        scope (success) ptimer__.stop();
    }`;
}

template ProfileScope(string customName = null)
{
    static if (!customName)
        enum timerName = `__LINE__ ~ " @ " ~ __FUNCTION__`;
    else
        enum timerName = `"` ~ customName ~ `" ~ " @ " ~ __FUNCTION__`;

    enum ProfileScope = `version (Profiling) {
        auto ptimer__ = Profiler.Timer(` ~ timerName ~ `);
        scope (success) ptimer__.stop();
    }`;
}