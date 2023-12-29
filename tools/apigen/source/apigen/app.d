// This file is part of the ZyeWare Game Engine, and subject to the terms
// and conditions defined in the file 'LICENSE.txt', which is part
// of this source code package.
//
// Copyright 2023 ZyeByte
module apigen.app;

import std.stdio;
import std.parallelism : parallel;
import std.file : dirEntries, SpanMode, exists, mkdirRecurse, readText, write, remove, timeLastModified;
import std.path : stripExtension, buildNormalizedPath, dirName, baseName;
import std.datetime : SysTime, unixTimeToStdTime;
import std.algorithm : filter;
import std.json;

import consolecolors;

import apigen.generator;

int main()
{
	if (!exists("source/zyeware"))
	{
		cwriteln("<red>This program must be run from the root of the ZyeWare repository.</red>");
		return 1;
	}

	cwritefln("<lgreen>%12s</lgreen> Generating ZyeWare API files.", "Starting");

	SysTime[string] lastKnownModifications;
	bool[string] filesParsed;

	size_t upToDateCount, outOfDateCount, removedCount;

	// If it exists, get the last modified times from a json
	if (exists(".apigen.json"))
	{
		JSONValue root = parseJSON(readText(".apigen.json"), 1);
		foreach (string key, JSONValue value; root.object)
			lastKnownModifications[key] = SysTime(value.integer);
	}

	auto generator = new InterfaceFileGenerator();

	// Generate the output directory
	mkdirRecurse("libraries/api/source/zyeware");

	foreach (string path; dirEntries("libraries/api/source/zyeware", "*.di", SpanMode.depth))
		filesParsed[path] = false;

	auto dfiles = dirEntries("source/zyeware", "*.d", SpanMode.depth);

	foreach (sourcePath; parallel(dfiles))
	{
		immutable SysTime lastKnownModification = lastKnownModifications.get(sourcePath, SysTime.min);
		immutable SysTime lastModification = timeLastModified(sourcePath);

		immutable string resultDir = buildNormalizedPath("libraries/api/", dirName(sourcePath));
		immutable string resultFile = buildNormalizedPath(resultDir, stripExtension(baseName(sourcePath)) ~ ".di");
		filesParsed[resultFile] = true;

		if (exists(resultFile) && lastKnownModification >= lastModification)
		{
			cwritefln("<green>%12s</green> %s", "Up-to-date", sourcePath);
			++upToDateCount;
			continue;
		}

		cwritefln("<yellow>%12s</yellow> %s", "Generating", resultFile);
		mkdirRecurse(resultDir);
		write(resultFile, generator.generate(readText!string(sourcePath)));

		++outOfDateCount;
		lastKnownModifications[sourcePath] = lastModification;
	}

	foreach (string path; filesParsed.keys.filter!(a => !filesParsed[a]))
	{
		cwritefln("<red>%12s</red> %s", "Removing", path);
		remove(path);
		++removedCount;
	}

	// Write the last modified times to a json
	JSONValue[string] root;
	foreach (string key, SysTime value; lastKnownModifications)
		root[key] = JSONValue(value.stdTime);
	auto toSave = JSONValue(root);
	write(".apigen.json", toJSON(toSave, true));

	cwritefln("<green>%12s</green> <green>%d</green> up-to-date, <yellow>%d</yellow> (re)generated, <red>%d</red> removed.",
		"Finished", upToDateCount, outOfDateCount, removedCount);

	return 0;
}
