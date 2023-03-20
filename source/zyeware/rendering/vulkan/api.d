module zyeware.rendering.vulkan.api;

version (ZW_Vulkan):
package (zyeware.rendering.vulkan):

import std.exception : enforce;
import std.string : format, fromStringz;
import std.typecons : Nullable;
import core.memory : GC;

import bindbc.sdl;
import erupted;
import erupted.types;
import erupted.vulkan_lib_loader;

import zyeware.common;
import zyeware.core.engine;

import zyeware.rendering.vulkan.init;

// TODO: Can initialize and loadLibraries be combined?

struct QueueFamilyIndices
{
    Nullable!uint graphicsFamily;
    Nullable!uint presentFamily;

    bool isComplete()
    {
        return !graphicsFamily.isNull() && !presentFamily.isNull();
    }

    auto uniqueIndices()
    {
        import std.algorithm : uniq;

        assert(isComplete, "Cannot get unique indices from incomplete QueueFamilyIndices.");

        return [graphicsFamily.value, presentFamily.value].uniq;
    }
}

struct Queues
{
    VkQueue graphicsQueue;
    VkQueue presentQueue;
}

VkInstance pVkInstance;
VkDebugUtilsMessengerEXT pDebugMessenger;
VkPhysicalDevice pPhysicalDevice;
VkDevice pDevice;

Queues pQueues;

VkSurfaceKHR pSurface;

void apiInitialize()
{
    apiInitCreateInstance(&pVkInstance);
    apiInitSetupDebugMessenger(pVkInstance, &pDebugMessenger);
    apiInitPickPhysicalDevice(pVkInstance, &pPhysicalDevice);
    apiCreateSurface(pVkInstance, &pSurface);
    apiCreateLogicalDevice(pPhysicalDevice, &pDevice, pQueues, pSurface);
}

void apiLoadLibraries()
{
    // Load and initialize SDL
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

    if (pDebugMessenger)
        vkDestroyDebugUtilsMessengerEXT(pVkInstance, pDebugMessenger, null);
    
    vkDestroyDevice(pDevice, null);
    vkDestroySurfaceKHR(pVkInstance, pSurface, null);
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