// D import file generated from 'source/zyeware/core/crash.d'
module zyeware.core.crash;
import zyeware;
interface CrashHandler
{
	void show(Throwable t);
}
class DefaultCrashHandler : CrashHandler
{
	public void show(Throwable t);
}
version (linux)
{
	class LinuxDefaultCrashHandler : DefaultCrashHandler
	{
		import std.process : execute, executeShell;
		protected
		{
			bool commandExists(string command);
			void showKDialog(string message, string details, string title);
			void showZenity(string message, string title);
			void showXMessage(string message);
			void showGXMessage(string message, string title);
			public override void show(Throwable t);
		}
	}
}
version (Windows)
{
	class WindowsDefaultCrashHandler : DefaultCrashHandler
	{
		import core.sys.windows.windows;
		import std.utf : toUTFz;
		protected
		{
			void showMessageBox(string message, string title);
			public override void show(Throwable t);
		}
	}
}
