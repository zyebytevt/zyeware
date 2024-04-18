// This file is part of the ZyeWare Game Engine, and subject to the terms
// and conditions defined in the file 'LICENSE.txt', which is part
// of this source code package.
//
// Copyright © 2021-2024 ZyeByte. All rights reserved.

/// This module is intended to be a end-all-be-all import for all
/// ZyeWare projects. It contains all necessary modules for 
/// developing a game with ZyeWare.
module zyeware;

public
{
    import std.typecons : Flag, Yes, No;
    import std.exception : enforce;
    import std.datetime : Duration, dur;

    import zyeware.core;

    import zyeware.math;

    import zyeware.subsystems;
    import zyeware.subsystems.physics.shapes.circle2d;
    import zyeware.subsystems.physics.shapes.polygon2d;
    import zyeware.subsystems.physics.shapes.shape2d;

    import zyeware.rendering;

    import zyeware.utils.codes;
    import zyeware.utils.collection;
    import zyeware.utils.format;
    import zyeware.utils.memory;
    import zyeware.utils.sdlang;
    import zyeware.utils.fsm;
    import zyeware.utils.interpolator;

    import zyeware.vfs;
}
