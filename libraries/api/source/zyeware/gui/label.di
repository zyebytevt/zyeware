// D import file generated from 'source/zyeware/gui/label.d'
module zyeware.gui.label;
version (none)
{
	import zyeware;
	
	import zyeware.gui;
	class GUILabel : GUINode
	{
		protected
		{
			ubyte mAlignment;
			Vector2f mTextPosition;
			pure nothrow void updateTextPosition();
			override const void customDraw(in FrameTime nextFrameTime);
			override nothrow void updateArea(Rect2f parentArea);
			public
			{
				Font font;
				Color color = Color.white;
				string text;
				this(GUINode parent, Sides anchor, Sides margin);
				const pure nothrow @property ubyte alignment();
				pure nothrow @property void alignment(ubyte value);
			}
		}
	}
}
