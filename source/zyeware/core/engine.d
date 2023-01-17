// This file is part of the ZyeWare Game Engine, and subject to the terms
// and conditions defined in the file 'LICENSE.txt', which is part
// of this source code package.
//
// Copyright 2021 ZyeByte
module zyeware.core.engine;

import core.time : MonoTime;
import core.thread : Thread;
import core.memory;

import std.exception : enforce, assumeWontThrow, collectException;
import std.string : format, fromStringz, toStringz;
import std.typecons : scoped;
import std.datetime : Duration, dur;
import std.algorithm : min;

import zyeware.common;
import zyeware.core.events;
import zyeware.core.application;
import zyeware.core.debugging;
import zyeware.rendering;
import zyeware.audio;
import zyeware.audio.thread;
import zyeware.core.crash;
import zyeware.utils.format;
import zyeware.core.startupapp;

/// Struct that holds information about the project.
struct ProjectProperties
{
    string authorName = "Anonymous";
    string projectName = "ZyeWare Project";

    LogLevel coreLogLevel = LogLevel.trace; /// The log level for the core logger.
    LogLevel clientLogLevel = LogLevel.trace; /// The log level for the client logger.

    Application mainApplication; /// The application to use.
    CrashHandler crashHandler; /// The crash handler to use.
    WindowProperties mainWindowProperties; /// The properties of the main window.

    uint audioBufferSize = 4096 * 4; /// The size of an individual audio buffer in samples.
    uint audioBufferCount = 4; /// The amount of audio buffers to cycle through for streaming.

    uint targetFrameRate = 60; /// The frame rate the project should target to hold. This is not a guarantee.
}

/// Holds information about passed time since the last frame.
struct FrameTime
{
    Duration deltaTime; /// Time between this frame and the last.
    Duration unscaledDeltaTime; /// Time between this frame and the last, without being multiplied by `ZyeWare.timeScale`.
}

/// Holds the core engine. Responsible for the main loop and generic engine settings.
struct ZyeWare
{
    @disable this();
    @disable this(this);

private static:
    alias DeferFunc = void delegate();

    Window sMainWindow;
    Application sApplication;

    Duration sFrameTime;
    Duration sUpTime;
    Timer sCleanupTimer;
    RandomNumberGenerator sRandom;

    Framebuffer sMainFramebuffer;
    Matrix4f sFramebufferProjection;
    Matrix4f sWindowProjection;
    Rect2f sFramebufferArea;
    ScaleMode sScaleMode;

    ProjectProperties sProjectProperties;
    string[] sCmdArgs;

    DeferFunc[16] sDeferredFunctions;
    size_t sDeferredFunctionsCount;

    bool sRunning;
    float sTimeScale = 1f;

    debug
    {
        bool sIsProcessingDeferred;
        bool sIsEmittingEvent;
    }

    void runMainLoop()
    {
        version (Profiling)
        {
            ushort fpsCounter;

            Timer fpsCounterTimer = new Timer(dur!"seconds"(1), (timer)
            {
                Profiler.sFPS = fpsCounter;
                fpsCounter = 0;
            }, No.oneshot, Yes.autostart);
        }

        sUpTime = Duration.zero;
        
        import std.datetime : msecs;
        MonoTime previous = MonoTime.currTime;
        Duration lag;

        while (sRunning)
        {
            version (Profiling)
            {
                Profiler.clear();
                scope (exit) ++fpsCounter;
            }

            immutable MonoTime current = MonoTime.currTime;
            immutable Duration elapsed = current - previous;
            immutable frameTime = FrameTime(dur!"hnsecs"(cast(long) (sFrameTime.total!"hnsecs" * sTimeScale)), sFrameTime);

            previous = current;
            lag += elapsed;

            while (lag >= sFrameTime)
            {
                Timer.tickEntries(frameTime);
                sApplication.tick(frameTime);
                
                lag -= sFrameTime;
                sUpTime += sFrameTime;
            }

            InputManager.tick();

            immutable nextFrameTime = FrameTime(dur!"hnsecs"(cast(long) (lag.total!"hnsecs" * sTimeScale)), lag);
            drawFramebuffer(nextFrameTime);

            // Call all registered deferred functions at the end of the frame.
            {
                debug
                {
                    sIsProcessingDeferred = true;
                    scope (exit) sIsProcessingDeferred = false;
                }

                for (size_t i; i < sDeferredFunctionsCount; ++i)
                    sDeferredFunctions[i]();
                sDeferredFunctionsCount = 0;
            }
        }

        version (Profiling) fpsCounterTimer.stop();
    }

    void createFramebuffer()
    {
        FramebufferProperties fbProps;
        fbProps.size = sMainWindow.size;
        sMainFramebuffer = new Framebuffer(fbProps);

        sWindowProjection = Matrix4f.orthographic(0, sMainWindow.size.x, 0, sMainWindow.size.y, -1, 1);
        sFramebufferProjection = Matrix4f.orthographic(0, fbProps.size.x, fbProps.size.y, 0, -1, 1);

        recalculateFramebufferArea();
    }

    void recalculateFramebufferArea() nothrow
    {
        immutable Vector2i winSize = sMainWindow.size;
        immutable Vector2i gameSize = sMainFramebuffer.properties.size;

        Vector2f finalPos, finalSize;

        final switch (sScaleMode) with (ScaleMode)
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
        case changeWindowSize:
            finalPos = Vector2f(0);
            finalSize = Vector2f(winSize);
            break;
        }

        sFramebufferArea = Rect2f(finalPos, finalPos + finalSize);
    }

    void drawFramebuffer(in FrameTime nextFrameTime)
    {
        sMainWindow.update();

        // Prepare framebuffer and render application into it.
        RenderAPI.setViewport(0, 0, sMainFramebuffer.properties.size.x, sMainFramebuffer.properties.size.y);
        sMainFramebuffer.bind();
        sApplication.draw(nextFrameTime);

        sMainFramebuffer.unbind();

        immutable bool oldWireframe = RenderAPI.getFlag(RenderFlag.wireframe);
        immutable bool oldCulling = RenderAPI.getFlag(RenderFlag.culling);

        // Prepare window space to render framebuffer into.
        RenderAPI.setFlag(RenderFlag.culling, false);
        RenderAPI.setFlag(RenderFlag.wireframe, false);

        RenderAPI.setViewport(0, 0, sMainWindow.size.x, sMainWindow.size.y);
        RenderAPI.clear();
        Renderer2D.begin(sWindowProjection, Matrix4f.identity);
        Renderer2D.drawRect(sFramebufferArea, Matrix4f.identity, Color.white, sMainFramebuffer.colorAttachment);
        Renderer2D.end();

        RenderAPI.setFlag(RenderFlag.culling, oldCulling);
        RenderAPI.setFlag(RenderFlag.wireframe, oldWireframe);

        sMainWindow.swapBuffers();
    }

package(zyeware.core) static:
    CrashHandler crashHandler;

    void initialize(string[] args, ProjectProperties properties)
    {
        GC.disable();

        sCmdArgs = args;
        sProjectProperties = properties;

        sFrameTime = dur!"msecs"(1000 / properties.targetFrameRate);
        sRandom = new RandomNumberGenerator();

        if (properties.crashHandler)
            crashHandler = properties.crashHandler;
        else
        {
            version (linux)
                crashHandler = new LinuxDefaultCrashHandler();
            else
                crashHandler = new DefaultCrashHandler();
        }

        // Initialize profiler and logger before anything else.
        version (Profiling) Profiler.initialize();
        Logger.initialize(properties.coreLogLevel, properties.clientLogLevel);
        
        // Creates a new window and render context.
        sMainWindow = new Window(properties.mainWindowProperties);
        enforce!CoreException(sMainWindow, "Main window creation failed.");
        createFramebuffer();

        // Initialize all other sub-systems.
        VFS.initialize();
        AssetManager.initialize();
        AudioAPI.initialize();
        AudioThread.initialize();
        RenderAPI.initialize();
        Renderer2D.initialize();
        Renderer3D.initialize();

        // In release mode, we want to display our fancy splash screen.
        debug sApplication = properties.mainApplication;
        else sApplication = new StartupApplication(properties.mainApplication);

        sApplication.initialize();
    }

    void cleanup()
    {
        sCleanupTimer.stop();
        sMainWindow.destroy();
        sApplication.cleanup();
        Renderer3D.cleanup();
        Renderer2D.cleanup();
        RenderAPI.cleanup();
        AudioThread.cleanup();
        AudioAPI.cleanup();

        VFS.cleanup();

        collect();
    }

    void start()
    {
        if (sRunning)
            return;

        sRunning = true;
        runMainLoop();
    }

public static:
    /// How the framebuffer should be scaled on resizing.
    enum ScaleMode
    {
        center, /// Keep the original size at the center of the window.
        keepAspect, /// Scale with window, but keep the aspect.
        fill, /// Fill the window completly.
        changeWindowSize /// Resize the framebuffer itself.
    }

    /// Stops the main loop and quits the engine.
    void quit() nothrow
    {
        sRunning = false;
    }

    /// Emits an event to the event bus.
    ///
    /// Params:
    ///     E = The event type to send.
    ///     args = The arguments of the event.
    void emit(E : Event, Args...)(Args args) nothrow
    {
        emit(scoped!E(args).assumeWontThrow);
    }

    /// Emits an event to the event bus.
    ///
    /// Params:
    ///     ev = The event to send.
    void emit(in Event ev) nothrow
        in (ev, "Event to emit cannot be null.")
    {
        debug
        {
            sIsEmittingEvent = true;
            scope (exit) sIsEmittingEvent = false;
        }

        if (auto wev = cast(WindowResizedEvent) ev)
        {
            sWindowProjection = Matrix4f.orthographic(0, wev.size.x, 0, wev.size.y, -1, 1);
            recalculateFramebufferArea();

            // TODO: Move this to pre-frame with flag.
            if (sScaleMode == ScaleMode.changeWindowSize)
            {
                FramebufferProperties fbProps = sMainFramebuffer.properties;
                fbProps.size = wev.size;
                sMainFramebuffer.properties = fbProps;

                import std.exception : assumeWontThrow;
                sMainFramebuffer.invalidate().assumeWontThrow;
            }
        }
        
        if (Exception ex = collectException(sApplication.receive(ev)))
            Logger.core.log(LogLevel.error, "Exception while emitting an event: %s", ex.msg);

        if (auto input = cast(InputEvent) ev)
            InputManager.receive(input).assumeWontThrow;

        version (Profiling)
        {
            if (auto key = cast(InputEventKey) ev)
                DebugInfoManager.receive(key);
        }
    }

    /// Starts a garbage collection cycle, and clears the cache of dead references.
    void collect() nothrow
    {
        immutable size_t memoryBeforeCollection = GC.stats().usedSize;

        Logger.core.log(LogLevel.debug_, "Running garbage collector...");
        GC.collect();
        AssetManager.cleanCache();
        GC.minimize();

        Logger.core.log(LogLevel.debug_, "Finished garbage collection, freed %s.",
            bytesToString(memoryBeforeCollection - GC.stats().usedSize));
    }

    // TODO: Change name?
    void changeWindowSize(Vector2i size)
        in (size.x > 0 && size.y > 0, "Application size cannot be negative.")
    {
        if (!sMainWindow.isMaximized && !sMainWindow.isMinimized)
            sMainWindow.size = Vector2i(size);
        
        framebufferSize = Vector2i(size);
    }

    /// Registers a callback to be called at the very end of a frame.
    ///
    /// Params:
    ///     func = The deferred callback.
    void callDeferred(DeferFunc func)
    {
        debug enforce!CoreException(!sIsProcessingDeferred, "Cannot defer calls while processing deferred calls!");
        enforce!CoreException(sDeferredFunctionsCount < sDeferredFunctions.length,
            format!"Cannot have more than %d deferred functions!"(sDeferredFunctions.length));

        sDeferredFunctions[sDeferredFunctionsCount++] = func;
    }

    /// The current application.
    Application application() nothrow
    {
        return sApplication;
    }

    /// Sets the current application. It will only be set active after the current frame.
    void application(Application value)
    {
        callDeferred(() {
            if (sApplication)
                sApplication.cleanup();

            sApplication = value;
            sApplication.initialize();

            recalculateFramebufferArea();
        });
    }

    /// The duration the engine is already running.
    Duration upTime() nothrow
    {
        return sUpTime;
    }

    void targetFrameRate(int fps) 
        in (fps > 0, "Target FPS must be greater than 0.")
    {
        sFrameTime = dur!"msecs"(cast(int) (1000f / cast(float) fps));
    }

    /// The current time scale. This controls the speed of the game, assuming
    /// all `tick` methods use the `deltaTime` member of the given `FrameTime`.
    ///
    /// See_Also: FrameTime
    float timeScale() nothrow
    {
        return sTimeScale;
    }

    /// ditto
    void timeScale(float value) nothrow
        in (value != float.nan, "Timescale value was nan.")
    {
        sTimeScale = value;
    }

    RandomNumberGenerator random() nothrow
    {
        return sRandom;
    }

    /// The main window of the engine.
    Window mainWindow() nothrow
    {
        return sMainWindow;
    }

    /// The size of the main framebuffer.
    Vector2i framebufferSize() nothrow
    {
        return sMainFramebuffer.properties.size;
    }

    /// ditto
    void framebufferSize(Vector2i newSize)
        in (newSize.x > 0 && newSize.y > 0, "Framebuffer size cannot be negative.")
    {
        FramebufferProperties fbProps = sMainFramebuffer.properties;
        fbProps.size = newSize;
        sMainFramebuffer.properties = fbProps;
        sMainFramebuffer.invalidate();

        sFramebufferProjection = Matrix4f.orthographic(0, fbProps.size.x, fbProps.size.y, 0, -1, 1);
        recalculateFramebufferArea();
    }

    /// Converts the given window-relative position to the main framebuffer location.
    /// Use this method whenever you have to e.g. convert mouse pointer coordinates.
    /// 
    /// Params:
    ///     location = The window relative position.
    /// Returns: The converted framebuffer position.
    Vector2f convertWindowToFramebufferLocation(Vector2f location) nothrow
    {
        float fbActualWidth = sFramebufferArea.max.x - sFramebufferArea.min.x;
        float fbActualHeight = sFramebufferArea.max.y - sFramebufferArea.min.y;

        float x = ((location.x - sFramebufferArea.min.x) / fbActualWidth) * sMainFramebuffer.properties.size.x;
        float y = ((location.y - sFramebufferArea.min.y) / fbActualHeight) * sMainFramebuffer.properties.size.y;

        return Vector2f(x, y);
    }

    /// Determines how the displayed framebuffer will be scaled according to the window size and shape.
    ScaleMode scaleMode() nothrow
    {
        return sScaleMode;
    }

    /// ditto
    void scaleMode(ScaleMode value) nothrow
    {
        sScaleMode = value;
    }

    /// The arguments this application was started with.
    /// These are the same as the ones ZyeWare was started with, but stripped of
    /// engine-specific arguments.
    string[] cmdArgs() nothrow
    {
        return sCmdArgs;
    }

    /// The `ProjectProperties` the engine was started with.
    /// See_Also: ProjectProperties
    const(ProjectProperties) projectProperties() nothrow
    {
        return sProjectProperties;
    }

    debug
    {
        /// If the engine is currently processing deferred calls.
        /// **This method is only available in debug builds!**
        bool isProcessingDeferred() nothrow
        {
            return sIsProcessingDeferred;
        }

        /// If the engine is currently emitting any event.
        /// **This method is only available in debug builds!**
        bool isEmittingEvent() nothrow
        {
            return sIsEmittingEvent;
        }
    }
}