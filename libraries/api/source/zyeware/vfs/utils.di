// D import file generated from 'source/zyeware/vfs/utils.d'
module zyeware.vfs.utils;
import std.string : indexOf, lastIndexOf;
import std.array : Appender;
pure string getScheme(string path);
pure string stripScheme(string path);
pure string getExtension(string path);
pure string stripExtension(string path);
pure string getBasename(string path);
pure string getDirname(string path);
pure nothrow string buildPath(string[] paths...);
