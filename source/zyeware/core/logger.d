// This file is part of the ZyeWare Game Engine, and subject to the terms
// and conditions defined in the file 'LICENSE.txt', which is part
// of this source code package.
//
// Copyright 2021 ZyeByte
module zyeware.core.logger;

import core.stdc.stdio : printf;
import std.stdio : File, stdout;
import std.string : format;
import std.datetime : Duration;
import std.algorithm : remove, SwapStrategy;
import std.exception : assumeWontThrow, collectException;

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

private immutable string[] levelNames = [
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
    __gshared static Logger[string] sLoggers;

    LogSink mSink;
    LogLevel mLogLevel;
    string mName;

public:
    /// Params:
    ///   sink = The log sink to use for writing messages.
    ///   logLevel = The minimum log level that should be logged.
    ///   name = The name of the logger.
    this(LogSink sink, LogLevel logLevel, string name) pure nothrow
    {
        mSink = sink;
        mLogLevel = logLevel;
        mName = name;
    }

    /// Writes a message to this log.
    /// Params:
    ///   level = The log level the message should be written as.
    ///   message = The message itself.
    void log(LogLevel level, string message) nothrow
    {
        if (level > mLogLevel)
            return;

        mSink.log(LogSink.LogData(
            mName,
            level,
            ZyeWare.upTime,
            message
        ));
    }

    /// Flushes the log sink connected to this log.
    void flush() => mSink.flush();

    pragma(inline, true)
    {
        void fatal(string message) nothrow => log(LogLevel.fatal, message);
        void error(string message) nothrow => log(LogLevel.error, message);
        void warning(string message) nothrow => log(LogLevel.warning, message);
        void info(string message) nothrow => log(LogLevel.info, message);
        void debug_(string message) nothrow => log(LogLevel.debug_, message);
        void verbose(string message) nothrow => log(LogLevel.verbose, message);

        void fatal(Args...)(string message, Args args) nothrow => log(LogLevel.fatal, message.format(args).assumeWontThrow);
        void error(Args...)(string message, Args args) nothrow => log(LogLevel.error, message.format(args).assumeWontThrow);
        void warning(Args...)(string message, Args args) nothrow => log(LogLevel.warning, message.format(args).assumeWontThrow);
        void info(Args...)(string message, Args args) nothrow => log(LogLevel.info, message.format(args).assumeWontThrow);
        void debug_(Args...)(string message, Args args) nothrow => log(LogLevel.debug_, message.format(args).assumeWontThrow);
        void verbose(Args...)(string message, Args args) nothrow => log(LogLevel.verbose, message.format(args).assumeWontThrow);
    }

    static void create(string id, Logger logger)
    {
        enforce!CoreException(id !in sLoggers, format!"Logger with id '%s' already exists!"(id));
        sLoggers[id] = logger;
    }

    pragma(inline, true)
    static Logger get(string id) nothrow => sLoggers[id];
}

/// Represents a sink to write a message into. This can be either a file, a console,
/// a in-game display, etc.
abstract class LogSink
{
public:
    /// The data that should be logged.
    struct LogData
    {
        string loggerName; /// The name of the logger.
        LogLevel level; /// The log level of the message.
        Duration uptime; /// The engine uptime this message was sent.
        string message; /// The message itself.
    }

    /// Logs the given data.
    /// Params:
    ///   data = The data to log.
    abstract void log(in LogData data) nothrow;

    /// Flushes the current sink.
    abstract void flush();
}

final class CombinedLogSink : LogSink
{
private:
    LogSink[] mSinks;

public:
    /// Params:
    ///   sinks = The sinks to combine.
    this(LogSink[] sinks)
    {
        mSinks = sinks;
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

    override void log(in LogData data) nothrow
    {
        foreach (sink; mSinks)
            sink.log(data);
    }

    override void flush()
    {
        foreach (sink; mSinks)
            sink.flush();
    }
}

/// Represents a log sink that logs into a real file.
class FileLogSink : LogSink
{
protected:
    File mFile;

public:
    /// Params:
    ///   file = The file to log into.
    this(File file)
    {
        mFile = file;
    }

    override void log(in LogData data) nothrow
    {
        mFile.writefln("%3$-7s %2$-6s %1$7.1f | %4$s", data.uptime.toFloatSeconds, data.loggerName,
            levelNames[data.level - 1], data.message).collectException;
    }

    override void flush()
    {
        mFile.flush();
    }
}

/// Represents a sink that writes in modulate to stdout.
class ColorLogSink : LogSink
{
    import consolecolors;

public:
    override void log(in LogData data) nothrow
    {
        static immutable string[] levelColors = ["magenta", "red", "yellow", "blue", "green", "gray"];

        size_t upSeconds = data.uptime.total!"seconds";

        cwritefln("<%1$s>%2$-7s</%1$s> %3$-6s %4$4d:%5$02d | %6$s", levelColors[data.level - 1], levelNames[data.level - 1],
            data.loggerName, upSeconds / 60, upSeconds % 60, data.message).collectException;
    }

    override void flush() 
    {
        stdout.flush();
    }
}