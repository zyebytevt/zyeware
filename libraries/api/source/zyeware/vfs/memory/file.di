// This file was generated by ZyeWare APIgen. Do not edit!
module zyeware.vfs.memory.file;


import core.stdc.string : memcpy;
import zyeware;

package(zyeware.vfs):

class VfsMemoryFile : VfsFile {

protected:

const(ubyte[]) mData;

size_t mFilePointer;

bool mIsOpened;

package(zyeware.vfs):

this(string path, in ubyte[] data) pure nothrow {
super(path);
mData = data;
}

public:

override size_t read(void* ptr, size_t size, size_t n) nothrow;

override size_t write(const void* ptr, size_t size, size_t n) nothrow;

override void seek(long offset, Seek whence) nothrow;

override long tell() nothrow;

override bool flush() nothrow;

override void open(VfsFile.Mode mode);

override void close() nothrow;

override FileSize size() nothrow;

override bool isOpened() pure const nothrow;

override bool isEof() pure nothrow;
}