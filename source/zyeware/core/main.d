// This file is part of the ZyeWare Game Engine, and subject to the terms
// and conditions defined in the file 'LICENSE.txt', which is part
// of this source code package.
//
// Copyright 2021 ZyeByte
module zyeware.core.main;

import core.stdc.stdlib;
import core.runtime : Runtime;
import core.thread : rt_moduleTlsCtor, rt_moduleTlsDtor;

import std.stdio : stderr;

import zyeware.common;
import zyeware.core.application;

/// Implement this function to return a valid ZyeWare application.
extern(C) ProjectProperties getProjectProperties();

version (unittest)
{
    // Keep free for the Silly test runner.
}
else
{
    export int main(string[] args)
    {
        try
        {
            import std.stdio;
            import zyeware.pal;

            writeln(Pal.registeredAudio);
            
            ZyeWare.initialize(args, getProjectProperties());
            ZyeWare.start();
            ZyeWare.cleanup();
            return 0;
        }
        catch (Throwable t)
        {
            if (ZyeWare.crashHandler)
                ZyeWare.crashHandler.show(t);
            else
                stderr.writeln(t.toString());

            abort();
        }
    }
}