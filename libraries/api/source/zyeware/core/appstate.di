// D import file generated from 'source/zyeware/core/appstate.d'
module zyeware.core.appstate;
public import zyeware.core.application : StateApplication;
import zyeware;
abstract class AppState
{
	private
	{
		StateApplication mApplication;
		package(zyeware.core)
		{
			bool mWasAlreadyAttached;
			protected
			{
				pure nothrow this(StateApplication application);
				public
				{
					abstract void tick();
					abstract void draw();
					void onAttach(bool firstTime);
					void onDetach();
					void receive(in Event ev);
					inout pure nothrow inout(StateApplication) application();
					const pure nothrow bool wasAlreadyAttached();
				}
			}
		}
	}
}
