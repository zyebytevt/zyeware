// D import file generated from 'source/zyeware/core/dynlib.d'
module zyeware.core.dynlib;
import core.runtime : Runtime;
static import std.path;
import std.exception : enforce, collectException;
import std.file : isDir, exists, write, tempDir, mkdirRecurse, remove;
import std.string : format;
import std.uuid : randomUUID;
import bindbc.loader;
import zyeware;
SharedLib loadDynamicLibrary(string vfsPath);
package(zyeware.core)
{
	void cleanDynamicLibraries();
	private extern __gshared string[] pLoadedLibraries;
}
