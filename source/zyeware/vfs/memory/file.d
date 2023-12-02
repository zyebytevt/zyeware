module zyeware.vfs.memory.file;

import core.stdc.string : memcpy;

import zyeware.common;

package(zyeware.vfs):

class VFSMemoryFile : VFSFile
{
protected:
    const(ubyte[]) mData;
    size_t mFilePointer;
    bool mIsOpened;

package(zyeware.vfs):
    this(string name, in ubyte[] data) pure nothrow
    {
        super(name);
        mData = data;
    }

public:
    override size_t read(void* ptr, size_t size, size_t n) nothrow
        in (ptr)
    {
        if (!isOpened)
            return 0;

        size_t bytesToRead = size * n;
        if (bytesToRead > mData.length - mFilePointer)
            bytesToRead = mData.length - mFilePointer;

        memcpy(ptr, mData.ptr + mFilePointer, bytesToRead);
        return bytesToRead;
    }

    override size_t write(const void* ptr, size_t size, size_t n) nothrow
        in (ptr)
    {
        return 0;
    }

    override void seek(long offset, Seek whence) nothrow
    {
        if (!isOpened)
            return;

        final switch (whence) with (Seek)
        {
        case current:
            mFilePointer += offset;
            if (mFilePointer > mData.length)
                mFilePointer = mData.length;
            break;
        
        case set:
            mFilePointer = offset;
            break;
        
        case end:
            mFilePointer = mData.length + offset;
            break;
        }
    }

    override long tell() nothrow
    {
        if (!isOpened)
            return -1;

        return cast(long) mFilePointer;
    }

    override bool flush() nothrow
    {
        return false;
    }

    override void open(VFSFile.Mode mode)
    {
        if (isOpened)
            return;

        mFilePointer = 0;
        mIsOpened = true;
    }

    override void close() nothrow
    {
        if (!isOpened)
            return;
        
        mIsOpened = false;
    }

    override FileSize size() nothrow
    {
        if (!isOpened)
            return -1;

        return cast(FileSize) mData.length;
    }

    override bool isOpened() pure const nothrow
    {
        return mIsOpened;
    }

    override bool isEof() pure nothrow
    {
        return mFilePointer >= mData.length;
    }
}