// This file is part of the ZyeWare Game Engine, and subject to the terms
// and conditions defined in the file 'LICENSE.txt', which is part
// of this source code package.
//
// Copyright 2021 ZyeByte
module zyeware.gui.label;

import zyeware.common;
import zyeware.rendering;
import zyeware.gui;

class GUILabel : GUINode
{
protected:
    ubyte mAlignment;
    Vector2f mTextPosition;

    void updateTextPosition() pure nothrow
    {
        immutable Vector2f size = mArea.max - mArea.min;

        if (mAlignment & Font.Alignment.left)
            mTextPosition.x = mArea.min.x;
        else if (mAlignment & Font.Alignment.right)
            mTextPosition.x = mArea.max.x;
        else if (mAlignment & Font.Alignment.center)
            mTextPosition.x = mArea.min.x + size.x / 2;

        if (mAlignment & Font.Alignment.top)
            mTextPosition.y = mArea.min.y;
        else if (mAlignment & Font.Alignment.bottom)
            mTextPosition.y = mArea.max.y;
        else if (mAlignment & Font.Alignment.middle)
            mTextPosition.y = mArea.min.y + size.y / 2;
    }

    override void customDraw(in FrameTime nextFrameTime) const
    {
        Renderer2D.drawString(text, font, mTextPosition, color, mAlignment);
    }

    override void updateArea(Rect2f parentArea) nothrow
    {
        super.updateArea(parentArea);
        updateTextPosition();
    }

public:
    Font font;
    Color color = Color.white;
    string text;

    this(GUINode parent, Sides anchor, Sides margin)
    {
        super(parent, anchor, margin);
        mTextPosition = area.min;
        font = AssetManager.load!Font("core://fonts/internal.fnt");
    }

    ubyte alignment() @property pure const nothrow
    {
        return mAlignment;
    }

    void alignment(ubyte value) @property pure nothrow
    {
        mAlignment = value;
        updateTextPosition();
    }
}