// This file is part of the ZyeWare Game Engine, and subject to the terms
// and conditions defined in the file 'LICENSE.txt', which is part
// of this source code package.
//
// Copyright 2021 ZyeByte
module zyeware.core.events.display;

import std.string : format;
import std.typecons : Rebindable;

import zyeware;
import zyeware.core.events.event;
import zyeware.rendering.display;

/// DisplayEvents are sent when something happens regarding displays.
abstract class DisplayEvent : Event
{
protected:
    Rebindable!(const Display) mDisplay;

    /// Params:
    ///     display = The display this event was sent from.
    this(in Display display) pure nothrow
    {
        mDisplay = display;
    }

public:
    /// The display this event was sent from.
    final const(Display) display() const pure nothrow
    {
        return mDisplay;
    }
}

/// This event is sent when a display has been resized.
/// Often times, this actually refers to the resizing of the <i>framebuffer</i>, and
/// not necessarily of the display itself.
class DisplayResizedEvent : DisplayEvent
{
protected:
    vec2i mSize;

public:
    /// Params:
    ///     display = The display this event was sent from.
    ///     size = The size after resizing.
    this(in Display display, vec2i size) pure nothrow
    {
        super(display);
        mSize = size;
    }

    /// The size after resizing.
    final vec2i size() const pure nothrow
    {
        return mSize;
    }

    override string toString() const
    {
        return format!"DisplayResizedEvent(size: %s)"(mSize);
    }
}

/// This event is sent when a display has been moved.
class DisplayMovedEvent : DisplayEvent
{
protected:
    vec2i mPosition;

public:
    /// Params:
    ///     display = The display this event was sent from.
    ///     position = The position after moving.
    this(in Display display, vec2i position) pure nothrow
    {
        super(display);
        mPosition = position;
    }

    /// The position after moving.
    final vec2i position() const pure nothrow
    {
        return mPosition;
    }

    override string toString() const
    {
        return format!"DisplayMovedEvent(position: %s)"(mPosition);
    }
}