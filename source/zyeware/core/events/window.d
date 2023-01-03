// This file is part of the ZyeWare Game Engine, and subject to the terms
// and conditions defined in the file 'LICENSE.txt', which is part
// of this source code package.
//
// Copyright 2021 ZyeByte
module zyeware.core.events.window;

import std.string : format;

import zyeware.common;
import zyeware.core.events.event;
import zyeware.rendering.window;

/// WindowEvents are sent when something happens regarding windows.
abstract class WindowEvent : Event
{
protected:
    Window mWindow;

    /// Params:
    ///     window = The window this event was sent from.
    this(Window window) pure nothrow
    {
        mWindow = window;
    }

public:
    /// The window this event was sent from.
    final inout(Window) window() inout pure nothrow
    {
        return mWindow;
    }
}

/// This event is sent when a window has been resized.
/// Often times, this actually refers to the resizing of the <i>framebuffer</i>, and
/// not necessarily of the window itself.
class WindowResizedEvent : WindowEvent
{
protected:
    Vector2i mSize;

public:
    /// Params:
    ///     window = The window this event was sent from.
    ///     size = The size after resizing.
    this(Window window, Vector2i size) pure nothrow
    {
        super(window);
        mSize = size;
    }

    /// The size after resizing.
    final Vector2i size() const pure nothrow
    {
        return mSize;
    }

    override string toString() const
    {
        return format!"WindowResizedEvent(size: %s)"(mSize);
    }
}

/// This event is sent when a window has been moved.
class WindowMovedEvent : WindowEvent
{
protected:
    Vector2i mPosition;

public:
    /// Params:
    ///     window = The window this event was sent from.
    ///     position = The position after moving.
    this(Window window, Vector2i position) pure nothrow
    {
        super(window);
        mPosition = position;
    }

    /// The position after moving.
    final Vector2i position() const pure nothrow
    {
        return mPosition;
    }

    override string toString() const
    {
        return format!"WindowMovedEvent(position: %s)"(mPosition);
    }
}

version(none)
{
    class WindowOpenedEvent : WindowEvent
    {
    public:
        this(Window window) pure nothrow
        {
            super(window);
        }
    }

    class WindowClosedEvent : WindowEvent
    {
    public:
        this(Window window) pure nothrow
        {
            super(window);
        }
    }
}