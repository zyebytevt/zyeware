// D import file generated from 'source/zyeware/vfs/root.d'
module zyeware.vfs.root;
static import std.path;
import core.stdc.stdlib : getenv;
import std.algorithm : findSplit;
import std.exception : enforce;
import std.typecons : Tuple;
import std.range : empty;
import std.string : fromStringz, format;
import std.file : mkdirRecurse, thisExePath, exists;
import zyeware;
import zyeware.vfs.disk : VfsDiskLoader, VfsDiskDirectory;
import zyeware.vfs.zip : VfsZipLoader, VfsZipDirectory;
import zyeware.vfs.dir : VfsCombinedDirectory;
private ubyte[16] md5FromHex(string hexString);
struct Vfs
{
	private static
	{
		enum userDirVfsPath = "user://";
		enum userDirPortableName = "ZyeWareData/";
		VfsDirectory[string] sSchemes;
		VfsLoader[] sLoaders;
		bool sPortableMode;
		pragma (inline, true)VfsDirectory getScheme(string scheme)
		in (scheme)
		{
			VfsDirectory dir = sSchemes.get(scheme, null);
			enforce!VfsException(dir, format!"Unknown Vfs scheme '%s'."(scheme));
			return dir;
		}
		pragma (inline, true)auto splitPath(string path)
		in (path)
		{
			auto splitResult = path.findSplit(":");
			enforce!VfsException(!splitResult[0].empty && !splitResult[1].empty && !splitResult[2].empty, "Malformed Vfs path.");
			return splitResult;
		}
		VfsDirectory loadPackage(string path, string scheme);
		VfsDirectory createUserDir();
		package(zyeware) static
		{
			void initialize();
			nothrow void cleanup();
			public static
			{
				nothrow void registerLoader(VfsLoader loader);
				VfsDirectory addPackage(string path);
				VfsFile open(string name, VfsFile.Mode mode = VfsFile.Mode.read);
				VfsFile openFromMemory(string name, in ubyte[] data);
				VfsFile getFile(string name);
				VfsDirectory getDirectory(string name);
				bool hasFile(string name);
				bool hasDirectory(string name);
				nothrow bool portableMode();
			}
		}
	}
}
