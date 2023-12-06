// D import file generated from 'source/zyeware/core/application.d'
module zyeware.core.application;
import core.memory : GC;
import std.algorithm : min;
import std.typecons : Nullable;
public import zyeware.core.gamestate;
import zyeware;
import zyeware.utils.collection;
abstract class Application
{
	public
	{
		abstract void initialize();
		abstract void tick();
		abstract void draw();
		void cleanup();
		void receive(in Event ev);
	}
}
class GameStateApplication : Application
{
	private
	{
		enum deferWarning = "Changing game state during event emission can cause instability. Use a deferred call instead.";
		protected
		{
			GrowableStack!GameState mStateStack;
			public
			{
				override void receive(in Event ev);
				override void tick();
				override void draw();
				void changeState(GameState state);
				void pushState(GameState state);
				void popState();
				pragma (inline, true)GameState currentState()
				{
					return mStateStack.peek;
				}
				pragma (inline, true)const nothrow bool hasState()
				{
					return !mStateStack.empty;
				}
			}
		}
	}
}
