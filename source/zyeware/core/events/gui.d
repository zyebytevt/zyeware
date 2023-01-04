// This file is part of the ZyeWare Game Engine, and subject to the terms
// and conditions defined in the file 'LICENSE.txt', which is part
// of this source code package.
//
// Copyright 2021 ZyeByte
module zyeware.core.events.gui;

import std.format : format;

import zyeware.common;
import zyeware.gui;

/*
abstract class VirtualCursorEvent : Event
{
protected:
    VirtualCursor mCursor;

    this(VirtualCursor cursor) pure nothrow
    {
        mCursor = cursor;
    }

public:
    inout(VirtualCursor) cursor() @property pure inout nothrow
    {
        return mCursor;
    }
}

class VirtualCursorEventButton : VirtualCursorEvent
{
protected:
    Vector2f mPosition;
    MouseCode mButton;
    bool mIsPressed;

public:
    /// Params:
    ///     button = The mouse code of the button that was activated.
    ///     isPressed = Whether the button was pressed or not.
    this(VirtualCursor cursor, Vector2f position, MouseCode button, bool isPressed) pure nothrow
    {
        super(cursor);

        mPosition = position;
        mButton = button;
        mIsPressed = isPressed;
    }

    /// The current cursor position.
    Vector2f position() @property const pure nothrow
    {
        return mPosition;
    }

    /// The mouse code of the button that was activated.
    MouseCode button() @property const pure nothrow
    {
        return mButton;
    }

    /// Whether the button was pressed or not.
    bool isPressed() @property const pure nothrow
    {
        return mIsPressed;
    }

    override string toString() const
    {
        return format!"VirtualCursorEventButton(cursor: %s, button: %d, isPressed: %s)"(mCursor, mButton, mIsPressed);
    }
}

class VirtualCursorEventMotion : VirtualCursorEvent
{
protected:
    Vector2f mPosition;

public:
    /// Params:
    ///     window = The window this event was sent from.
    ///     position = The current cursor position.
    this(VirtualCursor cursor, Vector2f position) pure nothrow
    {
        super(cursor);

        mPosition = position;
    }

    /// The current cursor position.
    Vector2f position() @property const pure nothrow
    {
        return mPosition;
    }

    override string toString() const
    {
        return format!"VirtualCursorEventMotion(cursor: %s, position: %s)"(mCursor, mPosition);
    }
}
*/

// ==============================================================

abstract class GUIEvent : Event
{
protected:
    GUINode mEmitter;

    this(GUINode emitter)
    {
        mEmitter = emitter;
    }

public:
    GUINode emitter() @property pure nothrow
    {
        return mEmitter;
    }
}

class GUIEventButton : GUIEvent
{
protected:
    Type mType;
    MouseCode mButton;

public:
    enum Type
    {
        pressed,
        released,
        clicked
    }

    this(GUINode emitter, Type type, MouseCode button)
    {
        super(emitter);

        mType = type;
        mButton = button;
    }

    Type type() @property pure const nothrow
    {
        return mType;
    }

    MouseCode button() @property pure nothrow
    {
        return mButton;
    }
}