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

import zyeware.common;
import zyeware.core.events;
import zyeware.core.application;
import zyeware.core.debugging;
import zyeware.rendering;
import zyeware.audio;
import zyeware.core.crash;
import zyeware.utils.format;

/// Struct that holds information about how to start up the engine.
struct ZyeWareProperties
{
    string[] cmdargs;
    Application application; /// The application to use.
    LogLevel coreLogLevel = LogLevel.trace; /// The log level for the core logger.
    LogLevel clientLogLevel = LogLevel.trace; /// The log level for the client logger.
    CrashHandler crashHandler; /// The crash handler to use.
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
    Application sApplication;
    Duration sFrameTime;
    Duration sUpTime;
    Timer sCleanupTimer;
    RandomNumberGenerator sRandom;
    bool sRunning;
    float sTimeScale = 1f;

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
            sApplication.drawFramebuffer(nextFrameTime);
        }

        version (Profiling) fpsCounterTimer.stop();
    }

package(zyeware.core) static:
    void initialize(ZyeWareProperties properties)
    {
        GC.disable();
        sRandom = new RandomNumberGenerator();

        sApplication = properties.application;
        sFrameTime = dur!"msecs"(1000 / sApplication.targetFramerate);

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
        sApplication.mWindow = new Window(sApplication.getWindowProperties());
        enforce!CoreException(sApplication.window, "Main window creation failed.");
        sApplication.createFramebuffer();

        // Initialize all other sub-systems.
        VFS.initialize();
        AssetManager.initialize();
        AudioAPI.initialize();
        RenderAPI.initialize();
        Renderer2D.initialize();
        Renderer3D.initialize();

        // Initialize application.
        sApplication.initialize();
    }

    void cleanup()
    {
        sCleanupTimer.stop();
        sApplication.cleanup();
        Renderer3D.cleanup();
        Renderer2D.cleanup();
        RenderAPI.cleanup();
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
    /// The crash handler that is used when the engine crashes.
    CrashHandler crashHandler;

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

    /// The current application.
    Application application() nothrow
    {
        return sApplication;
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
}