// D import file generated from 'source/zyeware/core/events/gui.d'
module zyeware.core.events.gui;
version (none)
{
	import std.format : format;
	import zyeware;
	import zyeware.gui;
	abstract class GUIEvent : Event
	{
		protected
		{
			GUINode mEmitter;
			this(GUINode emitter);
			public pure nothrow @property GUINode emitter();
		}
	}
	class GUIEventButton : GUIEvent
	{
		protected
		{
			Type mType;
			MouseCode mButton;
			public
			{
				enum Type
				{
					pressed,
					released,
					clicked,
				}
				this(GUINode emitter, Type type, MouseCode button);
				const pure nothrow @property Type type();
				pure nothrow @property MouseCode button();
			}
		}
	}
}
