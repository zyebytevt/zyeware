// This file is part of the ZyeWare Game Engine, and subject to the terms
// and conditions defined in the file 'LICENSE.txt', which is part
// of this source code package.
//
// Copyright © 2021-2024 ZyeByte. All rights reserved.
module zyeware.pal.pal;

import zyeware;
import zyeware.pal.generic.drivers;

package(zyeware):

struct Pal
{
    @disable this();
    @disable this(this);

private static:
    GraphicsDriver sGraphics;

    GraphicsDriverLoader[string] sGraphicsLoaders;

package(zyeware.pal) static:
    alias GraphicsDriverLoader = void function(ref GraphicsDriver) nothrow;

package(zyeware) static:
    void registerDrivers() nothrow
    {
        version (ZW_PAL_OPENGL)
            sGraphicsLoaders["opengl"] = &imported!"zyeware.pal.graphics.opengl.init".load;
    }

    void initializeDrivers()
    {
        sGraphics.api.initialize();
        sGraphics.r2d.initialize();
    }

    void cleanupDrivers()
    {
        sGraphics.api.cleanup();
        sGraphics.r2d.cleanup();
    }

    void loadGraphicsDriver(string name) nothrow
    in (name in sGraphicsLoaders, "GraphicsDriver " ~ name ~ " not registered")
    {
        sGraphicsLoaders[name](sGraphics);
        Logger.core.info("Set graphics driver '%s' active.", name);
    }

    string[] registeredGraphicsDrivers() nothrow
    {
        return sGraphicsLoaders.keys;
    }

    pragma(inline, true) ref const(GraphicsDriver) graphics() nothrow
    {
        return sGraphics;
    }
}
