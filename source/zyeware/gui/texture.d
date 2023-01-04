// This file is part of the ZyeWare Game Engine, and subject to the terms
// and conditions defined in the file 'LICENSE.txt', which is part
// of this source code package.
//
// Copyright 2021 ZyeByte
module zyeware.gui.texture;

import zyeware.common;
import zyeware.rendering;
import zyeware.gui;

class GUITexture : GUINode
{
protected:
    override void customDraw(in FrameTime nextFrameTime) const
    {
        Renderer2D.drawRect(mArea, Matrix4f.identity, modulate, texture, region);
    }

public:
    Texture2D texture;
    Rect2f region = Rect2f(0, 0, 1, 1);
    Color modulate = Color.white;

    this(GUINode parent, Sides anchor, Sides margin)
    {
        super(parent, anchor, margin);
    }
}