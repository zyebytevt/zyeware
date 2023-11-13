module zyeware.pal.audio.types;

import std.sumtype : SumType;

/// Contains information about a loop point for a module sound file.
struct ModuleLoopPoint
{
    int pattern; /// The pattern to loop from.
    int row; /// The row to loop from.
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

/// Represents what state the audio source is currently in.
enum SourceState
{
    stopped, /// Currently no playback.
    paused, /// Playback was paused and can be resumed.
    playing /// Currently playing audio.
}