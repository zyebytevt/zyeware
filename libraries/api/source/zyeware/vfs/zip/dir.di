// D import file generated from 'source/zyeware/vfs/zip/dir.d'
module zyeware.vfs.zip.dir;
import std.zip;
import std.string : split, format;
import std.exception : enforce;
import std.path : isRooted;
import zyeware;
import zyeware.vfs.zip;
package(zyeware.vfs) class VfsZipDirectory : VfsDirectory
{
	protected
	{
		alias FileNode = VfsZipLoader.FileNode;
		enum NodeType
		{
			invalid,
			directory,
			file,
		}
		FileNode* mRoot;
		const pure nothrow NodeType getNodeType(string path);
		const pure FileNode* traversePath(string path);
		package(zyeware.vfs)
		{
			const ZipArchive mArchive;
			pure nothrow this(string name, in ZipArchive archive, FileNode* root);
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
