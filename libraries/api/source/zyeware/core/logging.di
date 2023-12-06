// D import file generated from 'source/zyeware/core/logging.d'
module zyeware.core.logging;
import core.stdc.stdio : printf;
import std.stdio : File, stdout;
import std.datetime : Duration;
import std.string : fromStringz;
import std.format : format, sformat;
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
		LogSink[] mSinks;
		LogLevel mLogLevel;
		dstring mName;
		__gshared LogSink sDefaultLogSink;
		__gshared Logger sCoreLogger;
		__gshared Logger sClientLogger;
		__gshared Logger sPalLogger;
		package(zyeware)
		{
			static void initialize(LogLevel coreLevel, LogLevel clientLevel, LogLevel palLevel);
			static nothrow Logger core();
			static nothrow Logger pal();
			public
			{
				pure this(LogSink baseSink, LogLevel logLevel, dstring name);
				pure @trusted void addSink(LogSink sink);
				@trusted void removeSink(LogSink sink);
				nothrow void log(S, T...)(LogLevel level, S message, T args) if (isSomeString!S)
				{
					static char[2048] formatted;
					if (level > mLogLevel)
						return ;
					try
					{
						immutable dstring text = sformat(formatted, message, args).dtext;
						auto data = LogSink.LogData(mName, level, ZyeWare.upTime, text);
						foreach (LogSink sink; mSinks)
						{
							sink.log(data);
						}
						text.dispose();
					}
					catch(Exception ex)
					{
						printf("Logger threw an exception. Could not log.\n");
					}
				}
				void flush();
				static nothrow Logger client();
				static nothrow LogSink defaultLogSink();
			}
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
		abstract void log(LogData data);
		abstract void flush();
	}
}
class FileLogSink : LogSink
{
	private
	{
		File mFile;
		public
		{
			this(File file);
			override void log(LogData data);
		}
	}
}
class ColorLogSink : LogSink
{
	public
	{
		override void log(LogData data);
		override void flush();
	}
}
