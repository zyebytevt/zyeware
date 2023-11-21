// D import file generated from 'source/zyeware/vfs/file.d'
module zyeware.vfs.file;
import core.stdc.stdio;
import core.stdc.config : c_long;
import std.bitmanip : Endian, littleEndianToNative, bigEndianToNative;
import std.traits : isNumeric, isUnsigned;
import std.exception : enforce;
import zyeware.common;
import zyeware.vfs;
abstract class VFSFile : VFSBase
{
	protected
	{
		pure nothrow this(string fullname, string name);
		public
		{
			alias FileSize = long;
			enum Seek
			{
				current,
				end,
				set,
			}
			enum Mode
			{
				read,
				write,
				readWrite,
				writeRead,
				append,
			}
			nothrow T readAll(T)()
			{
				import std.range : ElementEncodingType;
				alias Element = ElementEncodingType!T;
				auto buffer = new Element[cast(size_t)size / Element.sizeof];
				read(cast(void[])buffer);
				return cast(T)buffer;
			}
			abstract nothrow size_t read(void* ptr, size_t size, size_t n);
			final nothrow size_t read(void[] buffer);
			nothrow T readNumber(T)(Endian endianness = Endian.littleEndian) if (isNumeric!T)
			{
				ubyte[T.sizeof] buffer;
				read(buffer.ptr, T.sizeof, 1);
				final switch (endianness)
				{
					case Endian.littleEndian:
					{
						return littleEndianToNative!T(buffer);
					}
					case Endian.bigEndian:
					{
						return bigEndianToNative!T(buffer);
					}
				}
			}
			nothrow S readPascalString(S = string, LengthType = ushort)(Endian endianness = Endian.littleEndian) if (isSomeString!S && isUnsigned!LengthType)
			{
				alias Char = ElementEncodingType!S;
				LengthType length = readNumber!LengthType(endianness);
				Char[] buffer = new Char[length];
				read(buffer.ptr, Char.sizeof, length);
				return buffer.idup;
			}
			abstract nothrow size_t write(const void* ptr, size_t size, size_t n);
			final nothrow size_t write(in void[] buffer);
			nothrow void writeNumber(T)(T number, Endian endianness = Endian.littleEndian) if (isNumeric!T)
			{
				ubyte[T.sizeof] buffer;
				final switch (endianness)
				{
					case Endian.littleEndian:
					{
						buffer = nativeToLittleEndian(number);
						break;
					}
					case Endian.bigEndian:
					{
						buffer = nativeToBigEndian(number);
						break;
					}
				}
				write(buffer.ptr, T.sizeof, 1);
			}
			nothrow void writePascalString(S = string, LengthType = ushort)(in S text, Endian endianness = Endian.littleEndian) if (isSomeString!S && isUnsigned!LengthType)
			{
				alias Char = ElementEncodingType!S;
				writeNumber(cast(LengthType)text.length, endianness);
				write(text.ptr, Char.sizeof, text.length);
			}
			abstract nothrow void seek(long offset, Seek whence);
			abstract nothrow long tell();
			abstract nothrow bool flush();
			abstract nothrow void close();
			abstract nothrow FileSize size();
			abstract const pure nothrow bool isOpen();
			abstract pure nothrow bool isEof();
		}
	}
}
package
{
	class VFSDiskFile : VFSFile
	{
		protected
		{
			FILE* mCFile;
			FileSize mCachedFileSize = FileSize.min;
			package
			{
				pure nothrow this(string fullname, string name, FILE* file);
				public
				{
					~this();
					override nothrow size_t read(void* ptr, size_t size, size_t n);
					override nothrow size_t write(const void* ptr, size_t size, size_t n);
					override nothrow void seek(long offset, Seek whence);
					override nothrow long tell();
					override nothrow bool flush();
					override nothrow void close();
					override nothrow FileSize size();
					override const pure nothrow bool isOpen();
					override pure nothrow bool isEof();
				}
			}
		}
	}
	class VFSZPKFile : VFSFile
	{
		protected
		{
			FILE* mCFile;
			FileSize mFileSize;
			long mFileOffset;
			long mFilePointer;
			bool mIsOpen = true;
			package
			{
				pure nothrow this(string fullname, string name, FILE* file, int offset, int fileSize);
				public
				{
					override nothrow size_t read(void* ptr, size_t size, size_t n);
					override nothrow size_t write(const void* ptr, size_t size, size_t n);
					override nothrow void seek(long offset, Seek whence);
					override pure nothrow long tell();
					override pure nothrow bool flush();
					override pure nothrow void close();
					override pure nothrow FileSize size();
					override const pure nothrow bool isOpen();
					override pure nothrow bool isEof();
				}
			}
		}
	}
}
