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
import zyeware.vfs.disk : VFSDiskLoader, VFSDiskDirectory;
import zyeware.vfs.dir : VFSCombinedDirectory;
struct VFS
{
	private static
	{
		enum userDirVFSPath = "user://";
		enum userDirPortableName = "ZyeWareData/";
		VFSDirectory[string] sSchemes;
		VFSLoader[] sLoaders;
		bool sPortableMode;
		pragma (inline, true)VFSDirectory getScheme(string scheme)
		in (scheme)
		{
			VFSDirectory dir = sSchemes.get(scheme, null);
			enforce!VFSException(dir, format!"Unknown VFS scheme '%s'."(scheme));
			return dir;
		}
		pragma (inline, true)auto splitPath(string path)
		in (path)
		{
			auto splitResult = path.findSplit(":");
			enforce!VFSException(!splitResult[0].empty && !splitResult[1].empty && !splitResult[2].empty, "Malformed VFS path.");
			return splitResult;
		}
		VFSDirectory loadPackage(string path, string name);
		VFSDirectory createUserDir();
		package(zyeware) static
		{
			void initialize();
			nothrow void cleanup();
			public static
			{
				nothrow void addLoader(VFSLoader loader);
				VFSDirectory addPackage(string path);
				VFSFile open(string name, VFSFile.Mode mode = VFSFile.Mode.read);
				VFSFile getFile(string name);
				VFSDirectory getDirectory(string name);
				bool hasFile(string name);
				bool hasDirectory(string name);
				nothrow bool portableMode();
			}
		}
	}
}
