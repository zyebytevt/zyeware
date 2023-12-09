// D import file generated from 'source/zyeware/vfs/disk/dir.d'
module zyeware.vfs.disk.dir;
static import std.path;
import std.exception : enforce, assumeWontThrow;
import std.string : format;
import std.file : exists, isDir, isFile, dirEntries, SpanMode;
import zyeware;
import zyeware.vfs.dir : isWriteMode;
import zyeware.vfs.disk;
package(zyeware.vfs) class VfsDiskDirectory : VfsDirectory
{
	protected
	{
		immutable string mDiskPath;
		package(zyeware.vfs)
		{
			pure nothrow this(string path, string diskPath);
			public
			{
				override const VfsDirectory getDirectory(string name);
				override const VfsFile getFile(string name);
				override const nothrow bool hasDirectory(string name);
				override const nothrow bool hasFile(string name);
				override const immutable(string[]) files();
				override const immutable(string[]) directories();
			}
		}
	}
}
