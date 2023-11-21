// D import file generated from 'source/zyeware/vfs/loader.d'
module zyeware.vfs.loader;
import zyeware.common;
import zyeware.vfs;
interface VFSLoader
{
	public
	{
		const LoadPackageResult load(string diskPath, string name);
		const bool eligable(string diskPath);
	}
}
class VFSDirectoryLoader : VFSLoader
{
	public
	{
		const LoadPackageResult load(string diskPath, string name);
		const bool eligable(string diskPath);
	}
}
class VFSZPKLoader : VFSLoader
{
	import core.stdc.stdio;
	protected
	{
		const nothrow string readPString(LengthType = ushort)(FILE* file)
		in (file)
		{
			import std.bitmanip : read, Endian;
			LengthType length = readPrimitive!LengthType(file);
			char[] str = new char[length];
			fread(str.ptr, (char).sizeof, length, file);
			return str.idup;
		}
		const nothrow T readPrimitive(T)(FILE* file)
		in (file)
		{
			import std.bitmanip : read, Endian;
			ubyte[] buffer = new ubyte[T.sizeof];
			fread(buffer.ptr, (ubyte).sizeof, T.sizeof, file);
			return read!(T, Endian.littleEndian)(buffer);
		}
		package
		{
			struct FileNode
			{
				struct FileInfo
				{
					string fullPath;
					int offset;
					int size;
				}
				FileInfo* fileInfo;
				FileNode*[string] children;
			}
			public
			{
				const LoadPackageResult load(string diskPath, string name);
				const bool eligable(string diskPath);
			}
		}
	}
}
