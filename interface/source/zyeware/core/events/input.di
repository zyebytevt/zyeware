// D import file generated from 'source/zyeware/core/events/input.d'
module zyeware.core.events.input;
import std.string : format;
import std.typecons : Rebindable;
import zyeware.common;
import zyeware.core.events.event;
import zyeware.utils.codes;
import zyeware.rendering.display;
abstract class InputEvent : Event
{
	public abstract const nothrow bool matchInputTemplate(in InputEvent ev, float deadzone, out bool pressed, out float strength);
}
abstract class InputEventFromDisplay : InputEvent
{
	protected
	{
		Rebindable!(const(Display)) mDisplay;
		public
		{
			pure nothrow this(in Display display);
			final const pure nothrow const(Display) display();
		}
	}
}
class InputEventAction : InputEvent
{
	protected
	{
		string mAction;
		bool mIsPressed;
		float mStrength = 1.0F;
		public
		{
			pure nothrow this(string action, bool isPressed, float strength);
			final const pure nothrow string action();
			final const pure nothrow bool isPressed();
			final const pure nothrow float strength();
			override const nothrow bool matchInputTemplate(in InputEvent ev, float deadzone, out bool pressed, out float strength);
			override const string toString();
		}
	}
}
class InputEventKey : InputEventFromDisplay
{
	protected
	{
		KeyCode mKeycode;
		bool mIsPressed;
		public
		{
			pure nothrow this(in Display display, KeyCode keycode, bool isPressed);
			pure nothrow this(KeyCode keycode);
			final const pure nothrow KeyCode keycode();
			final const pure nothrow bool isPressed();
			override const nothrow bool matchInputTemplate(in InputEvent ev, float deadzone, out bool pressed, out float strength);
			override const string toString();
		}
	}
}
class InputEventText : InputEventFromDisplay
{
	protected
	{
		dchar mCodepoint;
		public
		{
			pure nothrow this(in Display display, dchar codepoint);
			final const pure nothrow dchar codepoint();
			override const nothrow bool matchInputTemplate(in InputEvent ev, float deadzone, out bool pressed, out float strength);
			override const string toString();
		}
	}
}
class InputEventMouseButton : InputEventFromDisplay
{
	protected
	{
		MouseCode mButton;
		bool mIsPressed;
		size_t mClickCount;
		public
		{
			pure nothrow this(in Display display, MouseCode button, bool isPressed, size_t clickCount);
			pure nothrow this(MouseCode button);
			final const pure nothrow MouseCode button();
			final const pure nothrow bool isPressed();
			final const pure nothrow size_t clickCount();
			override const nothrow bool matchInputTemplate(in InputEvent ev, float deadzone, out bool pressed, out float strength);
			override const string toString();
		}
	}
}
class InputEventMouseScroll : InputEventFromDisplay
{
	protected
	{
		Vector2f mOffset;
		public
		{
			pure nothrow this(in Display display, Vector2f offset);
			pure nothrow this(Vector2f offset);
			final const pure nothrow Vector2f offset();
			override const nothrow bool matchInputTemplate(in InputEvent ev, float deadzone, out bool pressed, out float strength);
			override const string toString();
		}
	}
}
class InputEventMouseMotion : InputEventFromDisplay
{
	protected
	{
		Vector2f mPosition;
		Vector2f mRelative;
		public
		{
			pure nothrow this(in Display display, Vector2f position, Vector2f relative);
			final const pure nothrow Vector2f position();
			final const pure nothrow Vector2f relative();
			override const nothrow bool matchInputTemplate(in InputEvent ev, float deadzone, out bool pressed, out float strength);
			override const string toString();
		}
	}
}
abstract class InputEventGamepad : InputEvent
{
	protected
	{
		size_t mGamepadIndex;
		pure nothrow this(size_t gamepadIndex);
		public final const pure nothrow size_t gamepadIndex();
	}
}
class InputEventGamepadButton : InputEventGamepad
{
	protected
	{
		bool mIsPressed;
		GamepadButton mButton;
		public
		{
			pure nothrow this(size_t gamepadIndex, GamepadButton button, bool isPressed);
			pure nothrow this(size_t gamepadIndex, GamepadButton button);
			final const pure nothrow GamepadButton button();
			final const pure nothrow bool isPressed();
			override const nothrow bool matchInputTemplate(in InputEvent ev, float deadzone, out bool pressed, out float strength);
			override const string toString();
		}
	}
}
class InputEventGamepadAxisMotion : InputEventGamepad
{
	protected
	{
		GamepadAxis mAxis;
		float mValue;
		public
		{
			pure nothrow this(size_t gamepadIndex, GamepadAxis axis, float value);
			final const pure nothrow GamepadAxis axis();
			final const pure nothrow float value();
			override const nothrow bool matchInputTemplate(in InputEvent ev, float deadzone, out bool pressed, out float strength);
			override const string toString();
		}
	}
}
class InputEventGamepadAdded : InputEventGamepad
{
	public
	{
		pure nothrow this(size_t gamepadIndex);
		override const nothrow bool matchInputTemplate(in InputEvent ev, float deadzone, out bool pressed, out float strength);
		override const string toString();
	}
}
class InputEventGamepadRemoved : InputEventGamepad
{
	public
	{
		pure nothrow this(size_t gamepadIndex);
		override const nothrow bool matchInputTemplate(in InputEvent ev, float deadzone, out bool pressed, out float strength);
		override const string toString();
	}
}
