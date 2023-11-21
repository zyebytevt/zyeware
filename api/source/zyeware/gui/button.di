// D import file generated from 'source/zyeware/gui/button.d'
module zyeware.gui.button;
version (none)
{
	import zyeware.common;
	import zyeware.rendering;
	import zyeware.gui;
	class GUIButton : GUINode
	{
		protected
		{
			Color mColor = Color.white;
			override const void customDraw(in FrameTime nextFrameTime);
			override nothrow void onCursorEnter();
			override nothrow void onCursorExit();
			override nothrow void onCursorPressed(MouseCode button);
			override nothrow void onCursorReleased(MouseCode button);
			override nothrow void onCursorClicked(MouseCode button);
			public
			{
				TextureAtlas atlas;
				this(GUINode parent, Sides anchor, Sides margin, string name = null);
			}
		}
	}
}
