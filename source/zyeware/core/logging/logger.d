// This file is part of the ZyeWare Game Engine, and subject to the terms
// and conditions defined in the file 'LICENSE.txt', which is part
// of this source code package.
//
// Copyright 2021 ZyeByte
module zyeware.core.logging.logger;

import core.stdc.stdio : printf;
import std.stdio : File, stdout;
import std.datetime : Duration;
import std.string : fromStringz;
import std.traits : isSomeString;
import std.algorithm : remove, SwapStrategy;
import std.conv : dtext;

import zyeware;

/// The log level to use for various logs.
enum LogLevel
{
    off, /// No logs should go through. This is only useful for setting a "minimum log level."
    fatal, /// Extremely severe incidents which almost certainly are followed by a crash.
    error, /// Severe incidents that can impact the stability of the application.
    warning, // Incidents that can impact the usability of the application.
    info, // Messages with useful information when troubleshooting, but which have no visible effect on the application itself.
    debug_, // Messages useful for debugging, containing information a normal user wouldn't make much sense of.
    verbose /// Used when logging very minute details.
}

private immutable dstring[] levelNames = [
    "Fatal",
    "Error",
    "Warning",
    "Info",
    "Debug",
    "Verbose"
];

/// Represents a single logger.
final class Logger
{
private:
    LogSink[] mSinks;
    LogLevel mLogLevel;
    dstring mName;

public:
    /// Params:
    ///   baseSink = The log sink to use for writing messages.
    ///   logLevel = The minimum log level that should be logged.
    ///   name = The name of the logger.
    this(LogSink baseSink, LogLevel logLevel, dstring name) pure
    {
        addSink(baseSink);

        mLogLevel = logLevel;
        mName = name;
    }

    /// Add a log sink to this logger.
    void addSink(LogSink sink) @trusted pure
    {
        mSinks ~= sink;
    }

    /// Remove the specified log sink from this logger.
    /// If the given sink doesn't exist, nothing happens.
    /// Params:
    ///   sink = The sink to remove.
    void removeSink(LogSink sink) @trusted
    {
        for (size_t i; i < mSinks.length; ++i)
            if (mSinks[i] == sink)
            {
                mSinks.remove!(SwapStrategy.stable)(i);
                return;
            }
    }

    /// Writes a message to this log.
    /// Params:
    ///   level = The log level the message should be written as.
    ///   message = The message itself.
    void log(LogLevel level, dstring message) nothrow
    {
        if (level > mLogLevel)
            return;
        
        try
        {
            auto data = LogSink.LogData(
                mName,
                level,
                ZyeWare.upTime,
                message
            );

            foreach (LogSink sink; mSinks)
                sink.log(data);
        }
        catch (Exception ex)
        {
            printf("Logger threw an exception. Could not log.\n");
        }
    }

    /// Flushes all log sinks connected to this log.
    void flush() 
    {
        foreach (LogSink sink; mSinks)
            sink.flush();
    }
}

/// Represents a sink to write a message into. This can be either a file, a console,
/// a in-game display, etc.
abstract class LogSink
{
public:
    /// The data that should be logged.
    struct LogData
    {
        dstring loggerName; /// The name of the logger.
        LogLevel level; /// The log level of the message.
        Duration uptime; /// The engine uptime this message was sent.
        dstring message; /// The message itself.
    }

    /// Logs the given data.
    /// Params:
    ///   data = The data to log.
    abstract void log(LogData data);

    /// Flushes the current sink.
    abstract void flush() ;
}

/// Represents a log sink that logs into a real file.
class FileLogSink : LogSink
{
private:
    File mFile;

public:
    /// Params:
    ///   file = The file to log into.
    this(File file)
    {
        mFile = file;
    }

    override void log(LogData data)
    {
        mFile.writefln("%3$-7s %2$-6s %1$7.1f | %4$s", data.uptime.toFloatSeconds, data.loggerName,
            levelNames[data.level - 1], data.message);
    }
}

/// Represents a sink that writes in color to stdout.
class ColorLogSink : LogSink
{
    import consolecolors;

public:
    override void log(LogData data)
    {
        static immutable string[] levelColors = ["magenta", "red", "yellow", "blue", "green", "gray"];

        size_t upSeconds = data.uptime.total!"seconds";

        cwritefln("<%1$s>%2$-7s</%1$s> %3$-6s %4$4d:%5$02d | %6$s", levelColors[data.level - 1], levelNames[data.level - 1],
            data.loggerName, upSeconds / 60, upSeconds % 60, data.message);
    }

    override void flush() 
    {
        stdout.flush();
    }
}