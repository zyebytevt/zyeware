// This file is part of the ZyeWare Game Engine, and subject to the terms
// and conditions defined in the file 'LICENSE.txt', which is part
// of this source code package.
//
// Copyright 2021 ZyeByte
module zyeware.core.logging;

import core.stdc.stdio : printf;
import std.stdio : File, stdout;
import std.datetime : TimeOfDay, Clock;
import std.string : fromStringz;
import std.format : format, sformat;
import std.traits : isSomeString;
import std.algorithm : remove, SwapStrategy;
import std.conv : dtext;

import terminal;

import zyeware.common;


// LogLevel usage is as follows:
// 
// Fatal:      Extremely severe incidents which almost certainly are followed by a crash.
// Error:      Severe incidents that can impact the stability of the application.
// Warning:    Incidents that can impact the usability of the application.
// Info:       Messages with useful information when troubleshooting, but which have no
//             visible effect on the application itself.
// Debug:      Messages useful for debugging, containing information a normal user wouldn't
//             make much sense of.
// Trace:      Used when traversing through code, "tracing" each step with messages.

enum LogLevel
{
    off,
    fatal,
    error,
    warning,
    info,
    debug_,
    trace
}

final class Logger
{
private:
    LogSink[] mSinks;
    LogLevel mLogLevel;
    dstring mName;
    
    static LogSink sDefaultLogSink;
    static Logger sCoreLogger, sClientLogger;

package(zyeware):
    static void initialize(LogLevel coreLevel, LogLevel clientLevel)
    {
        sDefaultLogSink = new TerminalLogSink(new Terminal());

        sCoreLogger = new Logger(sDefaultLogSink, coreLevel, "Core");
        sClientLogger = new Logger(sDefaultLogSink, clientLevel, "Client");
    }

    static Logger core()  nothrow
    {
        return sCoreLogger;
    }

public:
    this(LogSink baseSink, LogLevel logLevel, dstring name) pure
    {
        addSink(baseSink);

        mLogLevel = logLevel;
        mName = name;
    }

    void addSink(LogSink sink) @trusted pure
    {
        mSinks ~= sink;
    }

    void removeSink(LogSink sink) @trusted
    {
        for (size_t i; i < mSinks.length; ++i)
            if (mSinks[i] == sink)
            {
                mSinks.remove!(SwapStrategy.stable)(i);
                return;
            }
    }

    void log(S, T...)(LogLevel level, S message, T args) nothrow
        if (isSomeString!S)
    {
        static char[2048] formatted;

        if (level > mLogLevel)
            return;
        
        try
        {
            immutable dstring text = sformat(formatted, message, args).dtext;

            auto data = LogSink.LogData(
                mName,
                level,
                cast(TimeOfDay) Clock.currTime,
                text
            );

            foreach (LogSink sink; mSinks)
                sink.log(data);

            text.dispose();
        }
        catch (Exception ex)
        {
            printf("Logger threw an exception. Could not log.\n");
            ex.dispose();
        }
    }

    void flush() 
    {
        foreach (LogSink sink; mSinks)
            sink.flush();
    }

    static Logger client()  nothrow
    {
        return sClientLogger;
    }

    static LogSink defaultLogSink()  nothrow
    {
        return sDefaultLogSink;
    }
}

abstract class LogSink
{
public:
    struct LogData
    {
        dstring loggerName;
        LogLevel level;
        TimeOfDay time;
        dstring message;
    }

    abstract void log(LogData data);
    abstract void flush() ;
}

class TerminalLogSink : LogSink
{
private:
    Terminal mTerm;

public:
    this(Terminal terminal)
    {
        mTerm = terminal;
    }

    override void log(LogData data)
    {
        static immutable Color[] levelColors = [
            Color.magenta, Color.red, Color.yellow, Color.blue, Color.green,
            Color.gray
        ];
        
        static immutable dstring[] levelNames = [
            "Fatal",
            "Error",
            "Warning",
            "Info",
            "Debug",
            "Trace"
        ];

        Foreground(Color.white);

        mTerm.writeln(
            Foreground(Color.white), format!"[ %-8s ] [ %-6s ] [ "(data.time, data.loggerName),
            
            Foreground(levelColors[data.level - 1]), format!"%-7s"(levelNames[data.level - 1]),
            Foreground(Color.reset), " ] ", data.message
        );
    }

    override void flush() 
    {
        mTerm.file.flush();
    }
}