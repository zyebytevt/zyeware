// This file is part of the ZyeWare Game Engine, and subject to the terms
// and conditions defined in the file 'LICENSE.txt', which is part
// of this source code package.
//
// Copyright 2021 ZyeByte
module zyeware.core.main;

import core.stdc.stdlib;

import std.stdio : stderr;

import bindbc.loader;

import zyeware.common;
import zyeware.core.application;

version (unittest)
{
    // Keep free for the Silly test runner.
}
else
{
    int main(string[] args)
    {
        try
        {
            ZyeWare.initialize(args);
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