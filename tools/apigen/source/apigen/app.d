// This file is part of the ZyeWare Game Engine, and subject to the terms
// and conditions defined in the file 'LICENSE.txt', which is part
// of this source code package.
//
// Copyright 2023 ZyeByte
module apigen.app;

import std.stdio;
import std.parallelism : parallel;
import std.file : dirEntries, SpanMode, exists, mkdirRecurse, readText, write, remove;
import std.path : stripExtension, buildNormalizedPath, dirName, baseName;
import std.algorithm : filter;
import std.digest.md : md5Of;

import consolecolors;

import apigen.generator;

int main()
{
	if (!exists("source/zyeware"))
	{
		writeln("This program must be run from the root of the ZyeWare repository.");
		return 1;
	}

	auto generator = new InterfaceFileGenerator();

	mkdirRecurse("libraries/api/source/zyeware");

	auto dfiles = dirEntries("source/zyeware", "*.d", SpanMode.depth);
	bool[string] diFiles;

	foreach (string path; dirEntries("libraries/api/source/zyeware", "*.di", SpanMode.depth))
	{
		diFiles[path] = false;
	}

	foreach (sourcePath; parallel(dfiles))
	{
		immutable string resultDir = buildNormalizedPath("libraries/api/", dirName(sourcePath));
		mkdirRecurse(resultDir);
		immutable string resultFile = buildNormalizedPath(resultDir, stripExtension(baseName(sourcePath)) ~ ".di");

		diFiles[resultFile] = true;

		immutable string source = readText!string(sourcePath);
		immutable string result = generator.generate(source);

		if (exists(resultFile) && md5Of(result) == md5Of(readText!string(resultFile)))
		{
			cwritefln("<green>Up-to-date</green>: %s", sourcePath);
			continue;
		}

		cwritefln("<yellow>Generating</yellow>: %s (to %s)", sourcePath, resultFile);
		write(resultFile, result);
	}

	foreach (string path; diFiles.keys.filter!(a => !diFiles[a]))
	{
		cwritefln("<red>Removing</red>: %s", path);
		remove(path);
	}

	return 0;
}
