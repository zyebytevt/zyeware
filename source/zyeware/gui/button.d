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

    override void onCursorEnter() nothrow
    {
        mColor = Color.red;
    }

    override void onCursorExit() nothrow
    {
        mColor = Color.white;
    }

    override void onCursorPressed(MouseCode button) nothrow
    {
        ZyeWare.emit!GUIEventButton(this, GUIEventButton.Type.pressed, button);
    }

    override void onCursorReleased(MouseCode button) nothrow
    {
        ZyeWare.emit!GUIEventButton(this, GUIEventButton.Type.released, MouseCode.buttonLeft);
    }

    override void onCursorClicked(MouseCode button) nothrow
    {
        ZyeWare.emit!GUIEventButton(this, GUIEventButton.Type.clicked, MouseCode.buttonLeft);
    }

public:
    TextureAtlas atlas;

    this(GUINode parent, Sides anchor, Sides margin, string name = null)
    {
        super(parent, anchor, margin, name);
        
        mCheckForCursor = true;
    }
}