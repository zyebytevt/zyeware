// D import file generated from 'source/zyeware/vfs/disk/dir.d'
module zyeware.vfs.disk.dir;
import std.exception : enforce, assumeWontThrow;
import std.string : format;
import std.path : isRooted, buildPath, baseName;
import std.file : exists, isDir, isFile, dirEntries, SpanMode;
import zyeware;
import zyeware.vfs.dir : isWriteMode;
import zyeware.vfs.disk;
package(zyeware.vfs) class VFSDiskDirectory : VFSDirectory
{
	protected
	{
		immutable string mDiskPath;
		package(zyeware.vfs)
		{
			pure nothrow this(string name, string diskPath);
			public
			{
				override const VFSDirectory getDirectory(string name);
				override const VFSFile getFile(string name);
				override const nothrow bool hasDirectory(string name);
				override const nothrow bool hasFile(string name);
				override const immutable(string[]) files();
				override const immutable(string[]) directories();
			}
		}
	}
}
