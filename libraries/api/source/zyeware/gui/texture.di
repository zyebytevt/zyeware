// D import file generated from 'source/zyeware/gui/texture.d'
module zyeware.gui.texture;
version (none)
{
	import zyeware;
	
	import zyeware.gui;
	class GUITexture : GUINode
	{
		protected
		{
			override const void customDraw(in FrameTime nextFrameTime);
			public
			{
				Texture2D texture;
				Rect2f region = Rect2f(0, 0, 1, 1);
				Color modulate = Color.white;
				this(GUINode parent, Sides anchor, Sides margin);
			}
		}
	}
}
