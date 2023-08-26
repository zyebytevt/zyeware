module zpklink.app;

import std.stdio;
import std.file;
import std.getopt;
import std.path;

import zpklink.file;

bool isVerbose;

int main(string[] args)
{
	// Get parameters
	string inputName, outputName;
	bool isExtract, isPack;

	auto helpInformation = getopt(
		args,
		"o|output", "The output of the specified action.", &outputName,
		"i|input", "The input of the specified action.", &inputName,
		"v|verbose", "Print extra information.", &isVerbose,
		"x|extract", "Extracts a ZPK input to a output directory.", &isExtract,
		"p|pack", "Packs an input directory into a output ZPK.", &isPack
	);

	// Check parameters
	if (helpInformation.helpWanted)
	{
		defaultGetoptPrinter("ZPKLINK, Copyright 2021 ZyeByte", helpInformation.options);
		return 0;
	}

	// Either none or both flags have been given.
	if (isExtract == isPack)
	{
		stderr.writeln("Need to know if to extract or to pack! (Specify with -p/--pack or -x/--extract)");
		return 1;
	}

	if (!inputName)
	{
		stderr.writeln("Need an input object! (Specify with -i or --input)");
		return 1;
	}

	if (!outputName)
	{
		stderr.writeln("Need an output object! (Specify with -o or --output)");
		return 1;
	}

	if (isPack)
		return pack(inputName, outputName);
	else if (isExtract)
		return extract(inputName, outputName);
	else
		assert(false, "Neither isPack nor isExtract is true! How did we even get here?");
}

struct FileInfo
{
	uint offset;
	uint size;
}

int pack(string sourceDirName, string targetZpkName)
{
	// Create ZPK file
	File zpkFile = File(targetZpkName, "wb");
	if (isVerbose)
		writefln("Creating ZPK file '%s'.", targetZpkName);
	
	FileInfo[string] fileInfos;
	uint centralDirectoryOffset;
	
	// Write magic number
	zpkFile.rawWrite("ZPK1");

	// Keep space for offset to central directory
	zpkFile.writePrimitive!uint(0);

	// Write all files
	foreach (string entry; dirEntries(sourceDirName, "*", SpanMode.breadth))
	{
		if (!isFile(entry))
			continue;

		File file = File(entry, "rb");

		if (file.size == 0)
		{
			file.close();
			continue;
		}

		string entryName = entry[sourceDirName.length .. $];
		if (entryName[0] == '/')
			entryName = entryName[1..$];

		fileInfos[entryName] = FileInfo(cast(uint) zpkFile.tell, cast(uint) file.size);
		if (isVerbose)
			writefln("Archiving '%s' at offset 0x%X, file size %d bytes.", entryName, zpkFile.tell, file.size);

		ubyte[] buffer = file.rawRead(new ubyte[file.size]);
		zpkFile.rawWrite(buffer);

		file.close();
	}
	
	// Central directory
	centralDirectoryOffset = cast(uint) zpkFile.tell;
	zpkFile.writePrimitive!uint(cast(uint) fileInfos.length);

	if (isVerbose)
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

	if (isVerbose)
	{
		writefln("ZPK size: %d bytes", zpkFile.size);
		writefln("Central directory size: %d bytes", zpkFile.size - centralDirectoryOffset);
		writeln("Done!");
	}

	zpkFile.close();

	return 0;
}

int extract(string sourceZpkName, string targetDirName)
{
	// Load ZPK file
	File zpkFile = File(sourceZpkName, "rb");
	if (isVerbose)
		writefln("Reading ZPK file '%s'...", sourceZpkName);

	// Check magic number
	char[4] magic;
	zpkFile.rawRead(magic);

	if (magic != "ZPK1")
	{
		stderr.writeln("Invalid ZPK file.");
		return 1;
	}

	// Go to central directory
	immutable uint centralDirectoryOffset = zpkFile.readPrimitive!uint();
    zpkFile.seek(centralDirectoryOffset);

	FileInfo[string] fileInfos;

	if (isVerbose)
		writeln("Parsing central directory...");

	// Read central directory
	immutable int fileAmount = zpkFile.readPrimitive!uint();
	for (size_t i; i < fileAmount; ++i)
	{
		immutable string fullPath = zpkFile.readPString!ushort();
		immutable int fileOffset = zpkFile.readPrimitive!uint();
		immutable int fileSize = zpkFile.readPrimitive!uint();

		fileInfos[fullPath] = FileInfo(fileOffset, fileSize);
	}

	if (isVerbose)
		writefln("Accounted for %d embedded file(s), extracting...", fileInfos.length);

	// Write out all files
	foreach (string path, FileInfo info; fileInfos)
	{
		if (info.size == 0)
		{
			writefln("File '%s' is zero-sized, skipping...", path);
			continue;
		}

		if (isVerbose)
			writefln("Extracting '%s' from offset 0x%X with size %d bytes...", path, info.offset, info.size);

		immutable string extractPath = buildNormalizedPath(targetDirName ~ "/", path);

		// Create directories in case they don't exist.
		mkdirRecurse(dirName(extractPath));

		ubyte[] fileData = new ubyte[info.size];
		zpkFile.seek(info.offset);
		zpkFile.rawRead(fileData);

		std.file.write(extractPath, fileData);

		destroy(fileData);
	}

	if (isVerbose)
		writeln("Done!");

	return 0;
}