// This file is part of the ZyeWare Game Engine, and subject to the terms
// and conditions defined in the file 'LICENSE.txt', which is part
// of this source code package.
//
// Copyright 2021 ZyeByte
module zyeware.audio.properties;

import std.sumtype : SumType;

import zyeware.common;
import zyeware.audio;

/// Contains information about a loop point for a module sound file.
struct ModuleLoopPoint
{
    int pattern; /// The pattern to loop from.
    int row; /// The row to loop from.
}

deprecated("This was still a joke.")
{
    /// Joke alias. Do not use in production.
    alias SoundFrame = Sample;
    /// Joke alias. Do not use in production.
    alias EarDrumPosition = Sample;
    /// Joke alias. Do not use in production.
    alias AirPressure = Sample;
    /// Joke alias. Do not use in production.
    alias SpeakerCoilCurrent = Sample;
}

/// Represents an audio sample position.
alias Sample = int;

/// A SumType for a loop point, containing either a sample position (`int`) or
/// pattern and row (`ModuleLoopPoint`).
alias LoopPoint = SumType!(Sample, ModuleLoopPoint);

/// Contains various data for Sound initialisation.
struct AudioProperties
{
    LoopPoint loopPoint = LoopPoint(0); /// The point to loop at. It differentiates between a sample or pattern & row (for modules)
}