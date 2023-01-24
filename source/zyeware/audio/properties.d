// This file is part of the ZyeWare Game Engine, and subject to the terms
// and conditions defined in the file 'LICENSE.txt', which is part
// of this source code package.
//
// Copyright 2021 ZyeByte
module zyeware.audio.properties;

import std.sumtype : SumType;

import zyeware.common;
import zyeware.audio;

struct ModuleLoopPoint
{
    int pattern;
    int row;
}

alias LoopPoint = SumType!(int, ModuleLoopPoint);

struct AudioProperties
{
    LoopPoint loopPoint = LoopPoint(0); /// The point to loop at. It differentiates between a frame or pattern & row (for modules)
}