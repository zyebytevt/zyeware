// D import file generated from 'source/zyeware/core/gamestate.d'
module zyeware.core.gamestate;
public import zyeware.core.application : GameStateApplication;
import zyeware;
abstract class GameState
{
	private
	{
		GameStateApplication mApplication;
		package(zyeware.core)
		{
			bool mWasAlreadyAttached;
			protected
			{
				pure nothrow this(GameStateApplication application);
				public
				{
					abstract void tick();
					abstract void draw();
					void onAttach(bool firstTime);
					void onDetach();
					void receive(in Event ev);
					inout pure nothrow inout(GameStateApplication) application();
					const pure nothrow bool wasAlreadyAttached();
				}
			}
		}
	}
}
