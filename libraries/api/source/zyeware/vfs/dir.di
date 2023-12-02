// D import file generated from 'source/zyeware/vfs/dir.d'
module zyeware.vfs.dir;
import std.exception : enforce;
import std.string : format;
import zyeware.common;
import zyeware.vfs;
abstract class VFSDirectory
{
	protected
	{
		string mName;
		pure nothrow this(string name);
		public
		{
			abstract VFSDirectory getDirectory(string name);
			abstract VFSFile getFile(string name);
			abstract const nothrow bool hasDirectory(string name);
			abstract const nothrow bool hasFile(string name);
			abstract const immutable(string[]) files();
			abstract const immutable(string[]) directories();
		}
	}
}
package(zyeware.vfs)
{
	pure nothrow bool isWriteMode(VFSFile.Mode mode);
	class VFSCombinedDirectory : VFSDirectory
	{
		protected
		{
			VFSDirectory[] mDirectories;
			package
			{
				pure nothrow this(string name, VFSDirectory[] directories);
				pure nothrow void addDirectory(VFSDirectory directory);
				public
				{
					override VFSDirectory getDirectory(string name);
					override VFSFile getFile(string name);
					override const nothrow bool hasDirectory(string name);
					override const nothrow bool hasFile(string name);
					override const immutable(string[]) files();
					override const immutable(string[]) directories();
				}
			}
		}
	}
}
