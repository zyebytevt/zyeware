module zyeware.core.dynlib;

import core.runtime : Runtime;

static import std.path;
import std.exception : enforce, collectException;
import std.file : isDir, exists, write, tempDir, mkdirRecurse, remove;
import std.string : format;
import std.uuid : randomUUID;

import bindbc.loader;

import zyeware;

// This function looks for a dynamic library in the VFS, saves it to a temporary file, and loads it.
SharedLib loadDynamicLibrary(string vfsPath)
{
    VfsFile libraryFile = Vfs.open(vfsPath);
    scope (exit) libraryFile.close();

    version (Posix)
        immutable string dllExtension = ".so";
    else version (Windows)
        immutable string dllExtension = ".dll";
    else version (OSX)
        immutable string dllExtension = ".dylib";
    else
        static assert(false, "Unsupported platform for loading dynamic libraries.");

    immutable string tempDirectory = std.path.buildPath(tempDir, "zyeware");
    mkdirRecurse(tempDirectory);

    immutable string tempFilePath = std.path.buildPath(tempDirectory, randomUUID.toString() ~ dllExtension);

    write(tempFilePath, libraryFile.readAll!(void[]));
    pLoadedLibraries ~= tempFilePath;
    
    void* handle = Runtime.loadLibrary(tempFilePath);
    enforce!CoreException(handle, format!"Failed to load dynamic library '%s'."(vfsPath));

    Logger.core.log(LogLevel.debug_, "Extracted '%s' to '%s' and loaded it.", libraryFile.path, tempFilePath);

    return SharedLib(handle);
}

package(zyeware.core):

void cleanDynamicLibraries()
{
    foreach (ref string path; pLoadedLibraries)
    {
        collectException(remove(path));
    }

    pLoadedLibraries.length = 0;
}

private:

__gshared string[] pLoadedLibraries;