// This file is part of the ZyeWare Game Engine, and subject to the terms
// and conditions defined in the file 'LICENSE.txt', which is part
// of this source code package.
//
// Copyright 2021 ZyeByte
module zyeware.core.cursor;

import std.exception : enforce, assumeWontThrow;
import std.typecons : Tuple, Rebindable;

import zyeware.common;
import zyeware.rendering;

final class VirtualCursor
{
protected:
    alias ShapeTexture = Tuple!(Texture2D, "texture", Vector2f, "pivot");

    Vector2f mPosition;
    Vector2f mScale;

    Rect2f mDimensions;
    bool mVisible;

    ShapeTexture[Shape] mShapeTextures;
    Rebindable!(const Texture2D) mTexture;
    Vector2f mPivot;
    
    Shape mShape;

    void move(Vector2f amount) nothrow
    {
        mPosition.x = clamp(mPosition.x + amount.x, 0, ZyeWare.framebufferSize.x);
        mPosition.y = clamp(mPosition.y + amount.y, 0, ZyeWare.framebufferSize.y);

        ZyeWare.emit!VirtualCursorEventMotion(this, mPosition);
    }

public:
    enum Shape
    {
        arrow,
        iBeam,
        pointingHand,
        cross,
        wait,
        busy,
        drag,
        canDrop,
        forbidden,
        move,
        help
    }

    Color color = Color.white;

    this()
    {
        mPosition = Vector2f(0);
        mScale = Vector2f(1);
        mPivot = Vector2f(0);

        setShapeTexture(Shape.arrow, AssetManager.load!Texture2D("core://textures/default-cursor/arrow.png"), Vector2f(0));
        setShapeTexture(Shape.pointingHand, AssetManager.load!Texture2D("core://textures/default-cursor/pointing-hand.png"), Vector2f(7, 0));

        this.shape = Shape.arrow;
    }

    void draw(in FrameTime nextFrameTime) const
    {
        Renderer2D.drawRect(mDimensions, mPosition - mPivot, mScale, color, mTexture);
    }

    void receive(in Event ev)
    {
        if (auto mev = cast(InputEventMouseMotion) ev)
            move(mev.relative);
        else if (auto mbutton = cast(InputEventMouseButton) ev)
            ZyeWare.emit!VirtualCursorEventButton(this, mPosition, mbutton.button, mbutton.isPressed);
    }

    /// Returns the cursor position inside the framebuffer.
    Vector2f position() @property const nothrow
    {
        return mPosition;
    }

    void position(Vector2f value) @property nothrow
    {
        mPosition = Vector2f(
            clamp(value.x, 0, ZyeWare.framebufferSize.x),
            clamp(value.y, 0, ZyeWare.framebufferSize.y)
        );
    }

    bool visible() @property pure const nothrow
    {
        return mVisible;
    }

    void visible(bool value) @property
    {
        mVisible = value;
        ZyeWare.mainWindow.isCursorCaptured = value;
    }

    pragma(inline, true)
    const(ShapeTexture) getShapeTexture(Shape shape) const pure nothrow
    {
        return mShapeTextures.get(shape, mShapeTextures[Shape.arrow]).assumeWontThrow;
    }

    void setShapeTexture(Shape shape, in Texture2D texture, Vector2f pivot)
    {
        if (shape == Shape.arrow && !texture)
            throw new CoreException("Cannot set 'arrow' shape to null texture.");

        mShapeTextures[shape] = ShapeTexture(cast(Texture2D) texture, pivot);

        // To update dimensions
        if (mShape == shape)
            this.shape = shape;
    }

    Shape shape() @property pure const nothrow
    {
        return mShape;
    }

    void shape(Shape value) @property pure nothrow
    {
        auto shapeInfo = getShapeTexture(value);

        mTexture = shapeInfo.texture;
        mPivot = shapeInfo.pivot;
        mDimensions = Rect2f(Vector2f(0), Vector2f(mTexture.size));
    }
}