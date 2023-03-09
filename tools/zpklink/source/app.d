module app;

import std.stdio;
import std.file;
import std.bitmanip;
import std.getopt;

int main(string[] args)
{
	// Get parameters
	string inputDirectoryName, outputFileName;
	bool verbose;

	auto helpInformation = getopt(
		args,
		"o|output", "The target ZPK file.", &outputFileName,
		"i|input", "The directory which will act as root.", &inputDirectoryName,
		"v|verbose", "Print extra information.", &verbose
	);

	// Check parameters
	if (helpInformation.helpWanted)
	{
		defaultGetoptPrinter("ZPKLINK, Copyright 2021 ZyeByte", helpInformation.options);
		return 0;
	}

	if (!inputDirectoryName)
	{
		stderr.writeln("Need a source directory! (Specify with -i or --input)");
		return 1;
	}

	if (!outputFileName)
	{
		stderr.writeln("Need a target ZPK! (Specify with -o or --output)");
		return 1;
	}

	// Create ZPK file
	File zpkFile = File(outputFileName, "wb");
	if (verbose)
		writefln("Creating ZPK file '%s'.", outputFileName);
	
	FileInfo[string] fileInfos;
	uint centralDirectoryOffset;
	
	// Write magic number
	zpkFile.rawWrite("ZPK1");

	// Keep space for offset to central directory
	zpkFile.writePrimitive!uint(0);

	// Write all files
	foreach (string entry; dirEntries(inputDirectoryName, "*", SpanMode.breadth))
	{
		if (!isFile(entry))
			continue;

		File file = File(entry, "rb");

		if (file.size == 0)
		{
			file.close();
			continue;
		}

		string entryName = entry[inputDirectoryName.length .. $];
		if (entryName[0] == '/')
			entryName = entryName[1..$];

		fileInfos[entryName] = FileInfo(cast(uint) zpkFile.tell, cast(uint) file.size);
		if (verbose)
			writefln("Archiving '%s' at offset 0x%X, file size %d bytes.", entryName, zpkFile.tell, file.size);

		ubyte[] buffer = file.rawRead(new ubyte[file.size]);
		zpkFile.rawWrite(buffer);

		file.close();
	}
	
	// Central directory
	centralDirectoryOffset = cast(uint) zpkFile.tell;
	zpkFile.writePrimitive!uint(cast(uint) fileInfos.length);

	if (verbose)
		writefln("Writing central directory at offset 0x%X...", centralDirectoryOffset);

	foreach (string path, ref FileInfo info; fileInfos)
	{
		zpkFile.writePString!ushort(path);
		zpkFile.writePrimitive!uint(info.offset);
		zpkFile.writePrimitive!uint(info.size);
	}

	// Write offset to central directory at beginning
	zpkFile.seek(4);
	zpkFile.writePrimitive!uint(centralDirectoryOffset);

	if (verbose)
	{
		writefln("ZPK size: %d bytes", zpkFile.size);
		writefln("Central directory size: %d bytes", zpkFile.size - centralDirectoryOffset);
		writeln("Done!");
	}

	zpkFile.close();

	return 0;
}

struct FileInfo
{
	uint offset;
	uint size;
}

private:

void writePString(LengthType = uint)(File file, string text)
{
	file.writePrimitive(cast(LengthType) text.length);
	fwrite(text.ptr, char.sizeof, text.length, file.getFP);
}

string readPString(LengthType = uint)(File file)
{
	LengthType length = file.readPrimitive!LengthType;
	char[] str = new char[length];

	fread(str.ptr, char.sizeof, length, file.getFP);
	return str.idup;
}

void writePrimitive(T)(File file, T value)
{
	ubyte[] data = new ubyte[T.sizeof];
	write!(T, Endian.littleEndian)(data, value, 0);

	fwrite(data.ptr, ubyte.sizeof, T.sizeof, file.getFP);
}

T readPrimitive(T)(File file)
{
	ubyte[] buffer = new ubyte[T.sizeof];
	fread(buffer.ptr, ubyte.sizeof, T.sizeof, file.getFP);

	return read!(T, Endian.littleEndian)(buffer);
}