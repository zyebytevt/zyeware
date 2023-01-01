module zyeware.utils.format;

import std.format : format;

import zyeware.common;

string bytesToString(size_t byteCount) pure nothrow
{
    immutable static string[] suffix = [
        "B", "KiB", "MiB", "GiB", "TiB", "PiB"
    ];

    size_t order = 0;
    double result = byteCount;
    
    while (result >= 1024 && order < suffix.length - 1)
    {
        ++order;
        result /= 1024;
    }

    try return format!"%.2f %s"(result, suffix[order]);
    catch (Exception ex)
    {
        return "<format error>";
    }
}