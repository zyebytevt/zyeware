// D import file generated from 'source/zyeware/vfs/root.d'
module zyeware.vfs.root;
import core.stdc.stdlib : getenv;
import std.algorithm : findSplit;
import std.exception : enforce;
import std.typecons : Tuple;
import std.range : empty;
import std.string : fromStringz, format;
import std.file : mkdirRecurse, thisExePath, exists;
import std.path : buildNormalizedPath, dirName, isValidPath;
import zyeware.common;
import zyeware.vfs;
package(zyeware.vfs) alias LoadPackageResult = Tuple!(VFSDirectory, "root", immutable(ubyte[]), "hash");
struct VFS
{
	private static
	{
		enum userDirVFSPath = "user://";
		enum userDirPortableName = "ZyeWareData/";
		VFSDirectory[string] sProtocols;
		VFSLoader[] sLoaders;
		bool sPortableMode;
		pragma (inline, true)VFSDirectory getProtocol(string protocol)
		in (protocol)
		{
			VFSDirectory dir = sProtocols.get(protocol, null);
			enforce!VFSException(dir, format!"Unknown VFS protocol '%s'."(protocol));
			return dir;
		}
		pragma (inline, true)auto splitPath(string path)
		in (path)
		{
			auto splitResult = path.findSplit("://");
			enforce!VFSException(!splitResult[0].empty && !splitResult[1].empty && !splitResult[2].empty, "Malformed VFS path.");
			return splitResult;
		}
		LoadPackageResult loadPackage(string path, string name);
		VFSDirectory createUserDir();
		package(zyeware) static
		{
			void initialize();
			nothrow void cleanup();
			public static
			{
				nothrow void addLoader(VFSLoader loader);
				VFSDirectory addPackage(string path);
				VFSFile getFile(string name, VFSFile.Mode mode = VFSFile.Mode.read);
				VFSDirectory getDirectory(string name);
				bool hasFile(string name);
				bool hasDirectory(string name);
				nothrow bool portableMode();
				pure nothrow bool isValidVFSPath(string path);
			}
		}
	}
}
