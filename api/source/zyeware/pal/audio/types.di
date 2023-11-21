// D import file generated from 'source/zyeware/pal/audio/types.d'
module zyeware.pal.audio.types;
import std.sumtype : SumType;
struct ModuleLoopPoint
{
	int pattern;
	int row;
}
alias Sample = int;
alias LoopPoint = SumType!(Sample, ModuleLoopPoint);
struct AudioProperties
{
	LoopPoint loopPoint = LoopPoint(0);
}
enum SourceState
{
	stopped,
	paused,
	playing,
}
