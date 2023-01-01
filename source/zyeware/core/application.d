// This file is part of the ZyeWare Game Engine, and subject to the terms
// and conditions defined in the file 'LICENSE.txt', which is part
// of this source code package.
//
// Copyright 2021 ZyeByte
module zyeware.core.application;

import core.memory : GC;
import std.exception : enforce, collectException;
import std.algorithm : min;

public import zyeware.core.gamestate;
import zyeware.common;
import zyeware.utils.collection;
import zyeware.rendering;

/// Represents an application that can be run by ZyeWare.
/// To write a ZyeWare app, you must inherit from this class and return an
/// instance of it with the `createZyeWareApplication` function.
///
/// Examples:
/// --------------------
/// class MyApplication : Application
/// {
///     ...    
/// }
///
/// extern(C) Application createZyeWareApplication(string[] args)
/// {
///     return new MyApplication(args);   
/// }
/// --------------------
abstract class Application
{
protected:
    Framebuffer mFramebuffer;
    Matrix4f mFramebufferProjection;
    Matrix4f mWindowProjection;
    Rect2f mFramebufferArea;
    ScaleMode mScaleMode;
    string[] mProgramArgs;
    
    this(string[] programArgs) pure nothrow
        in (programArgs, "Program arguments cannot be null.")
    {
        mProgramArgs = programArgs;
    }

    void recalculateFramebufferArea() nothrow
    {
        immutable Vector2ui winSize = mWindow.size;
        immutable Vector2ui gameSize = mFramebuffer.properties.size;

        Vector2f finalPos, finalSize;

        final switch (mScaleMode) with (ScaleMode)
        {
        case center:
            finalPos = Vector2f(winSize.x / 2 - gameSize.x / 2, winSize.y / 2 - gameSize.y / 2);
            finalSize = Vector2f(gameSize);
            break;

        case keepAspect:
            immutable float scale = min(cast(float) winSize.x / gameSize.x, cast(float) winSize.y / gameSize.y);

            finalSize = Vector2f(cast(int) (gameSize.x * scale), cast(int) (gameSize.y * scale));
            finalPos = Vector2f(winSize.x / 2 - finalSize.x / 2, winSize.y / 2 - finalSize.y / 2);
            break;

        case fill:
        case resize:
            finalPos = Vector2f(0);
            finalSize = Vector2f(winSize);
            break;
        }

        mFramebufferArea = Rect2f(finalPos, finalPos + finalSize);
    }

package(zyeware.core):
    Window mWindow;

    final void drawFramebuffer(in FrameTime nextFrameTime)
    {
        mWindow.update();

        // Prepare framebuffer and render application into it.
        RenderAPI.setViewport(0, 0, mFramebuffer.properties.size.x, mFramebuffer.properties.size.y);
        mFramebuffer.bind();
        draw(nextFrameTime);

        mFramebuffer.unbind();

        immutable bool oldWireframe = RenderAPI.getFlag(RenderFlag.wireframe);
        immutable bool oldCulling = RenderAPI.getFlag(RenderFlag.culling);

        // Prepare window space to render framebuffer into.
        RenderAPI.setFlag(RenderFlag.culling, false);
        RenderAPI.setFlag(RenderFlag.wireframe, false);

        RenderAPI.setViewport(0, 0, mWindow.size.x, mWindow.size.y);
        RenderAPI.clear();
        Renderer2D.begin(mWindowProjection, Matrix4f.identity);
        Renderer2D.drawRect(mFramebufferArea, Matrix4f.identity, Color.white, mFramebuffer.colorAttachment);
        Renderer2D.end();

        RenderAPI.setFlag(RenderFlag.culling, oldCulling);
        RenderAPI.setFlag(RenderFlag.wireframe, oldWireframe);

        mWindow.swapBuffers();
    }

    final void createFramebuffer()
    {
        FramebufferProperties fbProps;
        fbProps.size = mWindow.size;
        mFramebuffer = new Framebuffer(fbProps);

        mWindowProjection = Matrix4f.orthographic(0, mWindow.size.x, 0, mWindow.size.y, -1, 1);
        mFramebufferProjection = Matrix4f.orthographic(0, fbProps.size.x, fbProps.size.y, 0, -1, 1);

        recalculateFramebufferArea();
    }

public:
    /// How the framebuffer should be scaled on resizing.
    enum ScaleMode
    {
        center, /// Keep the original size at the center of the window.
        keepAspect, /// Scale with window, but keep the aspect.
        fill, /// Fill the window completly.
        resize /// Resize the framebuffer itself.
    }

    /// Override this method for application initialization.
    abstract void initialize();

    /// Override this method to perform logic on every frame.
    abstract void tick(in FrameTime frameTime);

    /// Override this method to perform rendering.
    abstract void draw(in FrameTime nextFrameTime);

    /// Override this method to return the window properties of the main window.
    abstract WindowProperties getWindowProperties();

    /// Destroys the application.
    void cleanup()
    {
        mWindow.destroy();
    }
    
    /// Handles the specified event in whatever manners seem appropriate.
    ///
    /// Params:
    ///     ev = The event to handle.
    void receive(in Event ev)
        in (ev, "Received event cannot be null.")
    {
        if (cast(QuitEvent) ev)
            ZyeWare.quit();
        else if (auto wev = cast(WindowResizedEvent) ev)
        {
            mWindowProjection = Matrix4f.orthographic(0, wev.size.x, 0, wev.size.y, -1, 1);
            recalculateFramebufferArea();

            if (mScaleMode == ScaleMode.resize)
            {
                FramebufferProperties fbProps = mFramebuffer.properties;
                fbProps.size = wev.size;
                mFramebuffer.properties = fbProps;

                mFramebuffer.invalidate();
            }
        }
    }

    /// The frame rate the application should target to hold. This is not a guarantee.
    uint targetFramerate() pure const nothrow
    {
        return 60;
    }

    /// The main window of the application.
    inout(Window) window() pure inout nothrow
    {
        return mWindow;
    }

    /// The arguments this application was started with.
    /// These are the same as the ones ZyeWare was started with, but stripped of
    /// engine-specific arguments.
    const(string[]) programArgs() pure const nothrow
    {
        return mProgramArgs;
    }

    Vector2ui framebufferSize() pure const nothrow
    {
        return mFramebuffer.properties.size;
    }

    void framebufferSize(Vector2ui newSize)
    {
        FramebufferProperties fbProps = mFramebuffer.properties;
        fbProps.size = newSize;
        mFramebuffer.properties = fbProps;
        mFramebuffer.invalidate();

        mFramebufferProjection = Matrix4f.orthographic(0, fbProps.size.x, fbProps.size.y, 0, -1, 1);
        recalculateFramebufferArea();
    }
}

/// A ZyeWare application that takes care of the game state logic.
/// Game states can be set, pushed and popped.
class GameStateApplication : Application
{
protected:
    GrowableStack!GameState mStateStack;

    this(string[] programArgs)
    {
        super(programArgs);
    }

public:
    override void receive(in Event ev)
        in (ev, "Received event cannot be null.")
    {
        super.receive(ev);

        if (hasState)
            currentState.receive(ev);
    }

    override void tick(in FrameTime frameTime)
    {
        if (hasState)
            currentState.tick(frameTime);
    }

    override void draw(in FrameTime nextFrameTime)
    {
        if (hasState)
            currentState.draw(nextFrameTime);
    }

    /// Change the current state to the given one.
    ///
    /// Params:
    ///     state = The game state to switch to.
    void changeState(GameState state)
        in (state, "Game state cannot be null.")
    {
        if (hasState)
            mStateStack.pop().onDetach();
        
        mStateStack.push(state);
        state.onAttach(!state.mWasAlreadyAttached);
        state.mWasAlreadyAttached = true;
        GC.collect();
    }

    /// Pushes the given state onto the stack, and switches to it.
    ///
    /// Params:
    ///     state = The state to push and switch to.
    void pushState(GameState state)
        in (state, "Game state cannot be null.")
    {
        if (hasState)
            currentState.onDetach();
        
        mStateStack.push(state);
        state.onAttach(!state.mWasAlreadyAttached);
        state.mWasAlreadyAttached = true;
        GC.collect();
    }

    /// Pops the current state from the stack, restoring the previous state.
    void popState()
    {
        if (hasState)
            mStateStack.pop().onDetach();
        
        currentState.onAttach(!currentState.mWasAlreadyAttached);
        currentState.mWasAlreadyAttached = true;
        GC.collect();
    }

    pragma(inline, true)
    GameState currentState()
    {
        return mStateStack.peek;
    }

    pragma(inline, true)
    bool hasState() const nothrow
    {
        return !mStateStack.empty;
    }
}
