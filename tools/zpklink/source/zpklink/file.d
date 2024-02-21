module zpklink.file;

import std.bitmanip;
import std.stdio;

void writePString(LengthType = uint)(File file, string text) {
	file.writePrimitive(cast(LengthType) text.length);
	fwrite(text.ptr, char.sizeof, text.length, file.getFP);
}

string readPString(LengthType = uint)(File file) {
	LengthType length = file.readPrimitive!LengthType;
	char[] str = new char[length];

	fread(str.ptr, char.sizeof, length, file.getFP);
	return str.idup;
}

void writePrimitive(T)(File file, T value) {
	ubyte[] data = new ubyte[T.sizeof];
	write!(T, Endian.littleEndian)(data, value, 0);

	fwrite(data.ptr, ubyte.sizeof, T.sizeof, file.getFP);
}

T readPrimitive(T)(File file) {
	ubyte[] buffer = new ubyte[T.sizeof];
	fread(buffer.ptr, ubyte.sizeof, T.sizeof, file.getFP);

	return read!(T, Endian.littleEndian)(buffer);
}
