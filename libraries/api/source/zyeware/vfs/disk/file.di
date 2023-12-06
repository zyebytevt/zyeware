// D import file generated from 'source/zyeware/vfs/disk/file.d'
module zyeware.vfs.disk.file;
import core.stdc.stdio;
import core.stdc.config : c_long;
import std.exception : enforce;
import std.string : toStringz;
import zyeware;
package(zyeware.vfs) class VFSDiskFile : VFSFile
{
	protected
	{
		string mDiskPath;
		FILE* mStream;
		FileSize mCachedFileSize = FileSize.min;
		package(zyeware.vfs)
		{
			pure nothrow this(string name, string diskPath);
			public
			{
				~this();
				override nothrow size_t read(void* ptr, size_t size, size_t n);
				override nothrow size_t write(const void* ptr, size_t size, size_t n);
				override nothrow void seek(long offset, Seek whence);
				override nothrow long tell();
				override nothrow bool flush();
				override void open(VFSFile.Mode mode);
				override nothrow void close();
				override nothrow FileSize size();
				override const pure nothrow bool isOpened();
				override pure nothrow bool isEof();
			}
		}
	}
}
