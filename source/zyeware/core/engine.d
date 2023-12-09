// This file is part of the ZyeWare Game Engine, and subject to the terms
// and conditions defined in the file 'LICENSE.txt', which is part
// of this source code package.
//
// Copyright 2021 ZyeByte
module zyeware.core.engine;

import core.runtime : Runtime;
import core.time : MonoTime;
import core.thread : Thread;
import core.memory;

import std.exception : enforce, assumeWontThrow, collectException;
import std.string : format, fromStringz, toStringz;
import std.typecons : scoped;
import std.datetime : Duration, dur;
import std.algorithm : min;

import bindbc.loader;

import zyeware;
import zyeware.core.events;
import zyeware.core.application;
import zyeware.core.debugging;


import zyeware.core.crash;
import zyeware.utils.format;
import zyeware.core.introapp;
import zyeware.pal;

/// Struct that holds information about the project.
/// Note that the author name and project name are used to determine the save data directory.
struct ProjectProperties
{
    string authorName = "Anonymous"; /// The author of the game. Can be anything, from a person to a company.
    string projectName = "ZyeWare Project"; /// The name of the project.

    Application mainApplication; /// The application to use.
    CrashHandler crashHandler; /// The crash handler to use.
    DisplayProperties mainDisplayProperties; /// The properties of the main display.
    ScaleMode scaleMode = ScaleMode.center; /// How the main framebuffer should be scaled on resizing.

    uint audioBufferSize = 4096 * 4; /// The size of an individual audio buffer in samples.
    uint audioBufferCount = 4; /// The amount of audio buffers to cycle through for streaming.

    uint targetFrameRate = 60; /// The frame rate the project should target to hold. This is not a guarantee.
}

/// How the main framebuffer should be scaled on resizing.
enum ScaleMode
{
    center, /// Keep the original size at the center of the display.
    keepAspect, /// Scale with display, but keep the aspect.
    fill, /// Fill the display completely.
    changeDisplaySize /// Resize the framebuffer itself.
}

/// Holds information about passed time since the last frame.
struct FrameTime
{
    Duration deltaTime; /// Time between this frame and the last.
    Duration unscaledDeltaTime; /// Time between this frame and the last, without being multiplied by `ZyeWare.timeScale`.
}

/// Holds information about a SemVer version.
struct Version
{
    int major; /// The major release version.
    int minor; /// The minor release version.
    int patch; /// The patch version.
    string prerelease; /// Any additional version declarations, e.g. "alpha".

    string toString() immutable pure
    {
        return format!"%d.%d.%d%s"(major, minor, patch, prerelease ? "-" ~ prerelease : "");
    }
}

/// Holds the core engine. Responsible for the main loop and generic engine settings.
struct ZyeWare
{
    @disable this();
    @disable this(this);

private static:
    struct ParsedArgs
    {
        string applicationFile; /// The dynamic library of the application to load.

        LogLevel coreLogLevel = LogLevel.verbose; /// The log level for the core logger.
        LogLevel clientLogLevel = LogLevel.verbose; /// The log level for the client logger.
        LogLevel palLogLevel = LogLevel.verbose; /// The log level for the Pal logger.

        string graphicsDriver = "opengl"; /// The graphics driver to use.
        string audioDriver = "openal"; /// The audio driver to use.
        string displayDriver = "sdl"; /// The display driver to use.
    }

    alias DeferFunc = void delegate();

    SharedLib sApplicationLibrary;
    Display sMainDisplay;
    Application sApplication;

    Duration sWaitTime;
    MonoTime sStartupTime;
    FrameTime sFrameTime;
    RandomNumberGenerator sRandom;

    Framebuffer sMainFramebuffer;
    Rect2i sFramebufferArea;
    ScaleMode sScaleMode;
    bool sMustUpdateFramebufferDimensions;

    ProjectProperties sProjectProperties;

    DeferFunc[16] sDeferredFunctions;
    size_t sDeferredFunctionsCount;

    bool sRunning;
    float sTimeScale = 1f;

    debug
    {
        bool sIsProcessingDeferred;
        bool sIsEmittingEvent;
    }

    ProjectProperties loadApplication(string library)
    {
        void* handle = Runtime.loadLibrary(library);
        enforce!CoreException(handle, format!"Could not load application library '%s'."(library));
        
        sApplicationLibrary = SharedLib(handle);

        ProjectProperties function() getProjectProperties;
        sApplicationLibrary.bindSymbol(cast(void**) &getProjectProperties, "getProjectProperties");

        enforce!CoreException(getProjectProperties, "Could not find getProjectProperties function in application library.");

        return getProjectProperties();
    }

    void runMainLoop()
    {
        version (ZW_Profiling)
        {
            ushort fpsCounter;

            Timer fpsCounterTimer = new Timer(dur!"seconds"(1), (timer)
            {
                Profiler.sFPS = fpsCounter;
                fpsCounter = 0;
            }, No.oneshot, Yes.autostart);
        }

        MonoTime previous = MonoTime.currTime;
        Duration lag;

        while (sRunning)
        {
            version (ZW_Profiling)
            {
                Profiler.clearAndSwap();
                scope (exit) ++fpsCounter;
            }

            immutable MonoTime current = MonoTime.currTime;
            immutable Duration elapsed = current - previous;
            sFrameTime = FrameTime(dur!"hnsecs"(cast(long) (sWaitTime.total!"hnsecs" * sTimeScale)), sWaitTime);

            previous = current;
            lag += elapsed;

            while (lag >= sWaitTime)
            {
                Timer.tickEntries();
                sApplication.tick();
                
                lag -= sWaitTime;
            }

            InputManager.tick();

            if (sMustUpdateFramebufferDimensions)
            {
                if (sScaleMode == ScaleMode.changeDisplaySize)
                    framebufferSize = sMainDisplay.size;
                
                recalculateFramebufferArea();
            }

            drawFramebuffer();

            // Call all registered deferred functions at the end of the frame.
            {
                debug
                {
                    sIsProcessingDeferred = true;
                    scope (exit) sIsProcessingDeferred = false;
                }

                for (size_t i; i < sDeferredFunctionsCount; ++i)
                {
                    // After invoking set to null so that no references keep lingering.
                    sDeferredFunctions[i]();
                    sDeferredFunctions[i] = null;
                }
                sDeferredFunctionsCount = 0;
            }
        }

        version (ZW_Profiling) fpsCounterTimer.stop();
    }

    void createFramebuffer()
    {
        FramebufferProperties fbProps;
        fbProps.size = sMainDisplay.size;
        sMainFramebuffer = new Framebuffer(fbProps);

        recalculateFramebufferArea();
    }

    void recalculateFramebufferArea() nothrow
    {
        immutable Vector2i winSize = sMainDisplay.size;
        immutable Vector2i gameSize = sMainFramebuffer.properties.size;

        Vector2i finalPos, finalSize;

        final switch (sScaleMode) with (ScaleMode)
        {
        case center:
            finalPos = Vector2i(winSize.x / 2 - gameSize.x / 2, winSize.y / 2 - gameSize.y / 2);
            finalSize = Vector2i(gameSize);
            break;

        case keepAspect:
            immutable float scale = min(cast(float) winSize.x / gameSize.x, cast(float) winSize.y / gameSize.y);

            finalSize = Vector2i(cast(int) (gameSize.x * scale), cast(int) (gameSize.y * scale));
            finalPos = Vector2i(winSize.x / 2 - finalSize.x / 2, winSize.y / 2 - finalSize.y / 2);
            break;

        case fill:
        case changeDisplaySize:
            finalPos = Vector2i(0);
            finalSize = Vector2i(winSize);
            break;
        }

        sFramebufferArea = Rect2i(finalPos, finalPos + finalSize);
    }

    void drawFramebuffer()
    {
        sMainDisplay.update();

        // Prepare framebuffer and render application into it.
        Pal.graphics.api.setViewport(Rect2i(Vector2i.zero, sMainFramebuffer.properties.size));
        
        Pal.graphics.api.setRenderTarget(sMainFramebuffer.handle);
        sApplication.draw();
        Pal.graphics.api.setRenderTarget(null);

        Pal.graphics.api.clearScreen(Color.black);
        Pal.graphics.api.presentToScreen(sMainFramebuffer.handle, Rect2i(Vector2i.zero, sMainFramebuffer.properties.size),
            sFramebufferArea);

        sMainDisplay.swapBuffers();
    }

    ParsedArgs parseCmdArgs(string[] args)
    {
        import std.getopt : getopt, defaultGetoptPrinter, config;
        import std.stdio : writeln, writefln;
        import std.traits : EnumMembers;
        import core.stdc.stdlib : exit;

        ParsedArgs parsed;

        try
        {
            auto helpInfo = getopt(args,
                config.passThrough,
                "loglevel-core", "The minimum log level for engine logs to be displayed.", &parsed.coreLogLevel,
                "loglevel-client", "The minimum log level for game logs to be displayed.", &parsed.clientLogLevel,
                "loglevel-pal", "The minimum log level for Pal logs to be displayed.", &parsed.palLogLevel,
                "graphics-driver", "The graphics driver to use.", &parsed.graphicsDriver,
                "audio-driver", "The audio driver to use.", &parsed.audioDriver,
                "display-driver", "The display driver to use.", &parsed.displayDriver,
                "game", "The dynamic library of the game to load.", &parsed.applicationFile,
            );

            if (helpInfo.helpWanted)
            {
                defaultGetoptPrinter(format!"ZyeWare Game Engine v%s"(engineVersion), helpInfo.options);
                writeln("If no arguments are given, the selection of said options are to the disgression of the game developer.");
                writeln("All arguments not understood by the engine are passed through to the game.");
                writeln("------------------------------------------");
                writefln("Available log levels: %(%s, %)", [EnumMembers!LogLevel]);
                writefln("Available graphics drivers: %(%s, %)", Pal.registeredGraphicsDrivers());
                writefln("Available audio drivers: %(%s, %)", Pal.registeredAudioDrivers());
                writefln("Available display drivers: %(%s, %)", Pal.registeredDisplayDrivers());
                exit(0);
            }
        }
        catch (Exception ex)
        {
            writeln("Could not parse arguments: ", ex.message);
            writeln("Please use -h or --help to show information about the command line arguments.");
            exit(1);
        }

        return parsed;
    }

package(zyeware.core) static:
    CrashHandler crashHandler;

    void initialize(string[] args)
    {
        GC.disable();
        sStartupTime = MonoTime.currTime;
        sRandom = new RandomNumberGenerator();

        ParsedArgs parsedArgs = parseCmdArgs(args);

        // Initialize profiler and logger before anything else.
        version (ZW_Profiling) Profiler.initialize();
        Logger.initialize(parsedArgs.coreLogLevel, parsedArgs.clientLogLevel, parsedArgs.palLogLevel);

        Logger.core.log(LogLevel.info, "ZyeWare Game Engine v%s", engineVersion.toString());

        // Initialize crash handler afterwards because it relies on the logger.
        version (linux)
            crashHandler = new LinuxDefaultCrashHandler();
        else version (Windows)
            crashHandler = new WindowsDefaultCrashHandler();
        else
            crashHandler = new DefaultCrashHandler();

        Vfs.initialize();
        AssetManager.initialize();

        string applicationFile = parsedArgs.applicationFile;
        if (!applicationFile)
        {
            version (linux)
                applicationFile = "./libapp.so";
            else version (Windows)
                applicationFile = ".\\app.dll";
            else version (OSX)
                applicationFile = "./libapp.dylib";
            else
                throw new CoreException("Cannot determine default application file for this platform.");
        }

        ProjectProperties properties = loadApplication(applicationFile);

        if (properties.crashHandler)
            crashHandler = properties.crashHandler;

        sProjectProperties = properties;
        targetFrameRate = properties.targetFrameRate;
        sScaleMode = properties.scaleMode;
        
        enforce!CoreException(properties.mainApplication, "Main application cannot be null.");
        
        Pal.loadAudioDriver(parsedArgs.audioDriver);
        Pal.loadDisplayDriver(parsedArgs.displayDriver);
        Pal.loadGraphicsDriver(parsedArgs.graphicsDriver);
        
        // Creates a new display and render context.
        sMainDisplay = new Display(properties.mainDisplayProperties);
        enforce!CoreException(sMainDisplay, "Main display creation failed.");

        Pal.graphics.api.initialize();
        Pal.graphics.renderer2d.initialize();
        Pal.audio.initialize();

        AudioBus.create("master");

        // In release mode, we want to display our fancy splash screen.
        debug sApplication = properties.mainApplication;
        else sApplication = new IntroApplication(properties.mainApplication);

        createFramebuffer();
        sApplication.initialize();
    }

    void cleanup()
    {
        sMainDisplay.destroy();
        sMainFramebuffer.destroy();
        sApplication.cleanup();
        
        Pal.graphics.renderer2d.cleanup();
        Pal.graphics.api.cleanup();
        Pal.audio.cleanup();

        Vfs.cleanup();

        collect();

        sApplicationLibrary.unload();
    }

    void start()
    {
        if (sRunning)
            return;

        sRunning = true;
        runMainLoop();
    }

public static:
    /// The current version of the engine.
    immutable Version engineVersion = Version(0, 6, 0, "alpha");

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
    pragma(inline, true)
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

        if (auto wev = cast(DisplayResizedEvent) ev)
            sMustUpdateFramebufferDimensions = true;
        
        if (Exception ex = collectException(sApplication.receive(ev)))
            Logger.core.log(LogLevel.error, "Exception while emitting an event: %s", ex.message);

        if (auto input = cast(InputEvent) ev)
            InputManager.receive(input).assumeWontThrow;

        version (ZW_Profiling)
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

    /// Changes the display size, respecting various display states with it (e.g. full screen, minimised etc.)
    /// Params:
    ///   size = The new size of the display.
    void changeDisplaySize(Vector2i size)
        in (size.x > 0 && size.y > 0, "Application size cannot be negative.")
    {
        if (!sMainDisplay.isMaximized && !sMainDisplay.isMinimized)
            sMainDisplay.size = Vector2i(size);
        
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
        return MonoTime.currTime - sStartupTime;
    }

    /// The target framerate to hit. This is not a guarantee.
    void targetFrameRate(int fps) 
        in (fps > 0, "Target FPS must be greater than 0.")
    {
        sWaitTime = dur!"msecs"(cast(int) (1000f / cast(float) fps));
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

    FrameTime frameTime() nothrow
    {
        return sFrameTime;
    }

    RandomNumberGenerator random() nothrow
    {
        return sRandom;
    }

    /// The main display of the engine.
    Display mainDisplay() nothrow
    {
        return sMainDisplay;
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

        sMainFramebuffer.recreate(fbProps);
        recalculateFramebufferArea();
    }

    /// Converts the given display-relative position to the main framebuffer location.
    /// Use this method whenever you have to e.g. convert mouse pointer coordinates.
    /// 
    /// Params:
    ///     location = The display relative position.
    /// Returns: The converted framebuffer position.
    Vector2f convertDisplayToFramebufferLocation(Vector2i location) nothrow
    {
        float x = ((location.x - sFramebufferArea.position.x) / sFramebufferArea.size.x) * sMainFramebuffer.properties.size.x;
        float y = ((location.y - sFramebufferArea.position.y) / sFramebufferArea.size.y) * sMainFramebuffer.properties.size.y;

        return Vector2f(x, y);
    }

    /// Determines how the displayed framebuffer will be scaled according to the display size and shape.
    ScaleMode scaleMode() nothrow
    {
        return sScaleMode;
    }

    /// ditto
    void scaleMode(ScaleMode value) nothrow
    {
        sScaleMode = value;
    }

    /// The `ProjectProperties` the engine was started with.
    /// See_Also: ProjectProperties
    const(ProjectProperties) projectProperties() nothrow @nogc
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