// This file is part of the ZyeWare Game Engine, and subject to the terms
// and conditions defined in the file 'LICENSE.txt', which is part
// of this source code package.
//
// Copyright 2021 ZyeByte
module zyeware.gui.button;

import zyeware.common;
import zyeware.rendering;
import zyeware.gui;

class GUIButton : GUINode
{
protected:
    Color mColor = Color.white;

    override void customDraw(in FrameTime nextFrameTime) const
    {
        Renderer2D.drawRect(mArea, Matrix4f.identity, mColor);
    }

    override void onCursorEnter(VirtualCursor cursor) nothrow
    {
        cursor.shape = VirtualCursor.Shape.pointingHand;
    }

    override void onCursorExit(VirtualCursor cursor) nothrow
    {
        cursor.shape = VirtualCursor.Shape.arrow;
    }

    override void onCursorPressed(VirtualCursor cursor) nothrow
    {
        ZyeWare.emit!GUIEventCursorButton(this, cursor, GUIEventCursorButton.Type.pressed, MouseCode.buttonLeft);
    }

    override void onCursorReleased(VirtualCursor cursor) nothrow
    {
        ZyeWare.emit!GUIEventCursorButton(this, cursor, GUIEventCursorButton.Type.released, MouseCode.buttonLeft);
    }

    override void onCursorClicked(VirtualCursor cursor) nothrow
    {
        ZyeWare.emit!GUIEventCursorButton(this, cursor, GUIEventCursorButton.Type.clicked, MouseCode.buttonLeft);
    }

public:
    TextureAtlas atlas;

    this(GUINode parent, Sides anchor, Sides margin, string name = null)
    {
        super(parent, anchor, margin, name);
        
        mCheckForCursor = true;
    }
}