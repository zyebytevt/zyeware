module zyeware.core.dynlib;

import core.runtime : Runtime;

static import std.path;
import std.exception : enforce;
import std.file : isDir, exists, write, tempDir, mkdirRecurse;
import std.digest.md : md5Of, toHexString;
import std.string : format;

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

    immutable string tempFileName = std.path.buildPath(tempDirectory, toHexString(md5Of(libraryFile.path)) ~ dllExtension);

    if (!exists(tempFileName))
        write(tempFileName, libraryFile.readAll!(void[]));
    
    void* handle = Runtime.loadLibrary(tempFileName);
    enforce!CoreException(handle, format!"Failed to load dynamic library '%s'."(vfsPath));

    Logger.core.log(LogLevel.debug_, "Extracted '%s' to '%s' and loaded it.", libraryFile.path, tempFileName);

    return SharedLib(handle);
}