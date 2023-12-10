// D import file generated from 'source/zyeware/core/logging/client.d'
module zyeware.core.logging.client;
import std.traits : isSomeString;
import std.exception : assumeWontThrow;
import std.string : format;
import std.conv : dtext;
import zyeware.core.logging.logger;
private
{
	extern __gshared Logger pLogger;
	package(zyeware)
	{
		void initClientLogger(LogLevel level);
		public pragma (inline, true)nothrow
		{
			void fatal(T, S...)(T message, S args) if (isSomeString!T)
			{
				pLogger.log(LogLevel.fatal, message.format(args).dtext.assumeWontThrow);
			}
			void error(T, S...)(T message, S args) if (isSomeString!T)
			{
				pLogger.log(LogLevel.error, message.format(args).dtext.assumeWontThrow);
			}
			void warning(T, S...)(T message, S args) if (isSomeString!T)
			{
				pLogger.log(LogLevel.warning, message.format(args).dtext.assumeWontThrow);
			}
			void info(T, S...)(T message, S args) if (isSomeString!T)
			{
				pLogger.log(LogLevel.info, message.format(args).dtext.assumeWontThrow);
			}
			void debug_(T, S...)(T message, S args) if (isSomeString!T)
			{
				pLogger.log(LogLevel.debug_, message.format(args).dtext.assumeWontThrow);
			}
			void verbose(T, S...)(T message, S args) if (isSomeString!T)
			{
				pLogger.log(LogLevel.verbose, message.format(args).dtext.assumeWontThrow);
			}
		}
	}
}
