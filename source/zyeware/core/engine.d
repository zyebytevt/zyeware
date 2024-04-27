// This file is part of the ZyeWare Game Engine, and subject to the terms
// and conditions defined in the file 'LICENSE.txt', which is part
// of this source code package.
//
// Copyright © 2021-2024 ZyeByte. All rights reserved.
module zyeware.core.engine;

import core.runtime : Runtime;
import core.time : MonoTime;
import core.thread : Thread;
import core.memory;

import std.exception : enforce, assumeWontThrow, collectException;
import std.string : format, fromStringz, toStringz;
import std.typecons : scoped, Rebindable;
import std.algorithm : min, remove;

import zyeware;
import zyeware.subsystems;
import zyeware.core.project;
import zyeware.core.cmdargs;

/// Represents a C-style string.
alias stringz = const(char)*;
/// A more readable alias for a native handle (a `void*`).
alias NativeHandle = void*;

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

    double deltaTimeSeconds; /// Time between this frame and the last, in seconds.
    double unscaledDeltaTimeSeconds; /// Time between this frame and the last, in seconds, without being multiplied by `ZyeWare.timeScale`.
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

struct Events
{
    @disable this(this);

public:
    Signal!() quitRequested;
    Signal!(const Window, vec2i) windowResized;
    Signal!(const Window, vec2i) windowMoved;
    Signal!(KeyCode) keyboardKeyPressed;
    Signal!(KeyCode) keyboardKeyReleased;
    Signal!(MouseCode, size_t) mouseButtonPressed;
    Signal!(MouseCode) mouseButtonReleased;
    Signal!(vec2) mouseWheelScrolled;
    Signal!(vec2, vec2) mouseMoved;
    Signal!(GamepadIndex) gamepadConnected;
    Signal!(GamepadIndex) gamepadDisconnected;
    Signal!(GamepadIndex, GamepadButton) gamepadButtonPressed;
    Signal!(GamepadIndex, GamepadButton) gamepadButtonReleased;
    Signal!(GamepadIndex, GamepadAxis, float) gamepadAxisMoved;
}

/// This interface describes an instance that holds a handle (a `void*`) to a native object.
/// This is used to allow the native object to be passed around without having to worry about
/// the actual type of the native object.
interface NativeObject
{
    const(NativeHandle) handle() pure const nothrow;
}

/// Holds the core engine. Responsible for the main loop and generic engine settings.
struct ZyeWare
{
    @disable this();
    @disable this(this);

private static:
    struct TimeoutEntry
    {
        Duration duration;
        Duration expiresAt;
        void delegate() callback;
        bool repeating;
    }

    Window sMainWindow;
    Application sApplication;

    Duration sWaitTime;
    MonoTime sStartupTime;
    RandomNumberGenerator sRandom;

    Framebuffer sMainFramebuffer;
    recti sFramebufferArea;
    ScaleMode sScaleMode;
    bool sMustUpdateFramebufferDimensions;

    Rebindable!(const ProjectProperties) sProjectProperties;

    TimeoutEntry[32] sTimeouts;

    bool sRunning;
    float sTimeScale = 1f;

    void runMainLoop()
    {
        MonoTime previous = MonoTime.currTime;

        while (sRunning)
        {
            immutable MonoTime current = MonoTime.currTime;
            immutable Duration elapsed = current - previous;

            immutable Duration elapsedScaled = dur!"hnsecs"(cast(long)(elapsed.total!"hnsecs" * sTimeScale));

            immutable FrameTime frameTime = FrameTime(
                elapsedScaled,
                elapsed,
                elapsedScaled.toDoubleSeconds,
                elapsed.toDoubleSeconds
            );
            
            previous = current;

            sApplication.tick(frameTime);
            InputMap.tick();

            if (sMustUpdateFramebufferDimensions)
            {
                if (sScaleMode == ScaleMode.changeDisplaySize)
                    framebufferSize = sMainWindow.size;

                recalculateFramebufferArea();
            }

            drawFramebuffer();

            // Check timeouts.
            for (size_t i; i < sTimeouts.length; ++i)
            {
                auto entry = &sTimeouts[i];

                if (entry.callback && entry.expiresAt <= upTime)
                {
                    entry.callback();

                    if (entry.repeating)
                        entry.expiresAt = upTime + entry.duration;
                    else
                        entry.callback = null;
                }
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
        fbProps.size = sMainWindow.size;
        sMainFramebuffer = new Framebuffer(fbProps);

        recalculateFramebufferArea();
    }

    void recalculateFramebufferArea() nothrow
    {
        immutable vec2i winSize = sMainWindow.size;
        immutable vec2i gameSize = sMainFramebuffer.properties.size;

        vec2i finalPos, finalSize;

        final switch (sScaleMode) with (ScaleMode)
        {
        case center:
            finalPos = vec2i(winSize.x / 2 - gameSize.x / 2, winSize.y / 2 - gameSize.y / 2);
            finalSize = vec2i(gameSize);
            break;

        case keepAspect:
            immutable float scale = min(cast(float) winSize.x / gameSize.x,
                cast(float) winSize.y / gameSize.y);

            finalSize = vec2i(cast(int)(gameSize.x * scale), cast(int)(gameSize.y * scale));
            finalPos = vec2i(winSize.x / 2 - finalSize.x / 2, winSize.y / 2 - finalSize.y / 2);
            break;

        case fill:
        case changeDisplaySize:
            finalPos = vec2i(0);
            finalSize = vec2i(winSize);
            break;
        }

        sFramebufferArea = recti(finalPos.x, finalPos.y,
            finalPos.x + finalSize.x, finalPos.y + finalSize.y);
    }

    void drawFramebuffer()
    {
        sMainWindow.update();

        // Prepare framebuffer and render application into it.
        GraphicsSubsystem.callbacks.setViewport(recti(0, 0,
                sMainFramebuffer.properties.size.x, sMainFramebuffer.properties.size.y));

        GraphicsSubsystem.callbacks.setRenderTarget(sMainFramebuffer.handle);
        sApplication.draw();
        GraphicsSubsystem.callbacks.setRenderTarget(null);

        GraphicsSubsystem.callbacks.clearScreen(color(0, 0, 0));
        GraphicsSubsystem.callbacks.presentToScreen(sMainFramebuffer.handle, recti(0, 0,
                sMainFramebuffer.properties.size.x, sMainFramebuffer.properties.size.y),
            sFramebufferArea);

        sMainWindow.swapBuffers();
    }

package(zyeware.core) static:
    void load(string[] args, in ProjectProperties projectProperties)
    {
        sStartupTime = MonoTime.currTime;

        GC.disable();
        auto parsedArgs = CommandLineArguments.parse(args);

        // Initialize profiler and logger before anything else.
        auto sink = new ColorLogSink();

        Logger.load(new Logger(sink, parsedArgs.coreLogLevel, "Core"),
            new Logger(sink, parsedArgs.clientLogLevel, "Client"));

        Logger.core.info("ZyeWare Game Engine v%s", engineVersion.toString());

        // Register available graphics backends
        GraphicsSubsystem.registerLoader("opengl", &(imported!"zyeware.platform.opengl.loader".loadOpenGl));

        // Init VFS
        Files.load();
        Files.addPackage("main.zpk");
        foreach (string pckPath; parsedArgs.packages)
            Files.addPackage(pckPath);

        AssetManager.load();
        InputMap.load();
        SdlSubsystem.load();
        AudioSubsystem.load();

        sProjectProperties = projectProperties;
        sApplication = cast(Application) Object.factory(sProjectProperties.mainApplication);
        enforce!CoreException(sApplication, "Failed to create main application.");

        // Creates a new display and render context.
        sRandom = new RandomNumberGenerator();
        targetFrameRate = sProjectProperties.targetFrameRate;
        sScaleMode = sProjectProperties.scaleMode;
        sMainWindow = new Window(sProjectProperties.mainWindowProperties);

        enforce!CoreException(sMainWindow, "Main display creation failed.");

        GraphicsSubsystem.load(parsedArgs.graphicsDriver);
        createFramebuffer();

        events.windowResized += (const Window window, vec2i size) {
            sMustUpdateFramebufferDimensions = true;
        };

        sApplication.load();
    }

    void unload()
    {
        sMainWindow.destroy();
        sMainFramebuffer.destroy();
        sApplication.unload();

        AudioSubsystem.unload();
        GraphicsSubsystem.unload();
        SdlSubsystem.unload();
        InputMap.unload();
        Files.unload();

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

    Events events;

    void run(string[] args, in ProjectProperties projectProperties) nothrow
    {
        try
        {
            load(args, projectProperties);
            start();
            unload();
        }
        catch (Throwable t)
        {
            Logger.core.error("%s", t);
        }
    }

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
        if (!sMainWindow.isMaximized && !sMainWindow.isMinimized)
            sMainWindow.size = vec2i(size);

        framebufferSize = vec2i(size);
    }

    void setTimeout(Duration duration, void delegate() callback,
        Flag!"repeating" repeating = No.repeating)
    in (callback, "Callback cannot be null.")
    {
        for (size_t i; i < sTimeouts.length; ++i)
        {
            if (!sTimeouts[i].callback)
            {
                sTimeouts[i] = TimeoutEntry(duration, upTime + duration, callback, repeating);
                return;
            }
        }

        throw new CoreException("Cannot set more than " ~ sTimeouts.length ~ " timeouts at once.");
    }

    void clearTimeout(void delegate() callback)
    {
        for (size_t i; i < sTimeouts.length; ++i)
        {
            if (sTimeouts[i].callback is callback)
            {
                sTimeouts[i].callback = null;
                return;
            }
        }
    }

    /// The current application.
    Application application() nothrow => sApplication;

    /// Sets the current application. It will only be set active after the current frame.
    void application(Application value)
    {
        setTimeout(Duration.zero, {
            if (sApplication)
                sApplication.unload();

            sApplication = value;
            sApplication.load();

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
        sWaitTime = dur!"msecs"(cast(int)(1000f / cast(float) fps));
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

    /// The main display of the engine.
    Window mainWindow() nothrow
    {
        return sMainWindow;
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
        float x = ((location.x - sFramebufferArea.x) / sFramebufferArea.width)
            * sMainFramebuffer.properties.size.x;
        float y = ((location.y - sFramebufferArea.y) / sFramebufferArea.height)
            * sMainFramebuffer.properties.size.y;

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
}
