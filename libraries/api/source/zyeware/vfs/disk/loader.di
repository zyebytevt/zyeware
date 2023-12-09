// D import file generated from 'source/zyeware/vfs/disk/loader.d'
module zyeware.vfs.disk.loader;
import std.path : baseName;
import std.file : exists, isDir;
import zyeware.vfs;
import zyeware.vfs.disk;
package(zyeware.vfs) class VfsDiskLoader : VfsLoader
{
	public
	{
		const VfsDirectory load(string diskPath, string scheme);
		const bool eligable(string diskPath);
	}
}
