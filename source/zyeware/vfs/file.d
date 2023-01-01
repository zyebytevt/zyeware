// This file is part of the ZyeWare Game Engine, and subject to the terms
// and conditions defined in the file 'LICENSE.txt', which is part
// of this source code package.
//
// Copyright 2021 ZyeByte
module zyeware.vfs.file;

import core.stdc.stdio;
import core.stdc.config : c_long;
import std.bitmanip : Endian, littleEndianToNative, bigEndianToNative;
import std.traits : isNumeric, isUnsigned;

import zyeware.common;
import zyeware.vfs;

/// Represents a virtual file in the VFS. Where this file is
/// physically located depends on the implementation.
abstract class VFSFile : VFSBase
{
protected:
    this(string fullname, string name) pure nothrow
    {
        super(fullname, name);
    }

public:
    alias FileSize = long;

    /// How the file position with a `seek` is set.
    enum Seek
    {
        current, /// Relative to the current position.
        end, /// Relative to the end of the file.
        set /// Absolute position.
    }

    /// Describes the access modes for opening a file.
    enum Mode
    {
        read, /// Opens for reading. File must exist.
        write, /// Opens for writing, creates empty file if it doesn't exist, or clears out content of already existing file.
        readWrite, /// Opens for reading and writing. File must exist.
        writeRead, /// Opens for reading and writing, creates empty file if it doesn't exist, or clears out content of already existing file.
        append /// Opens for appending, creates empty file if it doesn't exist.
    }

    /// Reads the entire content of the file.
    /// Returns: The content of the file.
    /// 
    /// Params:
    ///     T = The type to return.
    T readAll(T)() nothrow
    {
        import std.range : ElementEncodingType;

        auto buffer = new ElementEncodingType!T[cast(size_t) size];
        read(cast(void[]) buffer);
        return cast(T) buffer;
    }

    /// Reads data from the file into a block of memory.
    /// Returns: The total number of elements successfully read.
    /// Params:
    ///     ptr = Pointer to a block of memory with a minimum size of size*n.
    ///     size = Size in bytes of each element to be read.
    ///     n = The number of elements to read.
    abstract size_t read(void* ptr, size_t size, size_t n) nothrow;

    /// Reads data from the file into an array.
    /// Returns: The total number of elements successfully read.
    /// Params:
    ///     buffer = The array to read data into.
    final size_t read(void[] buffer) nothrow
        in (buffer)
    {
        return read(buffer.ptr, 1, buffer.length);
    }

    /// Reads a number in binary format from the file.
    /// Returns: The number.
    /// Params:
    ///     T = The type of number to read. All numeric types are valid.
    ///     endianness = The endianness of the number to read.
    T readNumber(T)(Endian endianness = Endian.littleEndian) nothrow 
            if (isNumeric!T)
    {
        ubyte[T.sizeof] buffer;
        read(buffer.ptr, T.sizeof, 1);

        final switch (endianness)
        {
        case Endian.littleEndian:
            return littleEndianToNative!T(buffer);

        case Endian.bigEndian:
            return bigEndianToNative!T(buffer);
        }
    }

    /// Reads text in Pascal-format from the file.
    /// Returns: The text as string.
    /// Params:
    ///     S = The type of string to read. All string types are valid.
    ///     LengthType = The type of the length indicator. All unsigned number types are valid.
    ///     endianness = The endianness of the length indicator.
    S readPascalString(S = string, LengthType = ushort)(Endian endianness = Endian
            .littleEndian) nothrow if (isSomeString!S && isUnsigned!LengthType)
    {
        alias Char = ElementEncodingType!S;

        LengthType length = readNumber!LengthType(endianness);
        Char[] buffer = new Char[length];

        read(buffer.ptr, Char.sizeof, length);
        return buffer.idup;
    }

    /// Writes data from a block of memory to the file.
    /// Returns: The number of elements successfully written.
    /// Params:
    ///     ptr = Pointer of a block of memory with a minimum size of size*n.
    ///     size = Size in bytes of each element to be written.
    ///     n = The number of elements to write.
    abstract size_t write(const void* ptr, size_t size, size_t n) nothrow;
    
    /// Writes data from an array to the file.
    /// Returns: The total number of elements successfully written.
    /// Params:
    ///     buffer = The array of elements to be written.
    final size_t write(in void[] buffer) nothrow
        in (buffer)
    {
        return write(buffer.ptr, 1, buffer.length);
    }

    /// Writes a number in binary format to the file.
    /// Params:
    ///     T = The type of number to write. All numeric types are valid.
    ///     number = The number to write.
    ///     endianness = The endianness of the number to read.
    void writeNumber(T)(T number, Endian endianness = Endian.littleEndian) nothrow
            if (isNumeric!T)
    {
        ubyte[T.sizeof] buffer;

        final switch (endianness)
        {
        case Endian.littleEndian:
            buffer = nativeToLittleEndian(number);
            break;

        case Endian.bigEndian:
            buffer = nativeToBigEndian(number);
            break;
        }

        write(buffer.ptr, T.sizeof, 1);
    }

    /// Writes text in Pascal-format to the file.
    /// Params:
    ///     S = The type of string to write. All string types are valid.
    ///     LengthType = The type of the length indicator. All unsigned number types are valid.
    ///     text = The text to write.
    ///     endianness = The endianness of the length indicator.
    void writePascalString(S = string, LengthType = ushort)(in S text,
            Endian endianness = Endian.littleEndian) nothrow 
            if (isSomeString!S && isUnsigned!LengthType)
    {
        alias Char = ElementEncodingType!S;

        writeNumber(cast(LengthType) text.length, endianness);
        write(text.ptr, Char.sizeof, text.length);
    }

    /// Sets the file position pointer inside the file.
    /// Params:
    ///     offset = The offset to set the file position to.
    ///     whence = How to interpret the given offset.
    abstract void seek(long offset, Seek whence) nothrow;

    /// Returns the current file position.
    abstract long tell() nothrow;
    /// Flushes all writing operations to disk.
    abstract bool flush() nothrow;
    /// Closes the file. Afterwards, no further operations should be taken on this file.
    abstract void close() nothrow;

    /// Returns the total file size in bytes.
    abstract FileSize size() nothrow;

    /// Returns `true` if the file is currently open, `false` otherwise.
    abstract bool isOpen() pure const nothrow;

    /// Returns `true` if the end of file has been reached, `false` otherwise.
    abstract bool isEof() pure nothrow;
}

package:

class VFSDiskFile : VFSFile
{
protected:
    FILE* mCFile;
    FileSize mCachedFileSize = FileSize.min;

package:
    this(string fullname, string name, FILE* file) pure nothrow
        in (file)
    {
        super(fullname, name);
        mCFile = file;
    }

public:
    ~this()
    {
        close();
    }

    override size_t read(void* ptr, size_t size, size_t n) nothrow
        in (ptr)
    {
        if (!isOpen)
            return 0;

        return fread(ptr, size, n, mCFile);
    }

    override size_t write(const void* ptr, size_t size, size_t n) nothrow
        in (ptr)
    {
        if (!isOpen)
            return 0;

        return fwrite(ptr, size, n, mCFile);
    }

    override void seek(long offset, Seek whence) nothrow
    {
        if (!isOpen)
            return;

        static int[Seek] seekToC;
        if (!seekToC)
            seekToC = [
                Seek.current: SEEK_CUR,
                Seek.set: SEEK_SET,
                Seek.end: SEEK_END
            ];

        assert(fseek(mCFile, cast(c_long) offset, seekToC[whence]) == 0, "Failed to seek.");
    }

    override long tell() nothrow
    {
        if (!isOpen)
            return -1;

        return cast(long) ftell(mCFile);
    }

    override bool flush() nothrow
    {
        return isOpen && fflush(mCFile) == 0;
    }

    override void close() nothrow
    {
        if (isOpen)
        {
            fclose(mCFile);
            mCFile = null;
        }
    }

    override FileSize size() nothrow
    {
        if (!isOpen)
            return -1;

        if (mCachedFileSize == FileSize.min)
        {
            immutable c_long pos = ftell(mCFile);
            fseek(mCFile, 0, SEEK_END);
            mCachedFileSize = cast(FileSize) ftell(mCFile);
            fseek(mCFile, pos, SEEK_SET);
        }

        return mCachedFileSize;
    }

    override bool isOpen() pure const nothrow
    {
        return mCFile !is null;
    }

    override bool isEof() pure nothrow
    {
        return feof(mCFile) != 0;
    }
}

class VFSZPKFile : VFSFile
{
protected:
    FILE* mCFile;
    FileSize mFileSize;
    long mFileOffset;
    long mFilePointer;
    bool mIsOpen = true;

package:
    this(string fullname, string name, FILE* file, int offset, int fileSize) pure nothrow
        in (file)
    {
        super(fullname, name);
        mCFile = file;
        mFileOffset = offset;
        mFileSize = fileSize;
    }

public:
    override size_t read(void* ptr, size_t size, size_t n) nothrow
        in (ptr)
    {
        if (!isOpen)
            return 0;

        fseek(mCFile, cast(c_long)(mFileOffset + mFilePointer), SEEK_SET);

        if (mFilePointer + n * size > mFileSize)
            n = cast(size_t)(mFileSize - mFilePointer) / size;

        immutable size_t bRead = fread(ptr, size, n, mCFile);
        mFilePointer += bRead * size;
        return bRead;
    }

    override size_t write(const void* ptr, size_t size, size_t n) nothrow
    {
        assert(false, "Cannot write files into ZPK archives.");
    }

    override void seek(long offset, Seek whence) nothrow
    {
        if (!isOpen)
            return;

        final switch (whence) with (Seek)
        {
        case set:
            mFilePointer = offset;
            break;

        case current:
            mFilePointer += offset;
            break;

        case end:
            mFilePointer = mFileSize - offset;
            break;
        }

        assert(mFilePointer >= 0 && mFilePointer < mFileSize, "Failed to seek.");
    }

    override long tell() pure nothrow
    {
        if (!isOpen)
            return -1;

        return mFilePointer;
    }

    override bool flush() pure nothrow
    {
        // No flushing needed when file is read-only.
        // Return true for error checking routines.
        return true;
    }

    override void close() pure nothrow
    {
        mIsOpen = false;
    }

    override FileSize size() pure nothrow
    {
        if (!isOpen)
            return -1;

        return mFileSize;
    }

    override bool isOpen() pure const nothrow
    {
        return mIsOpen;
    }

    override bool isEof() pure nothrow
    {
        return mFilePointer >= mFileSize;
    }
}
