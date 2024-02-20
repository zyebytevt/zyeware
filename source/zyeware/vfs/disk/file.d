module zyeware.vfs.disk.file;

import core.stdc.stdio;
import core.stdc.config : c_long;

import std.exception : enforce;
import std.string : toStringz;

import zyeware;

package(zyeware.vfs):

class DiskFile : File
{
protected:
    string mDiskPath;
    FILE* mStream;
    FileSize mCachedFileSize = FileSize.min;

package(zyeware.vfs):
    this(string path, string diskPath) pure nothrow
    {
        super(path);
        mDiskPath = diskPath;
    }

public:
    ~this()
    {
        if (mStream)
            fclose(mStream);
    }

    override size_t read(void* ptr, size_t size, size_t n) nothrow
        in (ptr)
    {
        if (!isOpened)
            return 0;

        return fread(ptr, size, n, mStream);
    }

    override size_t write(const void* ptr, size_t size, size_t n) nothrow
        in (ptr)
    {
        if (!isOpened)
            return 0;

        return fwrite(ptr, size, n, mStream);
    }

    override void seek(long offset, Seek whence) nothrow
    {
        if (!isOpened)
            return;

        int fseekWhence;
        final switch (whence) with (Seek)
        {
        case current:
            fseekWhence = SEEK_CUR;
            break;
        case set:
            fseekWhence = SEEK_SET;
            break;
        case end:
            fseekWhence = SEEK_END;
            break;
        }

        fseek(mStream, cast(c_long) offset, fseekWhence);
    }

    override long tell() nothrow
    {
        if (!isOpened)
            return -1;

        return cast(long) ftell(mStream);
    }

    override bool flush() nothrow
    {
        return isOpened && fflush(mStream) == 0;
    }

    override void open(File.Mode mode)
    {
        if (isOpened)
            return;

        const(char)* modeStr;
        final switch (mode) with (File.Mode)
        {
        case read:
            modeStr = "rb";
            break;
        case write:
            modeStr = "wb";
            break;
        case append:
            modeStr = "ab";
            break;
        case readWrite:
            modeStr = "r+b";
            break;
        case writeRead:
            modeStr = "w+b";
            break;
        }

        mStream = fopen(mDiskPath.toStringz, modeStr);
        enforce!VfsException(mStream, "Failed to open file.");
    }

    override void close() nothrow
    {
        if (!isOpened)
            return;
        
        fclose(mStream);
        mStream = null;
    }

    override FileSize size() nothrow
    {
        if (!isOpened)
            return -1;

        if (mCachedFileSize == FileSize.min)
        {
            immutable c_long pos = ftell(mStream);

            fseek(mStream, 0, SEEK_END);
            mCachedFileSize = cast(FileSize) ftell(mStream);
            fseek(mStream, pos, SEEK_SET);
        }

        return mCachedFileSize;
    }

    override bool isOpened() pure const nothrow
    {
        return mStream !is null;
    }

    override bool isEof() pure nothrow
    {
        return feof(mStream) != 0;
    }
}