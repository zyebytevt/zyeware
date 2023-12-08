// D import file generated from 'source/zyeware/core/application.d'
module zyeware.core.application;
import core.memory : GC;
import std.algorithm : min;
import std.typecons : Nullable;
public import zyeware.core.appstate;
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
class StateApplication : Application
{
	private
	{
		enum deferWarning = "Changing game state during event emission can cause instability. Use a deferred call instead.";
		protected
		{
			GrowableStack!AppState mStateStack;
			public
			{
				override void receive(in Event ev);
				override void tick();
				override void draw();
				void changeState(AppState state);
				void pushState(AppState state);
				void popState();
				pragma (inline, true)AppState currentState()
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
