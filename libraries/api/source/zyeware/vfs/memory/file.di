// D import file generated from 'source/zyeware/vfs/memory/file.d'
module zyeware.vfs.memory.file;
import core.stdc.string : memcpy;
import zyeware;
package(zyeware.vfs) class VfsMemoryFile : VfsFile
{
	protected
	{
		const(ubyte[]) mData;
		size_t mFilePointer;
		bool mIsOpened;
		package(zyeware.vfs)
		{
			pure nothrow this(string path, in ubyte[] data);
			public
			{
				override nothrow size_t read(void* ptr, size_t size, size_t n);
				override nothrow size_t write(const void* ptr, size_t size, size_t n);
				override nothrow void seek(long offset, Seek whence);
				override nothrow long tell();
				override nothrow bool flush();
				override void open(VfsFile.Mode mode);
				override nothrow void close();
				override nothrow FileSize size();
				override const pure nothrow bool isOpened();
				override pure nothrow bool isEof();
			}
		}
	}
}
