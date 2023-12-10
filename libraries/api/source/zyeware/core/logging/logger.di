// D import file generated from 'source/zyeware/core/logging/logger.d'
module zyeware.core.logging.logger;
import core.stdc.stdio : printf;
import std.stdio : File, stdout;
import std.datetime : Duration;
import std.string : fromStringz;
import std.traits : isSomeString;
import std.algorithm : remove, SwapStrategy;
import std.conv : dtext;
import zyeware;
enum LogLevel
{
	off,
	fatal,
	error,
	warning,
	info,
	debug_,
	verbose,
}
private extern immutable dstring[] levelNames;
final class Logger
{
	private
	{
		LogSink mSink;
		LogLevel mLogLevel;
		dstring mName;
		public
		{
			pure nothrow this(LogSink sink, LogLevel logLevel, dstring name);
			nothrow void log(LogLevel level, dstring message);
			void flush();
		}
	}
}
abstract class LogSink
{
	public
	{
		struct LogData
		{
			dstring loggerName;
			LogLevel level;
			Duration uptime;
			dstring message;
		}
		abstract void log(in LogData data);
		abstract void flush();
	}
}
final class CombinedLogSink : LogSink
{
	private
	{
		LogSink[] mSinks;
		public
		{
			this(LogSink[] sinks);
			pure @trusted void addSink(LogSink sink);
			@trusted void removeSink(LogSink sink);
			override void log(in LogData data);
			override void flush();
		}
	}
}
class FileLogSink : LogSink
{
	protected
	{
		File mFile;
		public
		{
			this(File file);
			override void log(in LogData data);
			override void flush();
		}
	}
}
class ColorLogSink : LogSink
{
	public
	{
		override void log(in LogData data);
		override void flush();
	}
}
