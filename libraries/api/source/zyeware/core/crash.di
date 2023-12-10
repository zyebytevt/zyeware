// D import file generated from 'source/zyeware/core/crash.d'
module zyeware.core.crash;
import std.string : format;
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
		private
		{
			enum popupTitle = "Fatal Error";
			enum popupDescription = "Please notify the developer about this issue.\nAdditionally, if this is a bug" ~ " in the engine, please leave a bug report over at https://github.com/zyebytevt/zyeware.";
			enum popupMoreDetails = "For more details, please look into the logs.";
			protected
			{
				bool commandExists(string command);
				void showKDialog(Throwable t);
				void showZenity(in Throwable t);
				void showXMessage(in Throwable t);
				void showGXMessage(in Throwable t);
				public override void show(Throwable t);
			}
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
