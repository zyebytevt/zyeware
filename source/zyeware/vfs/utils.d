module zyeware.vfs.utils;

import std.string : indexOf, lastIndexOf;
import std.array : Appender;

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

string buildPath(string[] paths...) pure nothrow
{
    Appender!string result = "";

    foreach (string path; paths)
    {
        if (!path)
            continue;

        immutable char lastChar = result[].length > 0 ? result[][$ - 1] : '/';

        if (lastChar != '/' && lastChar != ':')
            result ~= '/';

        result ~= path;
    }

    return result[];
}
