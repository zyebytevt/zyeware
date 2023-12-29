// This file was generated by ZyeWare APIgen. Do not edit!
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
import zyeware.core.properties;
import zyeware.core.dynlib;
import zyeware.pal;

/// How the main framebuffer should be scaled on resizing.
enum ScaleMode 
 {
center, Keep the original size at the center of the display.
keepAspect, Scale with display, but keep the aspect.
fill, Fill the display completely.
changeDisplaySize Resize the framebuffer itself.
}

/// Holds information about passed time since the last frame.
struct FrameTime {

Duration deltaTime;

Duration unscaledDeltaTime;
}

/// Holds information about a SemVer version.
struct Version {

int major;

int minor;

int patch;

string prerelease;

string toString() immutable pure;
}

/// Holds the core engine. Responsible for the main loop and generic engine settings.
struct ZyeWare {

@disable this();

@disable this(this);

private static:

struct ParsedArgs {

string[] packages;

LogLevel coreLogLevel;

LogLevel clientLogLevel;

string graphicsDriver;

string audioDriver;

string displayDriver;
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

float sTimeScale;debug

bool sIsProcessingDeferred;

Application createClientApplication();

void runMainLoop();

void createFramebuffer();

void recalculateFramebufferArea() nothrow;

void drawFramebuffer();

ParsedArgs parseCmdArgs(string[] args);

package(zyeware.core) static:

CrashHandler crashHandler;

void initialize(string[] args);

void cleanup();

void start();

public static:

/// The current version of the engine.
immutable Version engineVersion;

/// Stops the main loop and quits the engine.
void quit() nothrow;

/// Starts a garbage collection cycle, and clears the cache of dead references.
void collect() nothrow;

/// Changes the display size, respecting various display states with it (e.g. full screen, minimised etc.)
/// Params:
/// size = The new size of the display.
void changeDisplaySize(vec2i size);

/// Registers a callback to be called at the very end of a frame.
/// 
/// Params:
/// func = The deferred callback.
void callDeferred(DeferFunc func);

/// The current application.
Application application() nothrow;

/// Sets the current application. It will only be set active after the current frame.
void application(Application value);

/// The duration the engine is already running.
Duration upTime() nothrow;

/// The target framerate to hit. This is not a guarantee.
void targetFrameRate(int fps);

/// The current time scale. This controls the speed of the game, assuming
/// all `tick` methods use the `deltaTime` member of the given `FrameTime`.
/// 
/// See_Also: FrameTime
float timeScale() nothrow;

/// ditto
void timeScale(float value) nothrow;

FrameTime frameTime() nothrow;

RandomNumberGenerator random() nothrow;

/// The main display of the engine.
Display mainDisplay() nothrow;

/// The size of the main framebuffer.
vec2i framebufferSize() nothrow;

/// ditto
void framebufferSize(vec2i newSize);

/// Converts the given display-relative position to the main framebuffer location.
/// Use this method whenever you have to e.g. convert mouse pointer coordinates.
/// 
/// Params:
/// location = The display relative position.
/// Returns: The converted framebuffer position.
vec2 convertDisplayToFramebufferLocation(vec2i location) nothrow;

/// Determines how the displayed framebuffer will be scaled according to the display size and shape.
ScaleMode scaleMode() nothrow;

/// ditto
void scaleMode(ScaleMode value) nothrow;

/// The `ProjectProperties` the engine was started with.
/// See_Also: ProjectProperties
const(ProjectProperties) projectProperties() nothrow @nogc;debug

/// If the engine is currently processing deferred calls.
/// **This method is only available in debug builds!**
bool isProcessingDeferred() nothrow;
}