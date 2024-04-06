// This file is part of the ZyeWare Game Engine, and subject to the terms
// and conditions defined in the file 'LICENSE.txt', which is part
// of this source code package.
//
// Copyright © 2021-2024 ZyeByte. All rights reserved.
module zyeware.core.main;

import zyeware;
import zyeware.core.project;

extern (C) ProjectProperties getProjectProperties();

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
            ZyeWare.initialize(args, getProjectProperties());
            ZyeWare.start();
            ZyeWare.cleanup();

            return 0;
        }
        catch (Throwable t)
        {
            import zyeware.crashhandler : showCrashHandler;

            showCrashHandler(t);

            return 1;
        }
    }
}
