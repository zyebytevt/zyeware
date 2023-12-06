module zyeware.vfs.zip.file;

import core.stdc.string : memcpy;

import std.exception : enforce;
import std.zip;
import std.typecons : Rebindable;

import zyeware;

package(zyeware.vfs):

class VFSZipFile : VFSFile
{
protected:
    ZipArchive mArchive;
    ArchiveMember mMember;

    Rebindable!(const(ubyte[])) mData;
    size_t mFilePointer;

package(zyeware.vfs):
    this(string name, ZipArchive archive, ArchiveMember member)
    {
        super(name);
        mArchive = archive;
        mMember = member;
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

        enforce!VFSException(mode == VFSFile.Mode.read, "Compressed archives only support read mode");
        
        mData = mMember.expandedData ? mMember.expandedData : mArchive.expand(mMember);
        mFilePointer = 0;
    }

    override void close() nothrow
    {
        if (!isOpened)
            return;
        
        mData = null;
    }

    override FileSize size() nothrow
    {
        if (!isOpened)
            return -1;

        return cast(FileSize) mData.length;
    }

    override bool isOpened() pure const nothrow
    {
        return mData !is null;
    }

    override bool isEof() pure nothrow
    {
        return !isOpened && mFilePointer >= mData.length;
    }
}