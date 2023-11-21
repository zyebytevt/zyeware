// D import file generated from 'source/zyeware/core/debugging/info.d'
module zyeware.core.debugging.info;
import core.memory;
import zyeware.common;
version (ZW_Profiling)
{
	package(zyeware) struct DebugInfoManager
	{
		@disable this();
		@disable this(this);
		private static
		{
			bool sDebugKeyPressed;
			nothrow void logMemoryStatistics();
			package(zyeware.core) static nothrow void receive(InputEventKey key);
		}
	}
}
