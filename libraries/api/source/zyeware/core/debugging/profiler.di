// D import file generated from 'source/zyeware/core/debugging/profiler.d'
module zyeware.core.debugging.profiler;
import std.datetime.stopwatch : StopWatch;
import std.datetime : Duration;
import zyeware;
version (ZW_Profiling)
{
	struct Profiler
	{
		private static
		{
			Data[2] sData;
			size_t sReadDataPointer;
			size_t sWriteDataPointer = 1;
			package(zyeware) static
			{
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
				nothrow void initialize();
				nothrow void clearAndSwap();
				public static
				{
					struct Result
					{
						immutable string name;
						immutable Duration duration;
					}
					struct Timer
					{
						private
						{
							StopWatch mWatch;
							immutable string mName;
							public
							{
								nothrow this(string name);
								nothrow void stop();
							}
						}
					}
					nothrow const(Data)* currentReadData();
					nothrow Data* currentWriteData();
					nothrow ushort fps();
				}
			}
		}
	}
	template ProfileFunction(string customName = null)
	{
		static if (!customName)
		{
			enum timerName = "__FUNCTION__";
		}
		else
		{
			enum timerName = customName;
		}
		enum ProfileFunction = "version (ZW_Profiling) {\n        auto ptimer__ = Profiler.Timer(" ~ timerName ~ ");\n        scope (success) ptimer__.stop();\n    }";
	}
	template ProfileScope(string customName = null)
	{
		static if (!customName)
		{
			enum timerName = "__LINE__ ~ \" @ \" ~ __FUNCTION__";
		}
		else
		{
			enum timerName = "\"" ~ customName ~ "\" ~ \" @ \" ~ __FUNCTION__";
		}
		enum ProfileScope = "version (ZW_Profiling) {\n        auto ptimer__ = Profiler.Timer(" ~ timerName ~ ");\n        scope (success) ptimer__.stop();\n    }";
	}
}
