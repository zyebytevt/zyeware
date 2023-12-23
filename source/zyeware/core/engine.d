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
import zyeware.core.crash;
import zyeware.pal;

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
        string[] packages; /// The packages to load.

        LogLevel coreLogLevel = LogLevel.verbose; /// The log level for the core logger.
        LogLevel clientLogLevel = LogLevel.verbose; /// The log level for the client logger.

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
    recti sFramebufferArea;
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

    Application createClientApplication()
    {
        import std.system : os;

        string* path = os in sProjectProperties.appLibraries;
        enforce!CoreException(path, "No application library declared for this platform.");

        sApplicationLibrary = loadDynamicLibrary(*path);

        Application function() createApplication;
        sApplicationLibrary.bindSymbol(cast(void**) &createApplication, "createApplication");

        enforce!CoreException(createApplication, "Could not find 'createApplication' function in application library.");

        return createApplication();
    }

    void runMainLoop()
    {
        MonoTime previous = MonoTime.currTime;

        while (sRunning)
        {
            immutable MonoTime current = MonoTime.currTime;
            immutable Duration elapsed = current - previous;
            
            sFrameTime = FrameTime(dur!"hnsecs"(cast(long) (elapsed.total!"hnsecs" * sTimeScale)), elapsed);
            previous = current;

            sApplication.tick();
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

            // Wait until the target frame rate is reached.
            immutable Duration timeToWait = sWaitTime - (MonoTime.currTime - current);
            if (timeToWait > Duration.zero)
                Thread.sleep(timeToWait);
        }
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
        immutable vec2i winSize = sMainDisplay.size;
        immutable vec2i gameSize = sMainFramebuffer.properties.size;

        vec2i finalPos, finalSize;

        final switch (sScaleMode) with (ScaleMode)
        {
        case center:
            finalPos = vec2i(winSize.x / 2 - gameSize.x / 2, winSize.y / 2 - gameSize.y / 2);
            finalSize = vec2i(gameSize);
            break;

        case keepAspect:
            immutable float scale = min(cast(float) winSize.x / gameSize.x, cast(float) winSize.y / gameSize.y);

            finalSize = vec2i(cast(int) (gameSize.x * scale), cast(int) (gameSize.y * scale));
            finalPos = vec2i(winSize.x / 2 - finalSize.x / 2, winSize.y / 2 - finalSize.y / 2);
            break;

        case fill:
        case changeDisplaySize:
            finalPos = vec2i(0);
            finalSize = vec2i(winSize);
            break;
        }

        sFramebufferArea = recti(finalPos.x, finalPos.y, finalPos.x + finalSize.x, finalPos.y + finalSize.y);
    }

    void drawFramebuffer()
    {
        sMainDisplay.update();

        // Prepare framebuffer and render application into it.
        Pal.graphics.api.setViewport(recti(0, 0, sMainFramebuffer.properties.size.x, sMainFramebuffer.properties.size.y));
        
        Pal.graphics.api.setRenderTarget(sMainFramebuffer.handle);
        sApplication.draw();
        Pal.graphics.api.setRenderTarget(null);

        Pal.graphics.api.clearScreen(color.black);
        Pal.graphics.api.presentToScreen(sMainFramebuffer.handle, recti(0, 0, sMainFramebuffer.properties.size.x, sMainFramebuffer.properties.size.y),
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
                "game", "The packages to load.", &parsed.packages,
                "loglevel-core", "The minimum log level for engine logs to be displayed.", &parsed.coreLogLevel,
                "loglevel-client", "The minimum log level for game logs to be displayed.", &parsed.clientLogLevel,
                "graphics-driver", "The graphics driver to use.", &parsed.graphicsDriver,
                "audio-driver", "The audio driver to use.", &parsed.audioDriver,
                "display-driver", "The display driver to use.", &parsed.displayDriver,
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
        sStartupTime = MonoTime.currTime;

        GC.disable();
        ParsedArgs parsedArgs = parseCmdArgs(args);

        // Initialize profiler and logger before anything else.
        import zyeware.core.logging.core : initCoreLogger;
        import zyeware.core.logging.client : initClientLogger;

        initCoreLogger(parsedArgs.coreLogLevel);
        initClientLogger(parsedArgs.clientLogLevel);

        info("ZyeWare Game Engine v%s", engineVersion.toString());

        // Initialize crash handler afterwards because it relies on the logger.
        version (linux)
            crashHandler = new LinuxDefaultCrashHandler();
        else version (Windows)
            crashHandler = new WindowsDefaultCrashHandler();
        else
            crashHandler = new DefaultCrashHandler();

        Vfs.initialize();
        AssetManager.initialize();

        Vfs.addPackage("main.zpk");
        foreach (string pckPath; parsedArgs.packages)
            Vfs.addPackage(pckPath);

        sProjectProperties = ProjectProperties.load("res:zyeware.conf");
        sApplication = createClientApplication();
        enforce!CoreException(sApplication, "Main application cannot be null.");
        
        Pal.loadAudioDriver(parsedArgs.audioDriver);
        Pal.loadDisplayDriver(parsedArgs.displayDriver);
        Pal.loadGraphicsDriver(parsedArgs.graphicsDriver);
        
        // Creates a new display and render context.
        sRandom = new RandomNumberGenerator();
        targetFrameRate = sProjectProperties.targetFrameRate;
        sScaleMode = sProjectProperties.scaleMode;
        sMainDisplay = new Display(sProjectProperties.mainDisplayProperties);

        enforce!CoreException(sMainDisplay, "Main display creation failed.");

        Pal.graphics.api.initialize();
        Pal.graphics.renderer2d.initialize();
        Pal.audio.initialize();

        AudioBus.create("master");

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
            error("Exception while emitting an event: %s", ex.message);

        if (auto input = cast(InputEvent) ev)
            InputManager.receive(input).assumeWontThrow;
    }

    /// Starts a garbage collection cycle, and clears the cache of dead references.
    void collect() nothrow
    {
        immutable size_t memoryBeforeCollection = GC.stats().usedSize;

        debug_("Running garbage collector...");
        GC.collect();
        AssetManager.cleanCache();
        GC.minimize();

        debug_("Finished garbage collection, freed %s.",
            bytesToString(memoryBeforeCollection - GC.stats().usedSize));
    }

    /// Changes the display size, respecting various display states with it (e.g. full screen, minimised etc.)
    /// Params:
    ///   size = The new size of the display.
    void changeDisplaySize(vec2i size)
        in (size.x > 0 && size.y > 0, "Application size cannot be negative.")
    {
        if (!sMainDisplay.isMaximized && !sMainDisplay.isMinimized)
            sMainDisplay.size = vec2i(size);
        
        framebufferSize = vec2i(size);
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
    vec2i framebufferSize() nothrow
    {
        return sMainFramebuffer.properties.size;
    }

    /// ditto
    void framebufferSize(vec2i newSize)
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
    vec2 convertDisplayToFramebufferLocation(vec2i location) nothrow
    {
        float x = ((location.x - sFramebufferArea.x) / sFramebufferArea.width) * sMainFramebuffer.properties.size.x;
        float y = ((location.y - sFramebufferArea.y) / sFramebufferArea.height) * sMainFramebuffer.properties.size.y;

        return vec2(x, y);
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