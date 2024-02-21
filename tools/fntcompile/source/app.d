module fntcompile.app;

import std.stdio;
import std.getopt;

import fntcompile.font;

bool isVerbose;

int main(string[] args) {
	string inputName, outputName;

	auto helpInformation = getopt(
		args,
		"o|output", "The output of the specified action.", &outputName,
		"i|input", "The input of the specified action.", &inputName,
		"v|verbose", "Print extra information.", &isVerbose,
	);

	if (helpInformation.helpWanted) {
		defaultGetoptPrinter("FNTCompile, Copyright 2023 ZyeByte", helpInformation.options);
		return 0;
	}

	if (!inputName) {
		stderr.writeln("Need a source font description! (Specify with -i or --input)");
		return 1;
	}

	if (!outputName) {
		stderr.writeln("Need an output name! (Specify with -o or --output)");
		return 1;
	}

	convert(inputName, outputName);
	return 0;
}
