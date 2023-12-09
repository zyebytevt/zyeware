// D import file generated from 'source/zyeware/vfs/dir.d'
module zyeware.vfs.dir;
import std.exception : enforce;
import std.string : format;
import zyeware;
import zyeware.vfs;
abstract class VfsDirectory
{
	protected
	{
		string mPath;
		pure nothrow this(string path);
		public
		{
			abstract VfsDirectory getDirectory(string name);
			abstract VfsFile getFile(string name);
			abstract const nothrow bool hasDirectory(string name);
			abstract const nothrow bool hasFile(string name);
			abstract const immutable(string[]) files();
			abstract const immutable(string[]) directories();
			const pure nothrow string path();
		}
	}
}
package(zyeware.vfs)
{
	pure nothrow bool isWriteMode(VfsFile.Mode mode);
	class VfsCombinedDirectory : VfsDirectory
	{
		protected
		{
			VfsDirectory[] mDirectories;
			package
			{
				pure nothrow this(string path, VfsDirectory[] directories);
				pure nothrow void addDirectory(VfsDirectory directory);
				public
				{
					override VfsDirectory getDirectory(string name);
					override VfsFile getFile(string name);
					override const nothrow bool hasDirectory(string name);
					override const nothrow bool hasFile(string name);
					override const immutable(string[]) files();
					override const immutable(string[]) directories();
				}
			}
		}
	}
}
