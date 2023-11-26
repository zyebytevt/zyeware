// D import file generated from 'source/zyeware/vfs/dir.d'
module zyeware.vfs.dir;
import core.stdc.stdio : FILE;
import std.path : dirSeparator, baseName, buildPath, isRooted;
import std.file : exists, isDir, isFile, dirEntries, SpanMode;
import std.exception : enforce, assumeWontThrow;
import std.string : split, format;
import zyeware.common;
import zyeware.vfs;
abstract class VFSDirectory : VFSBase
{
	package
	{
		pure nothrow this(string fullname, string name);
		public
		{
			abstract VFSDirectory getDirectory(string name);
			abstract VFSFile getFile(string name, VFSFile.Mode mode = VFSFile.Mode.read);
			abstract const nothrow bool hasDirectory(string name);
			abstract const nothrow bool hasFile(string name);
			abstract const immutable(string[]) files();
			abstract const immutable(string[]) directories();
		}
	}
}
package
{
	class VFSCombinedDirectory : VFSDirectory
	{
		protected
		{
			VFSDirectory[] mDirectories;
			package
			{
				pure nothrow this(string fullname, string name, VFSDirectory[] directories);
				pure nothrow void addDirectory(VFSDirectory directory);
				public
				{
					override VFSDirectory getDirectory(string name);
					override VFSFile getFile(string name, VFSFile.Mode mode = VFSFile.Mode.read);
					override const nothrow bool hasDirectory(string name);
					override const nothrow bool hasFile(string name);
					override const immutable(string[]) files();
					override const immutable(string[]) directories();
				}
			}
		}
	}
	class VFSDiskDirectory : VFSDirectory
	{
		protected
		{
			immutable string mDiskPath;
			package
			{
				pure nothrow this(string fullname, string name, string diskPath);
				public
				{
					override const VFSDirectory getDirectory(string name);
					override const VFSFile getFile(string name, VFSFile.Mode mode = VFSFile.Mode.read);
					override const nothrow bool hasDirectory(string name);
					override const nothrow bool hasFile(string name);
					override const immutable(string[]) files();
					override const immutable(string[]) directories();
				}
			}
		}
	}
	class VFSZPKDirectory : VFSDirectory
	{
		protected
		{
			alias Node = VFSZPKLoader.FileNode;
			FILE* mCFile;
			Node* mRoot;
			bool mFilePointerOwner;
			package
			{
				pure nothrow this(string fullname, string name, FILE* file, Node* root, Flag!"filePointerOwner" filePointerOwner);
				public
				{
					~this();
					override pure VFSDirectory getDirectory(string name);
					override pure VFSFile getFile(string name, VFSFile.Mode mode = VFSFile.Mode.read);
					override const pure nothrow bool hasDirectory(string name);
					override const pure nothrow bool hasFile(string name);
					override const pure immutable(string[]) files();
					override const pure immutable(string[]) directories();
				}
			}
		}
	}
	private pure nothrow bool isWriteMode(VFSFile.Mode mode);
}
