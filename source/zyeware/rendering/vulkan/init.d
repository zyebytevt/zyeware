module zyeware.rendering.vulkan.init;

version (ZW_Vulkan):
package (zyeware.rendering.vulkan):

import std.exception : enforce;
import std.string : fromStringz;

import bindbc.sdl;
import erupted;

import zyeware.common;

void apiInitCreateInstance(VkInstance* instance)
{
    VkApplicationInfo appInfo = {
        sType: VK_STRUCTURE_TYPE_APPLICATION_INFO,
        pApplicationName: "Vulkan Rendering",
        applicationVersion: VK_MAKE_API_VERSION(0, 1, 0, 0),
        pEngineName: "ZyeWare",
        engineVersion: VK_MAKE_API_VERSION(0, 1, 0, 0),
        apiVersion: VK_API_VERSION_1_0
    };

    const(char)*[] extensions;
    const(char)*[] validationLayers;

    {
        uint sdlExtensionCount = 0;
        const(char)*[] sdlExtensions;

        // SDL_Vulkan_GetInstanceExtension has to be called twice; first to get the amount of extensions,
        // and then to actually get those extensions into e.g. an array.

        enforce!GraphicsException(SDL_Vulkan_GetInstanceExtensions(cast(SDL_Window*) ZyeWare.mainWindow.nativeWindow,
            &sdlExtensionCount, null), "Failed to get amount of necessary SDL Vulkan extensions.");

        sdlExtensions.length = sdlExtensionCount;

        enforce!GraphicsException(SDL_Vulkan_GetInstanceExtensions(cast(SDL_Window*) ZyeWare.mainWindow.nativeWindow,
            &sdlExtensionCount, sdlExtensions.ptr), "Failed to get list of necessary SDL Vulkan extensions.");

        for (size_t i; i < sdlExtensionCount; ++i)
            extensions ~= sdlExtensions[i];

        // I *think* the void* are C malloc'd and therefore manually managed...
        // GC.addRange(sdlExtensions.ptr, sdlExtensionCount); // what am I even doing
    }

    if (ZyeWare.projectProperties.graphicsBackendProperties.debugMode)
        extensions ~= VK_EXT_DEBUG_UTILS_EXTENSION_NAME;
    
    validationLayers ~= "VK_LAYER_KHRONOS_validation";

    VkInstanceCreateInfo createInfo = {
        sType: VK_STRUCTURE_TYPE_INSTANCE_CREATE_INFO,
        pApplicationInfo: &appInfo,

        enabledExtensionCount: cast(uint) extensions.length,
        ppEnabledExtensionNames: extensions.ptr,

        enabledLayerCount: cast(uint) validationLayers.length,
        ppEnabledLayerNames: validationLayers.ptr,
    };

    VkResult result = vkCreateInstance(&createInfo, null, instance);
    enforce!GraphicsException(result == VK_SUCCESS, "Failed to create Vulkan instance!");

    loadInstanceLevelFunctions(*instance);
}

void apiInitSetupDebugMessenger(VkInstance instance, VkDebugUtilsMessengerEXT* messenger)
{
    if (!ZyeWare.projectProperties.graphicsBackendProperties.debugMode)
        return;

    VkDebugUtilsMessengerCreateInfoEXT debugCreateInfo = {
        sType: VK_STRUCTURE_TYPE_DEBUG_UTILS_MESSENGER_CREATE_INFO_EXT,
        messageSeverity: VK_DEBUG_UTILS_MESSAGE_SEVERITY_VERBOSE_BIT_EXT | VK_DEBUG_UTILS_MESSAGE_SEVERITY_WARNING_BIT_EXT | VK_DEBUG_UTILS_MESSAGE_SEVERITY_ERROR_BIT_EXT,
        messageType: VK_DEBUG_UTILS_MESSAGE_TYPE_GENERAL_BIT_EXT | VK_DEBUG_UTILS_MESSAGE_TYPE_VALIDATION_BIT_EXT | VK_DEBUG_UTILS_MESSAGE_TYPE_PERFORMANCE_BIT_EXT,
        pfnUserCallback: cast(PFN_vkDebugUtilsMessengerCallbackEXT) &vkDebugCallback
    };

    enforce!GraphicsException(vkCreateDebugUtilsMessengerEXT(instance, &debugCreateInfo, null, messenger) == VK_SUCCESS,
        "Failed to create the debug utils messenger.");
}

void apiInitPickPhysicalDevice(VkInstance instance, VkPhysicalDevice* physicalDevice)
{

}

private:

extern(C) uint vkDebugCallback(VkDebugUtilsMessageSeverityFlagBitsEXT messageSeverity,
    VkDebugUtilsMessageTypeFlagsEXT messageType, const VkDebugUtilsMessengerCallbackDataEXT* callbackData,
    void* userData) nothrow
{
    LogLevel level;
    string typeName;

    switch (messageSeverity)
    {
    case VK_DEBUG_UTILS_MESSAGE_SEVERITY_VERBOSE_BIT_EXT: level = LogLevel.verbose; break;
    case VK_DEBUG_UTILS_MESSAGE_SEVERITY_INFO_BIT_EXT: level = LogLevel.info; break;
    case VK_DEBUG_UTILS_MESSAGE_SEVERITY_WARNING_BIT_EXT: level = LogLevel.warning; break;
    case VK_DEBUG_UTILS_MESSAGE_SEVERITY_ERROR_BIT_EXT: level = LogLevel.error; break;
    default:
    }

    switch (messageType)
    {
    case VK_DEBUG_UTILS_MESSAGE_TYPE_GENERAL_BIT_EXT: typeName = "General"; break;
    case VK_DEBUG_UTILS_MESSAGE_TYPE_VALIDATION_BIT_EXT: typeName = "Validation"; break;
    case VK_DEBUG_UTILS_MESSAGE_TYPE_PERFORMANCE_BIT_EXT: typeName = "Performance"; break;
    default:
    }

    Logger.core.log(level, "Vulkan %s: %s", messageType, callbackData.pMessage.fromStringz);

    return 0;
}