// D import file generated from 'source/zyeware/vfs/file.d'
module zyeware.vfs.file;
import core.stdc.stdio;
import std.bitmanip : Endian, littleEndianToNative, bigEndianToNative;
import std.traits : isNumeric, isUnsigned;
import std.exception : enforce;
import zyeware.common;
abstract class VFSFile
{
	protected
	{
		string mName;
		pure nothrow this(string name);
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
			abstract nothrow size_t read(void* ptr, size_t size, size_t n);
			abstract nothrow size_t write(const void* ptr, size_t size, size_t n);
			abstract nothrow void seek(long offset, Seek whence);
			abstract nothrow long tell();
			abstract nothrow bool flush();
			abstract void open(VFSFile.Mode mode);
			abstract nothrow void close();
			abstract nothrow FileSize size();
			abstract const pure nothrow bool isOpened();
			abstract pure nothrow bool isEof();
			nothrow T readAll(T)()
			{
				import std.range : ElementEncodingType;
				alias Element = ElementEncodingType!T;
				auto buffer = new Element[cast(size_t)size / Element.sizeof];
				read(cast(void[])buffer);
				return cast(T)buffer;
			}
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
		}
	}
}
