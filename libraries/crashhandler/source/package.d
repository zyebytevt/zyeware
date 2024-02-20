module zyeware.crashhandler;

import core.thread;

import std.string : split, startsWith;
import std.stdio;

void showCrashHandler(Throwable t)
{
    writeln("==================== Unhandled throwable '%s' ====================",
        typeid(t).toString().split(".")[$-1]);
    writeln("Details: %s", t.message);

    foreach (trace; t.info)
        if (!trace.startsWith("??:?"))
            writeln(trace);
}