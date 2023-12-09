// D import file generated from 'source/zyeware/core/dynlib.d'
module zyeware.core.dynlib;
import core.runtime : Runtime;
static import std.path;
import std.exception : enforce;
import std.file : isDir, exists, write, tempDir;
import std.digest.md : md5Of, toHexString;
import std.string : format;
import bindbc.loader;
import zyeware;
SharedLib loadDynamicLibrary(string vfsPath);
