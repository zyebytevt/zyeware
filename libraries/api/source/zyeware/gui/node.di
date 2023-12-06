// D import file generated from 'source/zyeware/gui/node.d'
module zyeware.gui.node;
version (none)
{
	import std.algorithm : countUntil, remove;
	import std.typecons : Tuple;
	import zyeware;
	struct Sides
	{
		enum zero = Sides(0, 0, 0, 0);
		enum one = Sides(1, 1, 1, 1);
		enum fill = Sides(0, 1, 1, 0);
		enum center = Sides(0.5, 0.5, 0.5, 0.5);
		enum topSide = Sides(0, 1, 0, 0);
		enum rightSide = Sides(0, 1, 1, 1);
		enum bottomSide = Sides(1, 1, 1, 0);
		enum leftSide = Sides(0, 0, 1, 0);
		float top;
		float right;
		float bottom;
		float left;
	}
	class GUINode
	{
		protected
		{
			GUINode mParent;
			string mName;
			Sides mMargin;
			Sides mAnchor;
			GUINode[] mChildren;
			Rect2f mArea;
			bool mMustUpdate;
			bool mIsPressedDown;
			bool mIsCursorHovering;
			bool mCheckForCursor;
			pragma (inline, true)final const nothrow Rect2f queryParentArea()
			{
				return mParent ? mParent.mArea : Rect2f(Vector2f(0), Vector2f(ZyeWare.framebufferSize));
			}
			final nothrow void checkForCursorEvent(in Event ev);
			nothrow void updateArea(Rect2f parentArea);
			pure nothrow bool customReceive(in Event ev);
			void customTick();
			const void customDraw();
			nothrow void arrangeChildren();
			nothrow void onCursorEnter();
			nothrow void onCursorExit();
			nothrow void onCursorPressed(MouseCode button);
			nothrow void onCursorReleased(MouseCode button);
			nothrow void onCursorClicked(MouseCode button);
			public
			{
				bool visible = true;
				this(GUINode parent, Sides anchor, Sides margin, string name = null);
				final void tick();
				final const void draw(in FrameTime nextFrameTime);
				final nothrow bool receive(in Event ev);
				final pure nothrow GUINode findByName(string name);
				final void addChild(GUINode node);
				final void removeChild(GUINode node);
				final pure GUINode getChild(size_t index);
				nothrow void translate(Vector2f translation);
				const pure nothrow @property const(GUINode[]) children();
				pure nothrow @property GUINode parent();
				const pure nothrow @property Rect2f area();
				const pure nothrow @property Sides margin();
				pure nothrow @property void margin(Sides value);
				const pure nothrow @property Sides anchor();
				pure nothrow @property void anchor(Sides value);
				const pure nothrow @property string name();
			}
		}
	}
}
