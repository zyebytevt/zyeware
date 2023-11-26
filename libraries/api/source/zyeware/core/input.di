// D import file generated from 'source/zyeware/core/input.d'
module zyeware.core.input;
import std.typecons : scoped, Rebindable, rebindable;
import std.exception : assumeWontThrow;
import zyeware.common;
struct InputManager
{
	@disable this();
	@disable this(this);
	private static
	{
		Action[string] sActions;
		package(zyeware.core) static
		{
			nothrow void tick();
			void receive(in InputEvent ev);
			public static
			{
				class Action
				{
					private
					{
						float mDeadzone;
						Rebindable!(const(InputEvent))[] mInputs;
						bool mOldIsPressed;
						bool mCurrentIsPressed;
						float mCurrentStrength = 0.0F;
						pure nothrow this(float deadzone);
						bool receiveInputEvent(in InputEvent ev, out bool isPressed, out float strength);
						public
						{
							pure nothrow Action addInput(in InputEvent input);
							Action removeInput(in InputEvent input);
						}
					}
				}
				nothrow Action addAction(string name, float deadzone = 0.5F);
				nothrow void removeAction(string name);
				nothrow Action getAction(string name);
				nothrow bool isActionPressed(string name);
				nothrow bool isActionJustPressed(string name);
				nothrow bool isActionJustReleased(string name);
				nothrow float getActionStrength(string name);
			}
		}
	}
}
