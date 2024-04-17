module zyeware.display.api;

import std.string : fromStringz;
import std.exception : enforce;

import bindbc.sdl;
import loader = bindbc.loader.sharedlib;

import zyeware;

struct DisplayApi
{
    @disable this();
    @disable this(this);

private static:
    SDL_Cursor*[const Cursor] sCursors;

    extern (C) static void logFunctionCallback(void* userdata, int category,
        SDL_LogPriority priority, stringz message) nothrow
    {
        LogLevel logLevel;
        immutable string msg = message.fromStringz.idup;

        switch (priority)
        {
        case SDL_LOG_PRIORITY_VERBOSE:
            logLevel = LogLevel.verbose;
            break;
        case SDL_LOG_PRIORITY_DEBUG:
            logLevel = LogLevel.debug_;
            break;
        case SDL_LOG_PRIORITY_INFO:
            logLevel = LogLevel.info;
            break;
        case SDL_LOG_PRIORITY_WARN:
            logLevel = LogLevel.warning;
            break;
        case SDL_LOG_PRIORITY_ERROR:
            logLevel = LogLevel.error;
            break;
        case SDL_LOG_PRIORITY_CRITICAL:
            logLevel = LogLevel.fatal;
            break;
        default:
        }

        Logger.core.log(logLevel, msg);
    }

package(zyeware) static:
    SDL_Surface* createSurfaceFromImage(in Image image) nothrow
    {
        uint rmask, gmask, bmask, amask;
        version (BigEndian)
        {
            immutable int shift = (image.channels == 4) ? 8 : 0;
            rmask = 0xff000000 >> shift;
            gmask = 0x00ff0000 >> shift;
            bmask = 0x0000ff00 >> shift;
            amask = 0x000000ff >> shift;
        }
        else
        {
            rmask = 0x000000ff;
            gmask = 0x0000ff00;
            bmask = 0x00ff0000;
            amask = (image.channels == 4) ? 0xff000000 : 0;
        }

        immutable int depth = image.channels * 8;
        immutable int pitch = image.channels * cast(int) image.size.x;

        return SDL_CreateRGBSurfaceFrom(cast(void*)&image.pixels[0],
            cast(int) image.size.x, cast(int) image.size.y, depth, pitch, rmask, gmask, bmask, amask);
    }

    SDL_Cursor* convertCursor(in Cursor cursor) nothrow
    {
        SDL_Cursor** sdlCursor = cursor in sCursors;
        if (!sdlCursor)
        {
            SDL_Surface* surface = createSurfaceFromImage(cursor.image);
            scope (exit) SDL_FreeSurface(surface);
            SDL_Cursor* newCursor = SDL_CreateColorCursor(surface, cursor.hotspot.x, cursor.hotspot.y);

            sCursors[cursor] = newCursor;
            sdlCursor = cursor in sCursors;
        }

        return *sdlCursor;
    }

public static:
    void initialize()
    {
        if (isSDLLoaded())
        return;

        immutable sdlResult = loadSDL();
        if (sdlResult != sdlSupport)
        {
            foreach (info; loader.errors)
                Logger.core.warning("SDL loader: %s", info.message.fromStringz);

            if (sdlResult == SDLSupport.noLibrary)
                throw new GraphicsException("Could not find SDL shared library.");
            else if (sdlResult == SDLSupport.badLibrary)
                throw new GraphicsException("Provided SDL shared library is corrupted.");
            else
                Logger.core.warning("Got older SDL version than expected. This might lead to errors.");
        }

        enforce!GraphicsException(SDL_Init(SDL_INIT_EVERYTHING) == 0,
            format!"Failed to initialize SDL: %s!"(SDL_GetError().fromStringz));

        SDL_LogSetOutputFunction(&logFunctionCallback, null);
    }

    void cleanup()
    {
        SDL_Quit();
    }
}