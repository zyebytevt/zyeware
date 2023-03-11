module zyeware.rendering.vulkan.api;

version (ZW_Vulkan):
package (zyeware.rendering.vulkan):

import std.exception : enforce;
import std.string : format, fromStringz;

import bindbc.sdl;
import erupted;
import erupted.vulkan_lib_loader;

import zyeware.common;
import zyeware.core.engine;

// TODO: Can initialize and loadLibraries be combined?

VkInstance pVkInstance;

void apiInitialize()
{
    VkApplicationInfo appInfo = {
        sType: VK_STRUCTURE_TYPE_APPLICATION_INFO,
        pApplicationName: "Vulkan Rendering",
        applicationVersion: VK_MAKE_API_VERSION(0, 1, 0, 0),
        pEngineName: "ZyeWare",
        engineVersion: VK_MAKE_API_VERSION(0, 1, 0, 0),
        apiVersion: VK_API_VERSION_1_0
    };

    uint sdlExtensionCount = 0;
    const(char)** sdlExtensions;

    enforce!GraphicsException(SDL_Vulkan_GetInstanceExtensions(cast(SDL_Window*) ZyeWare.mainWindow.nativeWindow,
        &sdlExtensionCount, sdlExtensions), "Failed to get list of necessary SDL Vulkan extensions.");

    VkInstanceCreateInfo createInfo = {
        sType: VK_STRUCTURE_TYPE_INSTANCE_CREATE_INFO,
        pApplicationInfo: &appInfo,

        enabledExtensionCount: sdlExtensionCount,
        ppEnabledExtensionNames: sdlExtensions,
        enabledLayerCount: 0
    };

    VkResult result = vkCreateInstance(&createInfo, null, &pVkInstance);
    enforce!GraphicsException(result == VK_SUCCESS, "Failed to create Vulkan instance!");

    loadInstanceLevelFunctions(pVkInstance);
}

void apiLoadLibraries()
{
    // Initialize SDL
    enforce!GraphicsException(loadSDL() == sdlSupport, "Failed to load SDL!");
    enforce!GraphicsException(SDL_Init(SDL_INIT_EVERYTHING) == 0,
        format!"Failed to initialize SDL: %s!"(SDL_GetError().fromStringz));

    SDL_LogSetOutputFunction(&sdlLogFunctionCallback, null);

    Logger.core.log(LogLevel.debug_, "SDL initialized.");

    // Initialize Vulkan
    enforce!GraphicsException(loadGlobalLevelFunctions(), "Could not load Vulkan global level functions.");
}

void apiCleanup()
{
    SDL_Quit();

    vkDestroyInstance(pVkInstance, null);
}

extern(C) void sdlLogFunctionCallback(void* userdata, int category, SDL_LogPriority priority, const char* message) nothrow
{
    LogLevel level;
    switch (priority)
    {
    case SDL_LOG_PRIORITY_VERBOSE: level = LogLevel.verbose; break;
    case SDL_LOG_PRIORITY_DEBUG: level = LogLevel.debug_; break;
    case SDL_LOG_PRIORITY_INFO: level = LogLevel.info; break;
    case SDL_LOG_PRIORITY_WARN: level = LogLevel.warning; break;
    case SDL_LOG_PRIORITY_ERROR: level = LogLevel.error; break;
    case SDL_LOG_PRIORITY_CRITICAL: level = LogLevel.fatal; break;
    default:
    }

    Logger.core.log(level, message.fromStringz);
}