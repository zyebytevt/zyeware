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
            import zyeware.platform.opengl.loader : loadOpenGl;
            import zyeware.subsystems.graphics.subsystem : GraphicsSubsystem;
            GraphicsSubsystem.registerLoader("opengl", &loadOpenGl);

            ZyeWare.load(args, getProjectProperties());
            ZyeWare.start();
            ZyeWare.unload();

            return 0;
        }
        catch (Throwable t)
        {
            import std.stdio : writeln;
            writeln(t);

            return 1;
        }
    }
}
