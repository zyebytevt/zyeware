// D import file generated from 'source/zyeware/vfs/zip/file.d'
module zyeware.vfs.zip.file;
import core.stdc.string : memcpy;
import std.exception : enforce;
import std.zip;
import std.typecons : Rebindable;
import zyeware;
package(zyeware.vfs) class VFSZipFile : VFSFile
{
	protected
	{
		ZipArchive mArchive;
		ArchiveMember mMember;
		Rebindable!(const(ubyte[])) mData;
		size_t mFilePointer;
		package(zyeware.vfs)
		{
			this(string name, ZipArchive archive, ArchiveMember member);
			public
			{
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
