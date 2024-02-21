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
import std.typecons : scoped, Rebindable;
import std.datetime : Duration, dur;
import std.algorithm : min;

import zyeware;
import zyeware.core.project;
import zyeware.pal;
import zyeware.core.main;
import zyeware.core.cmdargs;

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

alias stringz = const(char)*;

/// Holds the core engine. Responsible for the main loop and generic engine settings.
struct ZyeWare
{
    @disable this();
    @disable this(this);

private static:
    alias DeferCallable = void delegate();

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

    Rebindable!(const ProjectProperties) sProjectProperties;

    DeferCallable[] sDeferredFunctions;

    bool sRunning;
    float sTimeScale = 1f;
    bool sIsProcessingDeferred;
    
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

                for (size_t i; i < sDeferredFunctions.length; ++i)
                {
                    // After invoking set to null so that no references keep lingering.
                    sDeferredFunctions[i]();
                    sDeferredFunctions[i] = null;
                }
                sDeferredFunctions.length = 0;
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

        Pal.graphics.api.clearScreen(color(0, 0, 0));
        Pal.graphics.api.presentToScreen(sMainFramebuffer.handle, recti(0, 0, sMainFramebuffer.properties.size.x, sMainFramebuffer.properties.size.y),
            sFramebufferArea);

        sMainDisplay.swapBuffers();
    }

package(zyeware.core) static:
    void initialize(string[] args, in ProjectProperties projectProperties)
    {
        sStartupTime = MonoTime.currTime;

        GC.disable();
        auto parsedArgs = CommandLineArguments.parse(args);

        // Initialize profiler and logger before anything else.
        auto sink = new ColorLogSink();

        Logger.initialize(
            new Logger(sink, parsedArgs.coreLogLevel, "Core"),
            new Logger(sink, parsedArgs.clientLogLevel, "Client")
        );

        Logger.core.info("ZyeWare Game Engine v%s", engineVersion.toString());

        Files.initialize();
        AssetManager.initialize();
        InputMap.initialize();

        Files.addPackage("main.zpk");
        foreach (string pckPath; parsedArgs.packages)
            Files.addPackage(pckPath);

        sProjectProperties = projectProperties;
        sApplication = cast(Application) Object.factory(sProjectProperties.mainApplication);
        enforce!CoreException(sApplication, "Failed to create main application.");
        
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

        InputMap.cleanup();
        Files.cleanup();

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
    /// The current version of the engine.
    immutable Version engineVersion = Version(0, 6, 0, "alpha");

    /// Stops the main loop and quits the engine.
    void quit() nothrow
    {
        sRunning = false;
    }

    /// Starts a garbage collection cycle, and clears the cache of dead references.
    void collect() nothrow
    {
        immutable size_t memoryBeforeCollection = GC.stats().usedSize;

        Logger.core.debug_("Running garbage collector...");
        GC.collect();
        AssetManager.cleanCache();
        GC.minimize();

        Logger.core.debug_("Finished garbage collection, freed %s.",
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
    void callDeferred(DeferCallable func)
    {
        enforce!CoreException(!sIsProcessingDeferred, "Cannot defer calls while processing deferred calls!");

        sDeferredFunctions ~= func;
    }

    /// The current application.
    Application application() nothrow => sApplication;

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
    }
}