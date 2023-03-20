module zyeware.rendering.vulkan.init;

version (ZW_Vulkan):
package (zyeware.rendering.vulkan):

import std.exception : enforce;
import std.string : fromStringz;

import bindbc.sdl;
import erupted;

import zyeware.common;
import zyeware.rendering.vulkan.api;

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
    uint deviceCount;
    vkEnumeratePhysicalDevices(instance, &deviceCount, null);

    enforce!GraphicsException(deviceCount > 0, "Failed to find any Vulkan devices!");

    auto devices = new VkPhysicalDevice[deviceCount];
    vkEnumeratePhysicalDevices(instance, &deviceCount, &devices[0]);

    int highestScore;
    VkPhysicalDevice highestDevice;

    foreach (ref VkPhysicalDevice device; devices)
    {
        int score = apiGetDeviceSuitabilityScore(device);

        if (score > highestScore)
        {
            highestScore = score;
            highestDevice = device;
        }
    }

    enforce!GraphicsException(highestDevice, "Failed to find a suitable Vulkan device!");

    *physicalDevice = highestDevice;
}

void apiCreateLogicalDevice(VkPhysicalDevice physicalDevice, VkLogicalDevice* device, ref Queues queues, VkSurfaceKHR surface)
{
    QueueFamilyIndices indices = apiFindQueueFamilies(physicalDevice, surface);

    float queuePriority = 1f;
    VkDeviceQueueCreateInfo[] queueFamilyCreateInfos;

    foreach (uint queueFamily; indices.uniqueIndices)
    {
        VkDeviceQueueCreateInfo info = {
            sType: VK_STRUCTURE_TYPE_DEVICE_QUEUE_CREATE_INFO,
            queueFamilyIndex: queueFamily,
            queueCount: 1,
            pQueuePriorities: &queuePriority
        };

        queueFamilyCreateInfos ~= info;
    }

    // Leave this empty for now according to the tutorial...
    VkPhysicalDeviceFeatures deviceFeatures;

    VkDeviceCreateInfo createInfo = {
        sType: VK_STRUCTURE_TYPE_DEVICE_CREATE_INFO,
        pQueueCreateInfos: &queueFamilyCreateInfos[0],
        queueCreateInfoCount: cast(uint) queueFamilyCreateInfos.length,
        pEnabledFeatures = &deviceFeatures
    };

    // I'll leave validation layers and extensions out for now...
    enforce!GraphicsException(vkCreateDevice(physicalDevice, &createInfo, null, device) == VK_SUCCESS,
        "Failed to create a logical device!");

    vkGetDeviceQueue(device, indices.graphicsFamily.value, 0, &queues.graphicsQueue);
    vkGetDeviceQueue(device, indices.presentFamily.value, 0, &queues.presentQueue);
}

void apiCreateSurface(VkInstance instance, VkSurfaceKHR* surface)
{
    enforce(ZyeWare.mainWindow, "Cannot create Vulkan surface without SDL main window!");
    SDL_Vulkan_CreateSurface(cast(SDL_Window*) ZyeWare.mainWindow.nativeWindow, instance, surface);
}

void apiFindQueueFamilies(VkPhysicalDevice device, ref QueueFamilyIndices indices, VkSurfaceKHR surface)
{
    uint queueFamilyCount;
    vkGetPhysicalDeviceQueueFamilyProperties(device, &queueFamilyCount, null);

    auto queueFamilies = new VkQueueFamilyProperties[queueFamilyCount];
    vkGetPhysicalDeviceQueueFamilyProperties(device, &queueFamilyCount, &queueFamilies[0]);

    int i;
    foreach (const ref VkQueueFamilyProperties queueFamily; queueFamilies)
    {
        if (queueFamily.queueFlags & VK_QUEUE_GRAPHICS_BIT)
            indices.graphicsFamily = i;

        bool presentSupport;
        vkGetPhysicalDeviceSurfaceSupportKHR(device, i, surface, &presentSupport);

        if (presentSupport)
            indices.presentFamily = i;

        if (indices.isComplete())
            break;

        ++i;
    }
}

private:

int apiGetDeviceSuitabilityScore(VkPhysicalDevice device)
{
    int score;

    QueueFamilyIndices indices;
    apiFindQueueFamilies(device, indices);

    if (indices.graphicsFamily.isNull())
        return 0;

    VkPhysicalDeviceProperties props;
    VkPhysicalDeviceFeatures features;

    vkGetPhysicalDeviceProperties(device, &props);
    vkGetPhysicalDeviceFeatures(device, &features);

    if (props.deviceType == VK_PHYSICAL_DEVICE_TYPE_DISCRETE_GPU)
        score += 1000;

    score += props.limits.maxImageDimension2D;
    
    return score;
}

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