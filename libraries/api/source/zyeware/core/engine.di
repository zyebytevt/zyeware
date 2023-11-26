// D import file generated from 'source/zyeware/core/engine.d'
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
import zyeware.common;
import zyeware.core.events;
import zyeware.core.application;
import zyeware.core.debugging;
import zyeware.rendering;
import zyeware.audio;
import zyeware.core.crash;
import zyeware.utils.format;
import zyeware.core.introapp;
import zyeware.pal;
alias defer = ZyeWare.callDeferred;
struct ProjectProperties
{
	string authorName = "Anonymous";
	string projectName = "ZyeWare Project";
	Application mainApplication;
	CrashHandler crashHandler;
	DisplayProperties mainDisplayProperties;
	uint audioBufferSize = 4096 * 4;
	uint audioBufferCount = 4;
	uint targetFrameRate = 60;
}
struct FrameTime
{
	Duration deltaTime;
	Duration unscaledDeltaTime;
}
struct Version
{
	int major;
	int minor;
	int patch;
	string prerelease;
	immutable pure string toString();
}
struct ZyeWare
{
	@disable this();
	@disable this(this);
	private static
	{
		struct ParsedArgs
		{
			string applicationFile;
			LogLevel coreLogLevel = LogLevel.verbose;
			LogLevel clientLogLevel = LogLevel.verbose;
			LogLevel palLogLevel = LogLevel.verbose;
			string graphicsDriver = "opengl";
			string audioDriver = "openal";
			string displayDriver = "sdl";
		}
		alias DeferFunc = void delegate();
		SharedLib sApplicationLibrary;
		Display sMainDisplay;
		Application sApplication;
		Duration sFrameTime;
		Duration sUpTime;
		RandomNumberGenerator sRandom;
		Framebuffer sMainFramebuffer;
		Rect2i sFramebufferArea;
		ScaleMode sScaleMode;
		bool sMustUpdateFramebufferDimensions;
		ProjectProperties sProjectProperties;
		DeferFunc[16] sDeferredFunctions;
		size_t sDeferredFunctionsCount;
		bool sRunning;
		float sTimeScale = 1.0F;
		debug (1)
		{
			bool sIsProcessingDeferred;
			bool sIsEmittingEvent;
		}
		ProjectProperties loadApplication(string library);
		void runMainLoop();
		void createFramebuffer();
		nothrow void recalculateFramebufferArea();
		void drawFramebuffer(in FrameTime nextFrameTime);
		ParsedArgs parseCmdArgs(string[] args);
		package(zyeware.core) static
		{
			CrashHandler crashHandler;
			void initialize(string[] args);
			void cleanup();
			void start();
			public static
			{
				immutable Version engineVersion = Version(0, 6, 0, "alpha");
				enum ScaleMode
				{
					center,
					keepAspect,
					fill,
					changeDisplaySize,
				}
				nothrow void quit();
				pragma (inline, true)nothrow void emit(E : Event, Args...)(Args args)
				{
					emit(scoped!E(args).assumeWontThrow);
				}
				nothrow void emit(in Event ev);
				nothrow void collect();
				void changeDisplaySize(Vector2i size);
				void callDeferred(DeferFunc func);
				nothrow Application application();
				void application(Application value);
				nothrow Duration upTime();
				void targetFrameRate(int fps);
				nothrow float timeScale();
				nothrow void timeScale(float value);
				nothrow RandomNumberGenerator random();
				nothrow Display mainDisplay();
				nothrow Vector2i framebufferSize();
				void framebufferSize(Vector2i newSize);
				nothrow Vector2f convertDisplayToFramebufferLocation(Vector2i location);
				nothrow ScaleMode scaleMode();
				nothrow void scaleMode(ScaleMode value);
				nothrow @nogc const(ProjectProperties) projectProperties();
				debug (1)
				{
					nothrow bool isProcessingDeferred();
					nothrow bool isEmittingEvent();
				}
			}
		}
	}
}
