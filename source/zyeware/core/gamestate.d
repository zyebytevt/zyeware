// This file is part of the ZyeWare Game Engine, and subject to the terms
// and conditions defined in the file 'LICENSE.txt', which is part
// of this source code package.
//
// Copyright 2021 ZyeByte
module zyeware.core.gamestate;

public import zyeware.core.application : GameStateApplication;

import zyeware;


/// A game state is used in conjunction with a `GameStateApplication` instance
/// to make managing an application with different states easier.
abstract class GameState
{
private:
    GameStateApplication mApplication;

package(zyeware.core):
    bool mWasAlreadyAttached;

protected:
    this(GameStateApplication application) pure nothrow
        in (application, "Parent application cannot be null.")
    {
        mApplication = application;
    }

public:
    /// Override this function to perform logic every frame.
    ///
    /// Params:
    ///     frameTime = The time between this frame and the last.
    abstract void tick();

    /// Override this function to perform rendering.
    abstract void draw();
    
    /// Called when this game state gets attached to a `GameStateApplication`.
    ///
    /// Params:
    ///     firstTime = Whether it gets attached the first time or not.
    void onAttach(bool firstTime) {}

    /// Called when this game state gets detached from a `GameStateApplication`.
    void onDetach() {}
    
    /// Handles the specified event in whatever manners seem appropriate.
    ///
    /// Params:
    ///     ev = The event to handle.
    void receive(in Event ev) {}

    /// The application this game state is registered to.
    inout(GameStateApplication) application() pure inout nothrow
    {
        return mApplication;
    }

    /// Whether this game state was already attached once or not.
    bool wasAlreadyAttached() pure const nothrow
    {
        return mWasAlreadyAttached;
    }
}