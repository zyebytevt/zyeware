module zyeware.core.dynlib;

import core.runtime : Runtime;

import std.file : isDir, exists, write, tempDir;

import bindbc.loader;

import zyeware;

version(none)
SharedLib loadDynamicLibrary(string vfsPath)
{
    VfsFile libraryFile = Vfs.open(vfsPath);
    scope (exit) libraryFile.close();

    
}