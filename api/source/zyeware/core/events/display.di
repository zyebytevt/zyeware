// D import file generated from 'source/zyeware/core/events/display.d'
module zyeware.core.events.display;
import std.string : format;
import std.typecons : Rebindable;
import zyeware.common;
import zyeware.core.events.event;
import zyeware.rendering.display;
abstract class DisplayEvent : Event
{
	protected
	{
		Rebindable!(const(Display)) mDisplay;
		pure nothrow this(in Display display);
		public final const pure nothrow const(Display) display();
	}
}
class DisplayResizedEvent : DisplayEvent
{
	protected
	{
		Vector2i mSize;
		public
		{
			pure nothrow this(in Display display, Vector2i size);
			final const pure nothrow Vector2i size();
			override const string toString();
		}
	}
}
class DisplayMovedEvent : DisplayEvent
{
	protected
	{
		Vector2i mPosition;
		public
		{
			pure nothrow this(in Display display, Vector2i position);
			final const pure nothrow Vector2i position();
			override const string toString();
		}
	}
}
