// D import file generated from 'source/zyeware/core/properties.d'
module zyeware.core.properties;
import std.conv : to;
import std.system : OS;
import zyeware;
struct ProjectProperties
{
	string authorName = "Anonymous";
	string projectName = "ZyeWare Project";
	DisplayProperties mainDisplayProperties;
	ScaleMode scaleMode = ScaleMode.center;
	string[OS] appLibraries;
	uint targetFrameRate = 60;
	static ProjectProperties load(string path);
}
