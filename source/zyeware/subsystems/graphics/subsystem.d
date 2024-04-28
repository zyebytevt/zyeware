// This file is part of the ZyeWare Game Engine, and subject to the terms
// and conditions defined in the file 'LICENSE.txt', which is part
// of this source code package.
//
// Copyright © 2021-2024 ZyeByte. All rights reserved.
module zyeware.subsystems.graphics.subsystem;

import std.string : format;

import zyeware;
import zyeware.subsystems.graphics;

enum GraphicsFlag
{
    depthTesting, /// Whether to use depth testing or not.
    depthBufferWriting, /// Whether to write to the depth buffer when drawing.
    culling, /// Whether culling is enabled or not.
    stencilTesting, /// Whether to use stencil testing or not.
    wireframe /// Whether to render in wireframe or not.
}

enum GraphicsCapability
{
    maxTextureSlots /// How many texture slots are available to use. 
}

struct GraphicsSubsystem
{
    @disable this();
    @disable this(this);

private static:
    GraphicsCallbacks sCallbacks;
    Loader[string] sLoaders;

package(zyeware) static:
    alias Loader = void function(ref GraphicsCallbacks) nothrow;

    void load(string name)
    {
        auto loader = name in sLoaders;
        enforce!GraphicsException(loader, format!"Could not load graphics backend '%s'."(name));

        (*loader)(sCallbacks);
        sCallbacks.load();

        Logger.core.info("Graphics subsystem loaded.");
    }

    void unload()
    {
        sCallbacks.unload();
    }

    void registerLoader(string name, Loader loader) nothrow
    in (name, "Name cannot be null.")
    in (loader, "Loader cannot be null.")
    {
        sLoaders[name] = loader;
    }

    pragma(inline, true)
    ref const(GraphicsCallbacks) callbacks() nothrow => sCallbacks;
}