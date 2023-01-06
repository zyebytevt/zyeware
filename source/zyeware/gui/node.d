// This file is part of the ZyeWare Game Engine, and subject to the terms
// and conditions defined in the file 'LICENSE.txt', which is part
// of this source code package.
//
// Copyright 2021 ZyeByte
module zyeware.gui.node;

import std.algorithm : countUntil, remove;
import std.typecons : Tuple;

import zyeware.common;

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
protected:
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

    pragma(inline, true)
    final Rect2f queryParentArea() const nothrow
    {
        return mParent ? mParent.mArea : Rect2f(Vector2f(0), Vector2f(ZyeWare.framebufferSize));
    }

    final void checkForCursorEvent(in Event ev) nothrow
    {
        if (auto cMotion = cast(InputEventMouseMotion) ev)
        {
            if (!mIsPressedDown)
            {
                Vector2f position = ZyeWare.convertWindowToFramebufferLocation(cMotion.position);
                immutable bool hovering = mArea.contains(position);

                if (hovering && !mIsCursorHovering)
                {
                    mIsCursorHovering = true;
                    onCursorEnter();
                }
                else if (!hovering && mIsCursorHovering)
                {
                    mIsCursorHovering = false;
                    onCursorExit();
                }
            }
        }
        else if (auto cButton = cast(InputEventMouseButton) ev)
        {
            // TODO: Why specifically buttonLeft?
            if (cButton.button == MouseCode.buttonLeft)
            {
                Vector2f position = ZyeWare.convertWindowToFramebufferLocation(ZyeWare.mainWindow.cursorPosition);
                immutable bool hovering = mArea.contains(position);

                if (cButton.isPressed() && hovering)
                {
                    mIsPressedDown = true;
                    onCursorPressed(cButton.button);
                }
                else if (!cButton.isPressed() && mIsPressedDown)
                {
                    onCursorReleased(cButton.button);
                    mIsPressedDown = false;

                    if (hovering)
                        onCursorClicked(cButton.button);
                    else
                    {
                        mIsCursorHovering = false;
                        onCursorExit();
                    }
                }
            }
        }
    }

    void updateArea(Rect2f parentArea) nothrow
    {
        immutable Vector2f parentSize = parentArea.max - parentArea.min;
        immutable Rect2f anchorPoints = Rect2f(
            parentArea.min.x + parentSize.x * mAnchor.left,
            parentArea.min.y + parentSize.y * mAnchor.top,
            parentArea.min.x + parentSize.x * mAnchor.right,
            parentArea.min.y + parentSize.y * mAnchor.bottom
        );

        mArea = Rect2f(
            anchorPoints.min.x + mMargin.left,
            anchorPoints.min.y + mMargin.top,
            anchorPoints.max.x - mMargin.right,
            anchorPoints.max.y - mMargin.bottom
        );

        arrangeChildren();

        mMustUpdate = false;
    }

    bool customReceive(in Event ev) pure nothrow
    {
        return false;
    }

    void customTick(in FrameTime frameTime)
    {
    }

    void customDraw(in FrameTime nextFrameTime) const
    {
    }

    void arrangeChildren() nothrow
    {
        foreach (GUINode node; mChildren)
            node.updateArea(mArea);
    }

    void onCursorEnter() nothrow {}
    void onCursorExit() nothrow {}
    void onCursorPressed(MouseCode button) nothrow {}
    void onCursorReleased(MouseCode button) nothrow {}
    void onCursorClicked(MouseCode button) nothrow {}

public:
    bool visible = true;

    this(GUINode parent, Sides anchor, Sides margin, string name = null)
    {
        if (parent)
            parent.addChild(this);

        mAnchor = anchor;
        mMargin = margin;
        mName = name;

        updateArea(queryParentArea());
    }

    final void tick(in FrameTime frameTime)
    {
        if (mMustUpdate)
            updateArea(queryParentArea());
        
        customTick(frameTime);

        foreach (node; mChildren)
            node.tick(frameTime);
    }
    
    final void draw(in FrameTime nextFrameTime) const
    {
        if (!visible)
            return;

        customDraw(nextFrameTime);

        foreach (node; mChildren)
            node.draw(nextFrameTime);
    }

    final bool receive(in Event ev) nothrow
    {
        if (mCheckForCursor)
            checkForCursorEvent(ev);
        
        if (customReceive(ev))
            return true;

        foreach (node; mChildren)
        {
            if (node.receive(ev))
                return true;
        }

        return false;
    }

    final GUINode findByName(string name) pure nothrow
    {
        if (name == mName)
            return this;

        foreach (GUINode child; mChildren)
        {
            GUINode result = child.findByName(name);
            if (result)
                return result;
        }

        return null;
    }

    final void addChild(GUINode node)
    {
        if (node.mParent)
            node.mParent.removeChild(node);
        
        mChildren ~= node;
        node.mParent = this;
        mMustUpdate = true;
    }

    final void removeChild(GUINode node)
    {
        immutable ptrdiff_t index = countUntil(mChildren, node);
        if (index > -1)
        {
            mChildren[index].mParent = null;
            mChildren = mChildren.remove(index);
            mMustUpdate = true;
        }
    }

    final GUINode getChild(size_t index) pure
    {
        if (index >= mChildren.length)
            return null;

        return mChildren[index];
    }

    void translate(Vector2f translation) nothrow
    {
        mMargin.left += translation.x;
        mMargin.right -= translation.x;
        mMargin.top += translation.y;
        mMargin.bottom -= translation.y;

        updateArea(queryParentArea());
    }

    const(GUINode[]) children() @property pure const nothrow
    {
        return mChildren;
    }

    GUINode parent() @property pure nothrow
    {
        return mParent;
    }

    Rect2f area() @property pure const nothrow
    {
        return mArea;
    }

    Sides margin() @property pure const nothrow
    {
        return mMargin;
    }

    void margin(Sides value) @property pure nothrow
    {
        mMargin = value;
        mMustUpdate = true;
    }

    Sides anchor() @property pure const nothrow
    {
        return mAnchor;
    }

    void anchor(Sides value) @property pure nothrow
    {
        mAnchor = value;
        mMustUpdate = true;
    }

    string name() @property pure const nothrow
    {
        return mName;
    }
}