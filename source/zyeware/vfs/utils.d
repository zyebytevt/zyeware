module zyeware.vfs.utils;

import std.string : indexOf, lastIndexOf;

string getScheme(string path) pure
{
    immutable ptrdiff_t index = path.indexOf(':');

    if (index == -1)
        return null;

    return path[0 .. index];
}

string stripScheme(string path) pure
{
    immutable ptrdiff_t index = path.indexOf(':');

    if (index == -1)
        return path;

    return path[index + 1 .. $];
}

string getExtension(string path) pure
{
    immutable ptrdiff_t index = path.lastIndexOf('.');

    if (index == -1)
        return null;

    return path[index + 1 .. $];
}

string stripExtension(string path) pure
{
    immutable ptrdiff_t index = path.lastIndexOf('.');

    if (index == -1)
        return path;

    return path[0 .. index];
}

string getBasename(string path) pure
{
    immutable ptrdiff_t index = path.lastIndexOf('/');

    if (index == -1)
        return path;

    return path[index + 1 .. $];
}

string getDirname(string path) pure
{
    immutable ptrdiff_t index = path.lastIndexOf('/');

    if (index == -1)
        return path;

    return path[0 .. index];
}