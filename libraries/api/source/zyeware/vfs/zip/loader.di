// D import file generated from 'source/zyeware/vfs/zip/loader.d'
module zyeware.vfs.zip.loader;
import std.string : split, startsWith;
import std.file : read, isFile;
import std.exception : enforce;
import std.zip;
import zyeware;
import zyeware.vfs.zip;
package(zyeware.vfs) class VFSZipLoader : VFSLoader
{
	package(zyeware.vfs)
	{
		struct FileNode
		{
			ArchiveMember member;
			FileNode*[string] children;
			FileNode* parent;
		}
		public
		{
			const VFSDirectory load(string diskPath, string name);
			const bool eligable(string diskPath);
		}
	}
}