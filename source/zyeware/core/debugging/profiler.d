// This file is part of the ZyeWare Game Engine, and subject to the terms
// and conditions defined in the file 'LICENSE.txt', which is part
// of this source code package.
//
// Copyright 2021 ZyeByte
module zyeware.core.debugging.profiler;

import std.datetime.stopwatch : StopWatch;
import std.datetime : Duration;

import zyeware.common;

version (Profiling):

struct Profiler
{
private static:
    Data[2] sData;
    size_t sReadDataPointer;
    size_t sWriteDataPointer = 1;

package(zyeware) static:
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

            Profiler.currentWriteData.results ~= Profiler.Result(mName, mWatch.peek);
        }
    }

    const(Data)* currentReadData() nothrow
    {
        return &sData[sReadDataPointer];
    }

    Data* currentWriteData() nothrow
    {
        return &sData[sWriteDataPointer];
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