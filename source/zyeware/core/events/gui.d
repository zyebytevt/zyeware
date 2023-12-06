// This file is part of the ZyeWare Game Engine, and subject to the terms
// and conditions defined in the file 'LICENSE.txt', which is part
// of this source code package.
//
// Copyright 2021 ZyeByte
module zyeware.core.events.gui;

version(none):

import std.format : format;

import zyeware;
import zyeware.gui;

// ==============================================================

/// Represents any kind of event that happened in the GUI layer.
abstract class GUIEvent : Event
{
protected:
    GUINode mEmitter;

    this(GUINode emitter)
    {
        mEmitter = emitter;
    }

public:
    /// The `GUINode` instance that caused this event to occur.
    GUINode emitter() @property pure nothrow
    {
        return mEmitter;
    }
}

/// This event is emitted when a GUI button is interacted with.
class GUIEventButton : GUIEvent
{
protected:
    Type mType;
    MouseCode mButton;

public:
    /// The type of the interaction.
    enum Type
    {
        pressed, /// Mouse button has been pressed down.
        released, /// Mouse button has been depressed.
        clicked /// A click sequence occurred, which happens if a press and release have occurred on the button.
    }

    /// Params:
    ///   emitter = The node that caused this event to occur.
    ///   type = The type of interaction that happened.
    ///   button = The mouse button that caused the interaction.
    this(GUINode emitter, Type type, MouseCode button)
    {
        super(emitter);

        mType = type;
        mButton = button;
    }

    /// The type of interaction that happened.
    Type type() @property pure const nothrow
    {
        return mType;
    }

    /// The mouse button that caused the interaction.
    MouseCode button() @property pure nothrow
    {
        return mButton;
    }
}